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
exports.updateComplianceRate = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
/**
 * Triggered when a checklist document is updated.
 * When status changes to "submitted", recalculates the rolling 30-day
 * compliance rate for the worker and writes it to users/{uid}.complianceRate.
 */
exports.updateComplianceRate = (0, firestore_1.onDocumentUpdated)("checklists/{checklistId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    // Only fire when status transitions to "submitted"
    if (before.status === after.status || after.status !== "submitted") {
        return;
    }
    const uid = after.uid;
    const db = admin.firestore();
    // Fetch last 30 submitted checklists for this user
    const snap = await db
        .collection("checklists")
        .where("uid", "==", uid)
        .where("status", "==", "submitted")
        .orderBy("submittedAt", "desc")
        .limit(30)
        .get();
    if (snap.empty)
        return;
    const scores = snap.docs
        .map((d) => { var _a; return (_a = d.data().complianceScore) !== null && _a !== void 0 ? _a : 0; })
        .filter((s) => typeof s === "number" && !isNaN(s));
    if (scores.length === 0)
        return;
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const rounded = Math.round(avg * 10000) / 10000; // 4 decimal places
    await db.collection("users").doc(uid).update({
        complianceRate: rounded,
    });
    console.log(`[updateComplianceRate] uid=${uid} newRate=${rounded} from ${scores.length} submissions`);
});
//# sourceMappingURL=updateComplianceRate.js.map