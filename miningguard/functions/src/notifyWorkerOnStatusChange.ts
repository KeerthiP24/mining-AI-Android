import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions";

const STATUS_LABELS: Record<string, string> = {
  pending: "Pending",
  acknowledged: "Acknowledged",
  in_progress: "In Progress",
  resolved: "Resolved",
};

export const notifyWorkerOnStatusChange = onDocumentUpdated(
  "hazard_reports/{reportId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus: string = before.status ?? "";
    const newStatus: string = after.status ?? "";

    if (prevStatus === newStatus) return;

    const uid: string = after.uid ?? "";
    if (!uid) return;

    const workerDoc = await admin.firestore()
      .collection("users")
      .doc(uid)
      .get();

    const fcmToken: string | undefined = workerDoc.data()?.fcmToken;
    if (!fcmToken) {
      logger.info(`[notifyWorker] Worker ${uid} has no FCM token`);
      return;
    }

    const statusLabel = STATUS_LABELS[newStatus] ?? newStatus;
    const category: string = after.category ?? "hazard";

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Hazard Report Update",
        body: `Your ${category} report is now: ${statusLabel}`,
      },
      data: {
        reportId: event.params.reportId,
        status: newStatus,
        type: "hazard_report_status_change",
      },
    });

    logger.info(`[notifyWorker] Sent status change FCM to worker ${uid}: ${prevStatus} → ${newStatus}`);
  }
);
