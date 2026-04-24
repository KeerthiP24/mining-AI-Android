import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";

/**
 * Runs daily at 23:30 UTC (hardcoded for now; Phase 7 makes this configurable
 * per mine timezone).
 *
 * For every worker/supervisor who has not submitted today's checklist:
 * - Marks the checklist document as "missed" (creates it if it doesn't exist)
 * - Increments consecutiveMissedDays on the user document
 * - Creates an alert document for supervisors
 */
export const detectMissedChecklists = onSchedule("30 23 * * *", async () => {
  const db = admin.firestore();
  const today = _todayUtcString();

  // Fetch all workers and supervisors
  const usersSnap = await db
    .collection("users")
    .where("role", "in", ["worker", "supervisor"])
    .get();

  const batch = db.batch();
  let batchCount = 0;

  const flushBatch = async () => {
    if (batchCount > 0) {
      await batch.commit();
      batchCount = 0;
    }
  };

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    const uid = userDoc.id;
    const mineId = user.mineId as string;
    const checklistId = `${uid}_${mineId}_${today}`;
    const checklistRef = db.collection("checklists").doc(checklistId);

    const checklistSnap = await checklistRef.get();
    const existing = checklistSnap.exists ? checklistSnap.data() : null;

    // Skip if already submitted
    if (existing?.status === "submitted") continue;

    // Mark as missed
    if (checklistSnap.exists) {
      batch.update(checklistRef, {status: "missed"});
    } else {
      batch.set(checklistRef, {
        uid,
        mineId,
        shift: user.shift ?? "morning",
        date: today,
        templateVersion: 1,
        status: "missed",
        items: {},
        complianceScore: 0.0,
        mandatoryScore: 0.0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        submittedAt: null,
      });
    }

    // Increment consecutiveMissedDays on user
    batch.update(db.collection("users").doc(uid), {
      consecutiveMissedDays: admin.firestore.FieldValue.increment(1),
    });

    // Write alert for supervisor
    const consecutiveMissed = (user.consecutiveMissedDays as number ?? 0) + 1;
    const alertRef = db.collection("alerts").doc();
    batch.set(alertRef, {
      uid,
      supervisorUid: user.supervisorUid ?? null,
      type: "missed_checklist",
      severity: consecutiveMissed >= 3 ? "high" : "medium",
      message: "Worker missed safety checklist",
      date: today,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    batchCount += 3; // 3 writes per user

    // Firestore batch limit is 500 writes
    if (batchCount >= 450) {
      await flushBatch();
    }
  }

  await flushBatch();
  console.log(
    `[detectMissedChecklists] Processed ${usersSnap.size} users for date ${today}`
  );
});

function _todayUtcString(): string {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, "0");
  const d = String(now.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}
