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
exports.onVideoWatched = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
/**
 * Triggered on writes to `video_watches/{watchId}`.
 *
 * When `isCompleted` flips to `true`, updates the user's rolling 7-day
 * watch count, total watch count, and lastVideoWatchedAt timestamp.
 * The Phase 6 risk-prediction engine consumes `videosWatched7Days` directly
 * as a positive behavioral signal.
 */
exports.onVideoWatched = (0, firestore_1.onDocumentWritten)("video_watches/{watchId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    // Only react when isCompleted transitions to true.
    if (!after)
        return;
    const wasCompleted = (before === null || before === void 0 ? void 0 : before.isCompleted) === true;
    const isCompleted = after.isCompleted === true;
    if (!isCompleted || wasCompleted)
        return;
    const uid = after.userId;
    if (!uid)
        return;
    const db = admin.firestore();
    // Recompute the 7-day count by querying — keeps the field accurate even
    // if older documents are backfilled or rebuilt.
    const sevenDaysAgo = firestore_2.Timestamp.fromMillis(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentSnap = await db
        .collection("video_watches")
        .where("userId", "==", uid)
        .where("isCompleted", "==", true)
        .where("watchedAt", ">=", sevenDaysAgo)
        .get();
    await db.collection("users").doc(uid).set({
        videosWatched7Days: recentSnap.size,
        totalVideosWatched: admin.firestore.FieldValue.increment(1),
        lastVideoWatchedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`[onVideoWatched] uid=${uid} videosWatched7Days=${recentSnap.size}`);
});
//# sourceMappingURL=onVideoWatched.js.map