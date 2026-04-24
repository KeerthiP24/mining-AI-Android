import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

/**
 * Triggered when a checklist document is updated.
 * When status changes to "submitted", recalculates the rolling 30-day
 * compliance rate for the worker and writes it to users/{uid}.complianceRate.
 */
export const updateComplianceRate = onDocumentUpdated(
  "checklists/{checklistId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Only fire when status transitions to "submitted"
    if (before.status === after.status || after.status !== "submitted") {
      return;
    }

    const uid = after.uid as string;
    const db = admin.firestore();

    // Fetch last 30 submitted checklists for this user
    const snap = await db
      .collection("checklists")
      .where("uid", "==", uid)
      .where("status", "==", "submitted")
      .orderBy("submittedAt", "desc")
      .limit(30)
      .get();

    if (snap.empty) return;

    const scores = snap.docs
      .map((d) => (d.data().complianceScore as number) ?? 0)
      .filter((s) => typeof s === "number" && !isNaN(s));

    if (scores.length === 0) return;

    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const rounded = Math.round(avg * 10000) / 10000; // 4 decimal places

    await db.collection("users").doc(uid).update({
      complianceRate: rounded,
    });

    console.log(
      `[updateComplianceRate] uid=${uid} newRate=${rounded} from ${scores.length} submissions`
    );
  }
);
