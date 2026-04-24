import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions";

export const notifySupervisorOnNewReport = onDocumentCreated(
  "hazard_reports/{reportId}",
  async (event) => {
    const report = event.data?.data();
    if (!report) return;

    const supervisorId: string = report.supervisorId ?? "";
    if (!supervisorId) {
      logger.info(`[notifySupervisor] No supervisorId on report ${event.params.reportId}`);
      return;
    }

    const [supervisorDoc, workerDoc] = await Promise.all([
      admin.firestore().collection("users").doc(supervisorId).get(),
      admin.firestore().collection("users").doc(report.uid ?? "").get(),
    ]);

    const fcmToken: string | undefined = supervisorDoc.data()?.fcmToken;
    if (!fcmToken) {
      logger.info(`[notifySupervisor] Supervisor ${supervisorId} has no FCM token`);
      return;
    }

    const category: string = report.category ?? "unknown";
    const severity: string = report.severity ?? "low";
    const mineSection: string = report.mineSection ?? "";
    const workerName: string = workerDoc.data()?.fullName ?? "A worker";
    const mineId: string = report.mineId ?? "";

    const title = `New Hazard Report — ${severity} severity`;
    const body = `${category} reported${mineSection ? ` in ${mineSection}` : ""} by ${workerName}`;
    const isCritical = severity === "critical";

    await admin.messaging().send({
      token: fcmToken,
      notification: {title, body},
      data: {
        reportId: event.params.reportId,
        mineId,
        severity,
        type: "hazard_report_new",
      },
      android: {
        priority: isCritical ? "high" : "normal",
        notification: {
          channelId: isCritical ? "critical_safety" : "hazard_reports",
          sound: isCritical ? "default" : undefined,
        },
      },
    });

    logger.info(`[notifySupervisor] Sent FCM to supervisor ${supervisorId} (critical=${isCritical})`);
  }
);
