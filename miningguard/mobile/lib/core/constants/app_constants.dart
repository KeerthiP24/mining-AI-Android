/// Central constants file. Import this wherever a magic value is needed.
/// Never hardcode strings, colors, or numbers directly in widget files.
class AppConstants {
  AppConstants._();

  // ── App Identity ──────────────────────────────────────────────────────────
  static const String appName = 'MiningGuard';
  static const String appVersion = '1.0.0';

  // ── Firestore Collection Names ────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String minesCollection = 'mines';
  static const String checklistsCollection = 'checklists';
  static const String hazardReportsCollection = 'hazard_reports';
  static const String safetyVideosCollection = 'safety_videos';
  static const String alertsCollection = 'alerts';

  // ── Hive Box Names (offline storage) ─────────────────────────────────────
  static const String checklistBox = 'checklist_box';
  static const String reportQueueBox = 'report_queue_box';
  static const String userCacheBox = 'user_cache_box';

  // ── FastAPI Backend Base URL ──────────────────────────────────────────────
  // Development: localhost for emulator, 10.0.2.2 for Android emulator
  // Production:  set via environment variable in release builds
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000/api/v1';
  static const String apiBaseUrlProd = 'https://YOUR_RENDER_URL.onrender.com/api/v1';

  // ── AI API Endpoint Paths ─────────────────────────────────────────────────
  static const String riskPredictEndpoint = '/risk/predict';
  static const String behaviorAnalyzeEndpoint = '/behavior/analyze';
  static const String imageDetectEndpoint = '/image/detect';
  static const String recommendationsEndpoint = '/recommendations';

  // ── Risk Levels ────────────────────────────────────────────────────────────
  static const String riskLow = 'low';
  static const String riskMedium = 'medium';
  static const String riskHigh = 'high';

  // ── User Roles ─────────────────────────────────────────────────────────────
  static const String roleWorker = 'worker';
  static const String roleSupervisor = 'supervisor';
  static const String roleAdmin = 'admin';

  // ── Checklist Status ───────────────────────────────────────────────────────
  static const String checklistPending = 'pending';
  static const String checklistInProgress = 'in_progress';
  static const String checklistCompleted = 'completed';
  static const String checklistMissed = 'missed';

  // ── Hazard Report Status ───────────────────────────────────────────────────
  static const String reportSubmitted = 'submitted';
  static const String reportAcknowledged = 'acknowledged';
  static const String reportInProgress = 'in_progress';
  static const String reportResolved = 'resolved';

  // ── Hazard Categories ──────────────────────────────────────────────────────
  static const List<String> hazardCategories = [
    'roof_fall',
    'gas_leak',
    'fire',
    'machinery',
    'electrical',
    'other',
  ];

  // ── Severity Levels ────────────────────────────────────────────────────────
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  // ── Supported Languages ────────────────────────────────────────────────────
  static const List<String> supportedLanguageCodes = [
    'en', 'hi', 'bn', 'te', 'mr', 'or',
  ];

  // ── Shift Types ────────────────────────────────────────────────────────────
  static const String shiftMorning = 'morning';
  static const String shiftAfternoon = 'afternoon';
  static const String shiftNight = 'night';

  // ── Compliance Scoring Weights ─────────────────────────────────────────────
  static const double mandatoryItemWeight = 0.70;
  static const double optionalItemWeight = 0.30;

  // ── Timeouts & Durations ───────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration checklistReminderDelay = Duration(hours: 1);
  static const int behaviorAnalysisWindowDays = 30;
  static const int riskWindowDays = 7;

  // ── FCM Notification Channels ──────────────────────────────────────────────
  static const String fcmChannelStandard = 'miningguard_standard';
  static const String fcmChannelCritical = 'miningguard_critical';
}
