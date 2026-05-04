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
exports.recomputeDashboardCounters = exports.onHazardReportStatusChangeDenorm = exports.onHazardReportCreatedDenorm = exports.dailyResetTodayChecklistFlag = exports.onChecklistSubmittedDenorm = exports.dailyBehaviorAnalysis = exports.onHazardReportCreatedAi = exports.onChecklistStatusChange = exports.onVideoWatched = exports.notifyWorkerOnStatusChange = exports.notifySupervisorOnNewReport = exports.seedChecklistTemplates = exports.detectMissedChecklists = exports.updateComplianceRate = void 0;
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
var updateComplianceRate_1 = require("./updateComplianceRate");
Object.defineProperty(exports, "updateComplianceRate", { enumerable: true, get: function () { return updateComplianceRate_1.updateComplianceRate; } });
var detectMissedChecklists_1 = require("./detectMissedChecklists");
Object.defineProperty(exports, "detectMissedChecklists", { enumerable: true, get: function () { return detectMissedChecklists_1.detectMissedChecklists; } });
var seedChecklistTemplates_1 = require("./seedChecklistTemplates");
Object.defineProperty(exports, "seedChecklistTemplates", { enumerable: true, get: function () { return seedChecklistTemplates_1.seedChecklistTemplates; } });
var notifySupervisorOnNewReport_1 = require("./notifySupervisorOnNewReport");
Object.defineProperty(exports, "notifySupervisorOnNewReport", { enumerable: true, get: function () { return notifySupervisorOnNewReport_1.notifySupervisorOnNewReport; } });
var notifyWorkerOnStatusChange_1 = require("./notifyWorkerOnStatusChange");
Object.defineProperty(exports, "notifyWorkerOnStatusChange", { enumerable: true, get: function () { return notifyWorkerOnStatusChange_1.notifyWorkerOnStatusChange; } });
var onVideoWatched_1 = require("./onVideoWatched");
Object.defineProperty(exports, "onVideoWatched", { enumerable: true, get: function () { return onVideoWatched_1.onVideoWatched; } });
// Phase 6 — AI-backend triggers
var aiTriggers_1 = require("./aiTriggers");
Object.defineProperty(exports, "onChecklistStatusChange", { enumerable: true, get: function () { return aiTriggers_1.onChecklistStatusChange; } });
Object.defineProperty(exports, "onHazardReportCreatedAi", { enumerable: true, get: function () { return aiTriggers_1.onHazardReportCreatedAi; } });
Object.defineProperty(exports, "dailyBehaviorAnalysis", { enumerable: true, get: function () { return aiTriggers_1.dailyBehaviorAnalysis; } });
// Phase 7 — dashboard counter denormalisation
var denormaliseDashboardCounters_1 = require("./denormaliseDashboardCounters");
Object.defineProperty(exports, "onChecklistSubmittedDenorm", { enumerable: true, get: function () { return denormaliseDashboardCounters_1.onChecklistSubmittedDenorm; } });
Object.defineProperty(exports, "dailyResetTodayChecklistFlag", { enumerable: true, get: function () { return denormaliseDashboardCounters_1.dailyResetTodayChecklistFlag; } });
Object.defineProperty(exports, "onHazardReportCreatedDenorm", { enumerable: true, get: function () { return denormaliseDashboardCounters_1.onHazardReportCreatedDenorm; } });
Object.defineProperty(exports, "onHazardReportStatusChangeDenorm", { enumerable: true, get: function () { return denormaliseDashboardCounters_1.onHazardReportStatusChangeDenorm; } });
Object.defineProperty(exports, "recomputeDashboardCounters", { enumerable: true, get: function () { return denormaliseDashboardCounters_1.recomputeDashboardCounters; } });
//# sourceMappingURL=index.js.map