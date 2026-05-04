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
exports.dailyBehaviorAnalysis = exports.onHazardReportCreatedAi = exports.onChecklistStatusChange = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
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
async function callAiBackend(path, body) {
    if (!AI_BACKEND_URL) {
        console.log(`[aiTriggers] AI_BACKEND_URL unset — skipping ${path}`);
        return;
    }
    const url = `${AI_BACKEND_URL.replace(/\/$/, "")}${path}`;
    try {
        const headers = {
            "Content-Type": "application/json",
        };
        if (AI_INTERNAL_TOKEN)
            headers["X-Internal-Token"] = AI_INTERNAL_TOKEN;
        const response = await fetch(url, {
            method: "POST",
            headers,
            body: JSON.stringify(body),
        });
        if (!response.ok) {
            const text = await response.text().catch(() => "");
            console.warn(`[aiTriggers] ${path} returned ${response.status}: ${text.slice(0, 200)}`);
        }
    }
    catch (err) {
        console.error(`[aiTriggers] POST ${path} failed:`, err);
    }
}
// ── Checklist submitted/missed → recompute risk ──────────────────────────────
exports.onChecklistStatusChange = (0, firestore_1.onDocumentUpdated)("checklists/{checklistId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    if (before.status === after.status)
        return;
    if (!["submitted", "missed"].includes(after.status))
        return;
    const uid = after.uid;
    if (!uid)
        return;
    // Bump consecutive-missed-days counter so the next risk read sees the
    // updated value. Keeps consistency with Phase 4's existing checklist
    // submission flow which resets the counter to 0 on submit.
    const userRef = admin.firestore().collection("users").doc(uid);
    if (after.status === "missed") {
        await userRef.set({ consecutiveMissedDays: admin.firestore.FieldValue.increment(1) }, { merge: true });
    }
    await callAiBackend("/api/v1/risk/predict", { uid });
});
// ── Hazard report created → recompute risk ───────────────────────────────────
exports.onHazardReportCreatedAi = (0, firestore_1.onDocumentCreated)("hazard_reports/{reportId}", async (event) => {
    var _a;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    const uid = data === null || data === void 0 ? void 0 : data.uid;
    if (!uid)
        return;
    await callAiBackend("/api/v1/risk/predict", { uid });
});
// ── Daily behavior analysis sweep ────────────────────────────────────────────
exports.dailyBehaviorAnalysis = (0, scheduler_1.onSchedule)({
    // 23:30 UTC = 05:00 IST
    schedule: "30 23 * * *",
    timeZone: "UTC",
    region: "us-central1",
}, async () => {
    const snapshot = await admin
        .firestore()
        .collection("users")
        .where("role", "==", "worker")
        .get();
    console.log(`[dailyBehaviorAnalysis] Running analysis for ${snapshot.size} workers`);
    const settled = await Promise.allSettled(snapshot.docs.map((doc) => callAiBackend("/api/v1/behavior/analyze", { uid: doc.id })));
    const failed = settled.filter((r) => r.status === "rejected").length;
    if (failed > 0) {
        console.warn(`[dailyBehaviorAnalysis] ${failed}/${snapshot.size} failed`);
    }
});
//# sourceMappingURL=aiTriggers.js.map