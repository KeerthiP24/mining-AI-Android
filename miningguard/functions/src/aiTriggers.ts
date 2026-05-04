import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

/**
 * Phase 6 — AI-backend triggers.
 *
 * These functions are thin event-bridge handlers. They react to Firestore
 * writes and POST to the FastAPI AI backend so the model rerun happens
 * close to real time without the mobile client having to ask.
 *
 * The backend URL is read from `AI_BACKEND_URL`. If unset (e.g. the AI
 * backend isn't deployed yet), the functions log and short-circuit so
 * the Firestore-side work still completes.
 *
 * The optional `AI_INTERNAL_TOKEN` is forwarded as an `X-Internal-Token`
 * header — pair it with the backend's matching secret to skip Firebase
 * token verification for service-to-service calls.
 */

const AI_BACKEND_URL = process.env.AI_BACKEND_URL;
const AI_INTERNAL_TOKEN = process.env.AI_INTERNAL_TOKEN;

async function callAiBackend(
  path: string,
  body: object,
): Promise<void> {
  if (!AI_BACKEND_URL) {
    console.log(`[aiTriggers] AI_BACKEND_URL unset — skipping ${path}`);
    return;
  }
  const url = `${AI_BACKEND_URL.replace(/\/$/, "")}${path}`;
  try {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (AI_INTERNAL_TOKEN) headers["X-Internal-Token"] = AI_INTERNAL_TOKEN;

    const response = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      const text = await response.text().catch(() => "");
      console.warn(
        `[aiTriggers] ${path} returned ${response.status}: ${text.slice(0, 200)}`,
      );
    }
  } catch (err) {
    console.error(`[aiTriggers] POST ${path} failed:`, err);
  }
}

// ── Checklist submitted/missed → recompute risk ──────────────────────────────

export const onChecklistStatusChange = onDocumentUpdated(
  "checklists/{checklistId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (!["submitted", "missed"].includes(after.status)) return;

    const uid = after.uid as string | undefined;
    if (!uid) return;

    // Bump consecutive-missed-days counter so the next risk read sees the
    // updated value. Keeps consistency with Phase 4's existing checklist
    // submission flow which resets the counter to 0 on submit.
    const userRef = admin.firestore().collection("users").doc(uid);
    if (after.status === "missed") {
      await userRef.set(
        {consecutiveMissedDays: admin.firestore.FieldValue.increment(1)},
        {merge: true},
      );
    }

    await callAiBackend("/api/v1/risk/predict", {uid});
  },
);

// ── Hazard report created → recompute risk ───────────────────────────────────

export const onHazardReportCreatedAi = onDocumentCreated(
  "hazard_reports/{reportId}",
  async (event) => {
    const data = event.data?.data();
    const uid = data?.uid as string | undefined;
    if (!uid) return;
    await callAiBackend("/api/v1/risk/predict", {uid});
  },
);

// ── Daily behavior analysis sweep ────────────────────────────────────────────

export const dailyBehaviorAnalysis = onSchedule(
  {
    // 23:30 UTC = 05:00 IST
    schedule: "30 23 * * *",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    const snapshot = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "worker")
      .get();

    console.log(
      `[dailyBehaviorAnalysis] Running analysis for ${snapshot.size} workers`,
    );

    const settled = await Promise.allSettled(
      snapshot.docs.map((doc) =>
        callAiBackend("/api/v1/behavior/analyze", {uid: doc.id}),
      ),
    );
    const failed = settled.filter((r) => r.status === "rejected").length;
    if (failed > 0) {
      console.warn(`[dailyBehaviorAnalysis] ${failed}/${snapshot.size} failed`);
    }
  },
);
