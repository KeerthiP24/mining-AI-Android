"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifySupervisorOnNewReport = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firebase_functions_1 = require("firebase-functions");
exports.notifySupervisorOnNewReport = (0, firestore_1.onDocumentCreated)("hazard_reports/{reportId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    const report = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!report)
        return;
    const supervisorId = (_b = report.supervisorId) !== null && _b !== void 0 ? _b : "";
    if (!supervisorId) {
        firebase_functions_1.logger.info(`[notifySupervisor] No supervisorId on report ${event.params.reportId}`);
        return;
    }
    const [supervisorDoc, workerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(supervisorId).get(),
        admin.firestore().collection("users").doc((_c = report.uid) !== null && _c !== void 0 ? _c : "").get(),
    ]);
    const fcmToken = (_d = supervisorDoc.data()) === null || _d === void 0 ? void 0 : _d.fcmToken;
    if (!fcmToken) {
        firebase_functions_1.logger.info(`[notifySupervisor] Supervisor ${supervisorId} has no FCM token`);
        return;
    }
    const category = (_e = report.category) !== null && _e !== void 0 ? _e : "unknown";
    const severity = (_f = report.severity) !== null && _f !== void 0 ? _f : "low";
    const mineSection = (_g = report.mineSection) !== null && _g !== void 0 ? _g : "";
    const workerName = (_j = (_h = workerDoc.data()) === null || _h === void 0 ? void 0 : _h.fullName) !== null && _j !== void 0 ? _j : "A worker";
    const mineId = (_k = report.mineId) !== null && _k !== void 0 ? _k : "";
    const title = `New Hazard Report — ${severity} severity`;
    const body = `${category} reported${mineSection ? ` in ${mineSection}` : ""} by ${workerName}`;
    const isCritical = severity === "critical";
    await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
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
    firebase_functions_1.logger.info(`[notifySupervisor] Sent FCM to supervisor ${supervisorId} (critical=${isCritical})`);
});
//# sourceMappingURL=notifySupervisorOnNewReport.js.map