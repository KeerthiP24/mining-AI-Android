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
exports.detectMissedChecklists = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
/**
 * Runs daily at 23:30 UTC (hardcoded for now; Phase 7 makes this configurable
 * per mine timezone).
 *
 * For every worker/supervisor who has not submitted today's checklist:
 * - Marks the checklist document as "missed" (creates it if it doesn't exist)
 * - Increments consecutiveMissedDays on the user document
 * - Creates an alert document for supervisors
 */
exports.detectMissedChecklists = (0, scheduler_1.onSchedule)("30 23 * * *", async () => {
    var _a, _b, _c;
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
        const mineId = user.mineId;
        const checklistId = `${uid}_${mineId}_${today}`;
        const checklistRef = db.collection("checklists").doc(checklistId);
        const checklistSnap = await checklistRef.get();
        const existing = checklistSnap.exists ? checklistSnap.data() : null;
        // Skip if already submitted
        if ((existing === null || existing === void 0 ? void 0 : existing.status) === "submitted")
            continue;
        // Mark as missed
        if (checklistSnap.exists) {
            batch.update(checklistRef, { status: "missed" });
        }
        else {
            batch.set(checklistRef, {
                uid,
                mineId,
                shift: (_a = user.shift) !== null && _a !== void 0 ? _a : "morning",
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
        const consecutiveMissed = ((_b = user.consecutiveMissedDays) !== null && _b !== void 0 ? _b : 0) + 1;
        const alertRef = db.collection("alerts").doc();
        batch.set(alertRef, {
            uid,
            supervisorUid: (_c = user.supervisorUid) !== null && _c !== void 0 ? _c : null,
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
    console.log(`[detectMissedChecklists] Processed ${usersSnap.size} users for date ${today}`);
});
function _todayUtcString() {
    const now = new Date();
    const y = now.getUTCFullYear();
    const m = String(now.getUTCMonth() + 1).padStart(2, "0");
    const d = String(now.getUTCDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
}
//# sourceMappingURL=detectMissedChecklists.js.map