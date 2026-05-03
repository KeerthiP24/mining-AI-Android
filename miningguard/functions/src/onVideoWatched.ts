import * as admin from "firebase-admin";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {Timestamp} from "firebase-admin/firestore";

/**
 * Triggered on writes to `video_watches/{watchId}`.
 *
 * When `isCompleted` flips to `true`, updates the user's rolling 7-day
 * watch count, total watch count, and lastVideoWatchedAt timestamp.
 * The Phase 6 risk-prediction engine consumes `videosWatched7Days` directly
 * as a positive behavioral signal.
 */
export const onVideoWatched = onDocumentWritten(
  "video_watches/{watchId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    // Only react when isCompleted transitions to true.
    if (!after) return;
    const wasCompleted = before?.isCompleted === true;
    const isCompleted = after.isCompleted === true;
    if (!isCompleted || wasCompleted) return;

    const uid = after.userId as string | undefined;
    if (!uid) return;

    const db = admin.firestore();

    // Recompute the 7-day count by querying — keeps the field accurate even
    // if older documents are backfilled or rebuilt.
    const sevenDaysAgo = Timestamp.fromMillis(
      Date.now() - 7 * 24 * 60 * 60 * 1000
    );
    const recentSnap = await db
      .collection("video_watches")
      .where("userId", "==", uid)
      .where("isCompleted", "==", true)
      .where("watchedAt", ">=", sevenDaysAgo)
      .get();

    await db.collection("users").doc(uid).set(
      {
        videosWatched7Days: recentSnap.size,
        totalVideosWatched: admin.firestore.FieldValue.increment(1),
        lastVideoWatchedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    console.log(
      `[onVideoWatched] uid=${uid} videosWatched7Days=${recentSnap.size}`
    );
  }
);
