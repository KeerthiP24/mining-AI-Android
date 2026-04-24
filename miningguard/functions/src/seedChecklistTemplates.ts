import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";

const WORKER_ITEMS = [
  // PPE
  {itemId: "ppe_helmet", category: "ppe", labelKey: "checklist_ppe_helmet", mandatory: true, order: 1},
  {itemId: "ppe_boots", category: "ppe", labelKey: "checklist_ppe_boots", mandatory: true, order: 2},
  {itemId: "ppe_vest", category: "ppe", labelKey: "checklist_ppe_vest", mandatory: true, order: 3},
  {itemId: "ppe_gloves", category: "ppe", labelKey: "checklist_ppe_gloves", mandatory: true, order: 4},
  {itemId: "ppe_lamp_charged", category: "ppe", labelKey: "checklist_ppe_lamp_charged", mandatory: true, order: 5},
  {itemId: "ppe_scsr_present", category: "ppe", labelKey: "checklist_ppe_scsr_present", mandatory: true, order: 6},
  // Machinery
  {itemId: "mach_preshift_done", category: "machinery", labelKey: "checklist_mach_preshift_done", mandatory: true, order: 7},
  {itemId: "mach_guards_in_place", category: "machinery", labelKey: "checklist_mach_guards_in_place", mandatory: true, order: 8},
  {itemId: "mach_no_leaks", category: "machinery", labelKey: "checklist_mach_no_leaks", mandatory: true, order: 9},
  // Environment
  {itemId: "env_gas_detector_ok", category: "environment", labelKey: "checklist_env_gas_detector_ok", mandatory: true, order: 10},
  {itemId: "env_roof_inspected", category: "environment", labelKey: "checklist_env_roof_inspected", mandatory: true, order: 11},
  {itemId: "env_ventilation_ok", category: "environment", labelKey: "checklist_env_ventilation_ok", mandatory: true, order: 12},
  {itemId: "env_walkways_clear", category: "environment", labelKey: "checklist_env_walkways_clear", mandatory: false, order: 13},
  // Emergency
  {itemId: "emg_exit_known", category: "emergency", labelKey: "checklist_emg_exit_known", mandatory: true, order: 14},
  {itemId: "emg_comms_working", category: "emergency", labelKey: "checklist_emg_comms_working", mandatory: true, order: 15},
  {itemId: "emg_first_aid_located", category: "emergency", labelKey: "checklist_emg_first_aid_located", mandatory: false, order: 16},
];

const SUPERVISOR_EXTRA_ITEMS = [
  {itemId: "sup_attendance_confirmed", category: "supervisor", labelKey: "checklist_sup_attendance_confirmed", mandatory: true, order: 17},
  {itemId: "sup_toolbox_talk_done", category: "supervisor", labelKey: "checklist_sup_toolbox_talk_done", mandatory: true, order: 18},
  {itemId: "sup_dgms_permits_reviewed", category: "supervisor", labelKey: "checklist_sup_dgms_permits_reviewed", mandatory: true, order: 19},
  {itemId: "sup_high_risk_permits_checked", category: "supervisor", labelKey: "checklist_sup_high_risk_permits_checked", mandatory: true, order: 20},
  {itemId: "sup_muster_point_communicated", category: "supervisor", labelKey: "checklist_sup_muster_point_communicated", mandatory: false, order: 21},
];

/**
 * One-time callable HTTPS function to seed checklist templates for a mine.
 * Call with: { mineId: "mine001" }
 * Requires the caller to be an admin (role == "admin").
 */
export const seedChecklistTemplates = onCall(async (request) => {
  const db = admin.firestore();

  // Verify caller is admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerDoc = await db
    .collection("users")
    .doc(request.auth.uid)
    .get();

  if (callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin role required.");
  }

  const mineId = (request.data as {mineId: string}).mineId;
  if (!mineId) {
    throw new HttpsError("invalid-argument", "mineId is required.");
  }

  const batch = db.batch();

  // Worker template
  batch.set(
    db.collection("checklist_templates").doc(`${mineId}_worker`),
    {
      templateId: `${mineId}_worker`,
      mineId,
      role: "worker",
      version: 1,
      items: WORKER_ITEMS,
    }
  );

  // Supervisor template (worker items + supervisor-specific items)
  batch.set(
    db.collection("checklist_templates").doc(`${mineId}_supervisor`),
    {
      templateId: `${mineId}_supervisor`,
      mineId,
      role: "supervisor",
      version: 1,
      items: [...WORKER_ITEMS, ...SUPERVISOR_EXTRA_ITEMS],
    }
  );

  await batch.commit();

  console.log(`[seedChecklistTemplates] Seeded templates for mine ${mineId}`);
  return {success: true, mineId, templatesCreated: 2};
});
