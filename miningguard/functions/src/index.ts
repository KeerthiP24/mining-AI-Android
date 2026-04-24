import * as admin from "firebase-admin";

admin.initializeApp();

export {updateComplianceRate} from "./updateComplianceRate";
export {detectMissedChecklists} from "./detectMissedChecklists";
export {seedChecklistTemplates} from "./seedChecklistTemplates";
export {notifySupervisorOnNewReport} from "./notifySupervisorOnNewReport";
export {notifyWorkerOnStatusChange} from "./notifyWorkerOnStatusChange";
