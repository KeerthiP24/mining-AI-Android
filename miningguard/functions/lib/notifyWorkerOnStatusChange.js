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
exports.notifyWorkerOnStatusChange = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firebase_functions_1 = require("firebase-functions");
const STATUS_LABELS = {
    pending: "Pending",
    acknowledged: "Acknowledged",
    in_progress: "In Progress",
    resolved: "Resolved",
};
exports.notifyWorkerOnStatusChange = (0, firestore_1.onDocumentUpdated)("hazard_reports/{reportId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    const prevStatus = (_c = before.status) !== null && _c !== void 0 ? _c : "";
    const newStatus = (_d = after.status) !== null && _d !== void 0 ? _d : "";
    if (prevStatus === newStatus)
        return;
    const uid = (_e = after.uid) !== null && _e !== void 0 ? _e : "";
    if (!uid)
        return;
    const workerDoc = await admin.firestore()
        .collection("users")
        .doc(uid)
        .get();
    const fcmToken = (_f = workerDoc.data()) === null || _f === void 0 ? void 0 : _f.fcmToken;
    if (!fcmToken) {
        firebase_functions_1.logger.info(`[notifyWorker] Worker ${uid} has no FCM token`);
        return;
    }
    const statusLabel = (_g = STATUS_LABELS[newStatus]) !== null && _g !== void 0 ? _g : newStatus;
    const category = (_h = after.category) !== null && _h !== void 0 ? _h : "hazard";
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
    firebase_functions_1.logger.info(`[notifyWorker] Sent status change FCM to worker ${uid}: ${prevStatus} → ${newStatus}`);
});
//# sourceMappingURL=notifyWorkerOnStatusChange.js.map