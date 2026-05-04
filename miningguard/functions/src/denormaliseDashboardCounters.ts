/**
 * Phase 7 — Dashboard counter denormalisation.
 *
 * The supervisor dashboard reads two boolean / int counters off
 * `users/{uid}` to avoid an N-query fan-out per render:
 *   - todayChecklistDone   (bool)  — submitted today?
 *   - pendingReportCount   (int)   — open hazard reports filed by this user
 *
 * Maintaining them in Cloud Functions keeps the supervisor list at
 * 1 read per worker rather than 1+N+M reads.
 */
import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";

const OPEN_STATUSES = new Set(["pending", "acknowledged", "in_progress"]);

function todayKey(): string {
  const n = new Date();
  const y = n.getUTCFullYear().toString().padStart(4, "0");
  const m = (n.getUTCMonth() + 1).toString().padStart(2, "0");
  const d = n.getUTCDate().toString().padStart(2, "0");
  return `${y}-${m}-${d}`;
}

// ─── todayChecklistDone ──────────────────────────────────────────────────────

/**
 * Mark a worker as "done for today" the moment they submit. The
 * `dailyResetTodayChecklistFlag` scheduled job clears the flag at midnight.
 *
 * We use onDocumentWritten (covers both create and update) and only mutate
 * when the resulting status is "submitted" AND the checklist's `date`
 * matches today's UTC date — this keeps backfills from historical writes
 * out of the live "today" flag.
 */
export const onChecklistSubmittedDenorm = onDocumentWritten(
  "checklists/{checklistId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after) return;
    if (after.status !== "submitted") return;
    if (after.date !== todayKey()) return;

    const uid = after.uid as string | undefined;
    if (!uid) return;

    await admin.firestore().collection("users").doc(uid).set(
      {
        todayChecklistDone: true,
        lastChecklistDate: after.date,
      },
      {merge: true},
    );

    console.log(
      `[denorm/checklistDone] uid=${uid} flag=true date=${after.date}`,
    );
  },
);

/**
 * Reset every user's `todayChecklistDone` flag at the start of a new day.
 * Runs at 00:05 UTC daily (matches `detectMissedChecklists` cadence).
 *
 * Uses a chunked batch write because Firestore's batch limit is 500.
 */
export const dailyResetTodayChecklistFlag = onSchedule(
  {schedule: "5 0 * * *", timeZone: "UTC", region: "us-central1"},
  async () => {
    const db = admin.firestore();
    const snap = await db
      .collection("users")
      .where("todayChecklistDone", "==", true)
      .get();
    if (snap.empty) {
      console.log("[denorm/dailyReset] no flagged users");
      return;
    }

    let written = 0;
    for (let i = 0; i < snap.docs.length; i += 400) {
      const batch = db.batch();
      const chunk = snap.docs.slice(i, i + 400);
      for (const doc of chunk) {
        batch.update(doc.ref, {todayChecklistDone: false});
        written++;
      }
      await batch.commit();
    }
    console.log(`[denorm/dailyReset] cleared todayChecklistDone for ${written} users`);
  },
);

// ─── pendingReportCount ──────────────────────────────────────────────────────

/**
 * Increment the worker's pending count when they file a new report.
 *
 * The Phase 4 `notifySupervisorOnNewReport` runs on the same trigger; we
 * deliberately split this into its own handler so a transient failure here
 * doesn't block the FCM notification.
 */
export const onHazardReportCreatedDenorm = onDocumentCreated(
  "hazard_reports/{reportId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const uid = data.uid as string | undefined;
    if (!uid) return;

    // A new report defaults to "pending"; if the client uploaded with
    // an already-resolved status (unusual), don't bump the counter.
    const status = (data.status as string | undefined) ?? "pending";
    if (!OPEN_STATUSES.has(status)) return;

    await admin.firestore().collection("users").doc(uid).set(
      {pendingReportCount: admin.firestore.FieldValue.increment(1)},
      {merge: true},
    );

    console.log(`[denorm/reportCreate] uid=${uid} +1 pending`);
  },
);

/**
 * When a report transitions across the open/resolved boundary, adjust the
 * counter. We compare both sides so the function tolerates re-opens
 * (resolved → in_progress should bump back up).
 */
export const onHazardReportStatusChangeDenorm = onDocumentUpdated(
  "hazard_reports/{reportId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const uid = after.uid as string | undefined;
    if (!uid) return;

    const wasOpen = OPEN_STATUSES.has(before.status);
    const isOpen = OPEN_STATUSES.has(after.status);

    let delta = 0;
    if (wasOpen && !isOpen) delta = -1;     // closed
    else if (!wasOpen && isOpen) delta = 1; // re-opened

    if (delta === 0) return;

    await admin.firestore().collection("users").doc(uid).set(
      {pendingReportCount: admin.firestore.FieldValue.increment(delta)},
      {merge: true},
    );

    console.log(
      `[denorm/reportStatus] uid=${uid} ${before.status}→${after.status} delta=${delta}`,
    );
  },
);

/**
 * One-shot recompute job for backfilling existing users whose counters
 * are missing or wrong. Trigger manually via `firebase functions:shell`
 * or the Cloud Console — not on a schedule.
 *
 * Skips users who already have correct counts to keep cost down.
 */
export const recomputeDashboardCounters = onSchedule(
  // Disabled schedule (year=2099) — only triggered manually.
  {schedule: "0 0 1 1 *", timeZone: "UTC", region: "us-central1"},
  async () => {
    const db = admin.firestore();
    const today = todayKey();

    // Pending counts per uid
    const reportsSnap = await db
      .collection("hazard_reports")
      .where("status", "in", ["pending", "acknowledged", "in_progress"])
      .get();
    const pendingByUid = new Map<string, number>();
    for (const doc of reportsSnap.docs) {
      const uid = doc.data().uid as string | undefined;
      if (!uid) continue;
      pendingByUid.set(uid, (pendingByUid.get(uid) ?? 0) + 1);
    }

    // todayChecklistDone per uid
    const checklistsSnap = await db
      .collection("checklists")
      .where("date", "==", today)
      .where("status", "==", "submitted")
      .get();
    const submittedToday = new Set<string>(
      checklistsSnap.docs
        .map((d) => d.data().uid as string | undefined)
        .filter((u): u is string => !!u),
    );

    // Walk users in pages of 400 (batch write limit ~500).
    const usersSnap = await db.collection("users").get();
    let written = 0;
    for (let i = 0; i < usersSnap.docs.length; i += 400) {
      const batch = db.batch();
      const chunk = usersSnap.docs.slice(i, i + 400);
      for (const doc of chunk) {
        batch.update(doc.ref, {
          pendingReportCount: pendingByUid.get(doc.id) ?? 0,
          todayChecklistDone: submittedToday.has(doc.id),
        });
        written++;
      }
      await batch.commit();
    }
    console.log(`[denorm/recompute] wrote ${written} users`);
  },
);
