import * as admin from "firebase-admin";

admin.initializeApp();

export {updateComplianceRate} from "./updateComplianceRate";
export {detectMissedChecklists} from "./detectMissedChecklists";
export {seedChecklistTemplates} from "./seedChecklistTemplates";
export {notifySupervisorOnNewReport} from "./notifySupervisorOnNewReport";
export {notifyWorkerOnStatusChange} from "./notifyWorkerOnStatusChange";
export {onVideoWatched} from "./onVideoWatched";

// Phase 6 — AI-backend triggers
export {
  onChecklistStatusChange,
  onHazardReportCreatedAi,
  dailyBehaviorAnalysis,
} from "./aiTriggers";

// Phase 7 — dashboard counter denormalisation
export {
  onChecklistSubmittedDenorm,
  dailyResetTodayChecklistFlag,
  onHazardReportCreatedDenorm,
  onHazardReportStatusChangeDenorm,
  recomputeDashboardCounters,
} from "./denormaliseDashboardCounters";
