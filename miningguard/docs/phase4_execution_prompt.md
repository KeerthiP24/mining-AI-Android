# MiningGuard — Phase 4 Execution Prompt
## Hazard Reporting System

> **Use this prompt with your AI coding assistant (Claude Code, Cursor, Copilot, etc.) to implement Phase 4 of MiningGuard in full.**
> Paste this entire document as your starting context, then proceed task by task.

---

## 🧭 Context

You are building **MiningGuard**, an AI-powered mining safety companion app built with:

- **Frontend:** Flutter + Dart, Riverpod (state management), GoRouter (navigation), Dio (HTTP)
- **Backend:** Firebase (Auth, Firestore, Storage, FCM), FastAPI (Python) AI backend
- **Local Storage:** Hive (offline caching)

Phases 1–3 are already complete. The following are in place:
- Firebase project configured (dev + prod environments)
- Firebase Auth working with email/password and phone OTP
- Role-based routing: Worker → Worker Dashboard, Supervisor → Supervisor Dashboard
- Riverpod providers scaffolded; GoRouter configured
- Daily checklist system fully functional with compliance scoring
- Firestore collections: `users/`, `mines/`, `checklists/`

**Phase 4 goal:** Build the complete Hazard Reporting System — from a worker capturing a photo or voice note on their phone, through AI image analysis, to the supervisor receiving a notification and managing the report lifecycle.

---

## 📁 Folder Structure to Create

```
lib/
└── features/
    └── hazard_reporting/
        ├── data/
        │   ├── models/
        │   │   ├── hazard_report_model.dart
        │   │   └── ai_analysis_result_model.dart
        │   ├── repositories/
        │   │   └── hazard_report_repository.dart
        │   └── services/
        │       ├── media_upload_service.dart
        │       └── report_queue_service.dart       # offline queue
        ├── providers/
        │   ├── hazard_report_provider.dart
        │   └── report_list_provider.dart
        └── presentation/
            ├── screens/
            │   ├── report_input_screen.dart        # main entry point
            │   ├── my_reports_screen.dart
            │   └── report_detail_screen.dart
            └── widgets/
                ├── input_mode_selector.dart
                ├── photo_capture_widget.dart
                ├── voice_input_widget.dart
                ├── category_severity_picker.dart
                ├── ai_analysis_card.dart
                └── report_status_badge.dart

fastapi_backend/
└── app/
    └── routers/
        └── image_detection.py                     # new in Phase 4
```

---

## 🗄️ Firestore Schema

### Collection: `hazard_reports/{reportId}`

```json
{
  "reportId": "string",
  "uid": "string",
  "mineId": "string",
  "supervisorId": "string",
  "mineSection": "string",

  "inputMode": "photo | voice | text",
  "description": "string",
  "voiceTranscription": "string",

  "category": "roof_fall | gas_leak | fire | machinery | electrical | other",
  "severity": "low | medium | high | critical",

  "mediaUrls": ["string"],
  "voiceNoteUrl": "string | null",

  "aiAnalysis": {
    "hazardDetected": "string",
    "confidence": 0.0,
    "suggestedSeverity": "string",
    "recommendedAction": "string"
  },

  "status": "pending | acknowledged | in_progress | resolved",
  "supervisorNote": "string | null",

  "submittedAt": "Timestamp",
  "acknowledgedAt": "Timestamp | null",
  "resolvedAt": "Timestamp | null",

  "isOfflineCreated": false,
  "syncedAt": "Timestamp | null"
}
```

### Firebase Storage paths

```
storage/
└── reports/
    └── {mineId}/
        └── {reportId}/
            ├── image_0.jpg
            ├── image_1.jpg
            ├── video_0.mp4
            └── voice_note.aac
```

---

## ✅ Task List

Work through every task below in order. Do not skip any task. After completing each task, confirm it works before proceeding.

---

### TASK 1 — Data Model: `HazardReportModel`

Create `lib/features/hazard_reporting/data/models/hazard_report_model.dart`.

Requirements:
- Dart class with all fields from the Firestore schema above
- Use `freezed` + `json_serializable` for immutability and JSON serialization
- Include a `copyWith` method
- Include a factory `fromFirestore(DocumentSnapshot doc)` method
- Include a `toFirestore()` method returning `Map<String, dynamic>`
- Add an enum `HazardCategory` with values: `roofFall, gasLeak, fire, machinery, electrical, other`
- Add an enum `HazardSeverity` with values: `low, medium, high, critical`
- Add an enum `ReportStatus` with values: `pending, acknowledged, inProgress, resolved`
- Add an enum `InputMode` with values: `photo, voice, text`
- Each enum must have a `label` getter returning a human-readable string

---

### TASK 2 — Data Model: `AiAnalysisResult`

Create `lib/features/hazard_reporting/data/models/ai_analysis_result_model.dart`.

Requirements:
- Fields: `hazardDetected` (String), `confidence` (double, 0.0–1.0), `suggestedSeverity` (HazardSeverity), `recommendedAction` (String)
- Factory `fromJson(Map<String, dynamic> json)` method
- A `confidencePercent` getter returning `(confidence * 100).round()`
- A `isHighConfidence` getter returning `true` if confidence >= 0.75

---

### TASK 3 — Repository: `HazardReportRepository`

Create `lib/features/hazard_reporting/data/repositories/hazard_report_repository.dart`.

Implement the following methods:

```dart
// Submit a new report to Firestore
Future<String> submitReport(HazardReportModel report);

// Update report status (supervisor action)
Future<void> updateStatus(String reportId, ReportStatus status, {String? supervisorNote});

// Fetch a single report by ID
Future<HazardReportModel?> getReport(String reportId);

// Stream of reports for the current worker (filtered by uid)
Stream<List<HazardReportModel>> watchWorkerReports(String uid);

// Stream of all pending/in-progress reports for a supervisor's mine
Stream<List<HazardReportModel>> watchMineReports(String mineId);
```

Requirements:
- Inject `FirebaseFirestore` via the constructor (use Riverpod to provide it)
- Use the `hazard_reports` collection
- Sort `watchMineReports` by `submittedAt` descending, then by `severity` (critical first)
- All errors must be caught and rethrown as a typed `ReportException` with a human-readable message

---

### TASK 4 — Service: `MediaUploadService`

Create `lib/features/hazard_reporting/data/services/media_upload_service.dart`.

Implement:

```dart
// Upload a list of image/video files and return their download URLs
Future<List<String>> uploadMedia(String mineId, String reportId, List<File> files);

// Upload a voice note and return its download URL
Future<String> uploadVoiceNote(String mineId, String reportId, File audioFile);
```

Requirements:
- Use `firebase_storage` package
- Storage path pattern: `reports/{mineId}/{reportId}/image_{index}.jpg`
- Compress images before upload using `flutter_image_compress` (max width 1280px, quality 75)
- Show upload progress via a `StreamController<double>` (0.0 to 1.0) exposed as a getter `uploadProgress`
- Retry failed uploads up to 3 times with exponential backoff (1s, 2s, 4s)
- Validate MIME type before uploading — only allow `image/*`, `video/*`, `audio/*`; throw `InvalidFileTypeException` otherwise

---

### TASK 5 — Service: `ReportQueueService` (Offline Support)

Create `lib/features/hazard_reporting/data/services/report_queue_service.dart`.

This service manages reports created while offline.

Requirements:
- Use `Hive` to persist a queue of `HazardReportModel` objects locally under box name `'offline_reports'`
- Method `enqueue(HazardReportModel report)` — saves the report to the local Hive box
- Method `flush()` — iterates the queue, attempts to submit each report via `HazardReportRepository`, removes successfully synced items, leaves failed items for the next attempt
- Method `pendingCount` getter — returns the number of reports currently in the queue
- Call `flush()` automatically when internet connectivity is restored (use `connectivity_plus` package to listen for connection changes)
- Mark reports created offline with `isOfflineCreated: true`

---

### TASK 6 — Riverpod Providers

Create `lib/features/hazard_reporting/providers/hazard_report_provider.dart`.

Implement the following providers:

```dart
// Provides the repository
final hazardReportRepositoryProvider = Provider<HazardReportRepository>(...);

// Manages the state of an in-progress report submission
// States: idle, loading, success(reportId), error(message)
final reportSubmissionProvider = StateNotifierProvider<ReportSubmissionNotifier, ReportSubmissionState>(...);

// Streams worker's own reports
final workerReportsProvider = StreamProvider.family<List<HazardReportModel>, String>((ref, uid) => ...);

// Streams all mine reports (supervisor use)
final mineReportsProvider = StreamProvider.family<List<HazardReportModel>, String>((ref, mineId) => ...);
```

`ReportSubmissionNotifier` must expose:
- `setInputMode(InputMode mode)`
- `attachMedia(List<File> files)`
- `attachVoiceNote(File audio, String transcription)`
- `setDescription(String text)`
- `setCategory(HazardCategory category)`
- `setSeverity(HazardSeverity severity)`
- `setMineSection(String section)`
- `applyAiSuggestion(AiAnalysisResult result)` — pre-fills severity if worker accepts
- `submit()` — validates, calls upload service, calls repository, triggers FCM via Cloud Function

---

### TASK 7 — FastAPI: `/api/v1/image/detect` Endpoint

In `fastapi_backend/app/routers/image_detection.py`, implement the image analysis endpoint.

**Request:** `multipart/form-data` with field `file` (image upload)

**Response JSON:**
```json
{
  "hazard_detected": "missing_helmet | missing_vest | unsafe_environment | machinery_hazard | safe",
  "confidence": 0.91,
  "suggested_severity": "high",
  "recommended_action": "Worker must put on helmet before entering the work area."
}
```

Requirements:
- Use TensorFlow with a pre-trained **MobileNetV2** base, fine-tuned with a custom classification head for 5 classes (see above)
- Since real training data is not yet available, initialize the model with **ImageNet weights** and add a classification head. Return mock high-confidence predictions for now with a `TODO` comment marking where real fine-tuned weights will be loaded
- Accept only images (validate `content_type` starts with `image/`); return HTTP 422 for invalid files
- Resize input image to 224×224 before inference
- Verify the Firebase ID token from the `Authorization: Bearer <token>` header before processing; return HTTP 401 if missing or invalid
- Log inference time in milliseconds to the console
- Register this router in `main.py` with prefix `/api/v1`

---

### TASK 8 — Riverpod Provider: AI Image Analysis

Create `lib/features/hazard_reporting/providers/ai_analysis_provider.dart`.

```dart
final imageAnalysisProvider = FutureProvider.family<AiAnalysisResult, File>((ref, imageFile) async {
  // 1. Get current user's Firebase ID token
  // 2. POST multipart request to FastAPI /api/v1/image/detect
  // 3. Parse response into AiAnalysisResult
  // 4. Return result
});
```

Requirements:
- Use `Dio` for the HTTP request
- Set a 10-second timeout; if the backend is unreachable, return a fallback `AiAnalysisResult` with `confidence: 0.0` and `hazardDetected: 'unknown'` rather than throwing — the worker must still be able to submit their report
- Attach the Firebase ID token as `Authorization: Bearer <token>`

---

### TASK 9 — UI: `ReportInputScreen`

Create `lib/features/hazard_reporting/presentation/screens/report_input_screen.dart`.

This is the main screen workers use to file a report. It is reached via the bottom nav bar "Report Hazard" tab.

**Layout (top to bottom):**

1. **AppBar** — title "Report Hazard", back button
2. **Input Mode Selector** — three large tappable cards: 📷 Photo/Video, 🎤 Voice, ✏️ Text. The selected mode is highlighted. Switching modes clears previous input for that slot.
3. **Input Area** — changes based on selected mode:
   - *Photo/Video:* A grid showing selected media thumbnails (max 5). A "+" button opens the image picker (camera or gallery). Videos show a play icon overlay. If an image is selected, trigger `imageAnalysisProvider` automatically and show a loading shimmer while analysis runs.
   - *Voice:* A large circular microphone button. Tapping starts recording; tapping again stops. Shows waveform animation while recording. Transcribed text appears in a read-only text field below the button. The audio file is attached silently.
   - *Text:* A multiline text field, minimum 3 lines, character counter, max 500 characters.
4. **AI Analysis Card** — appears below the input area after image analysis completes (only for Photo mode). Shows the detected hazard, confidence percentage as a progress bar, and suggested severity with a chip. Two buttons: "Accept Suggestion" and "I'll set manually."
5. **Category Picker** — a horizontal scrollable row of icon+label chips: Roof Fall, Gas Leak, Fire, Machinery, Electrical, Other.
6. **Severity Picker** — four colored chips: Low (green), Medium (amber), High (orange), Critical (red). Required field — validated on submit.
7. **Mine Section Dropdown** — dropdown populated from the worker's mine sections. Required field.
8. **Submit Button** — full-width, shows a loading spinner during submission. Disabled if required fields are missing.

Requirements:
- All state managed by `reportSubmissionProvider`
- Show a `SnackBar` on success: "Report submitted successfully"
- On success, navigate to `MyReportsScreen` and pass the new `reportId`
- Show an `AlertDialog` on error with the error message and a "Retry" button
- The entire screen must be scrollable

---

### TASK 10 — Widget: `VoiceInputWidget`

Create `lib/features/hazard_reporting/presentation/widgets/voice_input_widget.dart`.

Requirements:
- Use `speech_to_text` package for transcription
- Use `record` package for saving the audio file to a temp path
- Show recording state clearly: idle (grey mic), recording (red pulsing mic with timer), done (green mic with transcription visible)
- Support languages: `en_US`, `hi_IN`, `bn_IN`, `te_IN`, `mr_IN`, `or_IN` — read the active language from the user's profile via a Riverpod provider
- If speech-to-text is unavailable (permissions denied or unsupported device), show a fallback text field with a notice: "Voice not available — please type your report."
- Expose `onTranscriptionComplete(String text, File audioFile)` callback

---

### TASK 11 — Widget: `AiAnalysisCard`

Create `lib/features/hazard_reporting/presentation/widgets/ai_analysis_card.dart`.

Requirements:
- Displays: hazard type label, confidence percentage bar (animated), suggested severity chip (color-coded), recommended action text
- "Accept Suggestion" button calls `ref.read(reportSubmissionProvider.notifier).applyAiSuggestion(result)`
- "I'll set manually" button dismisses the card without applying the suggestion
- If `confidence < 0.5`, show a disclaimer: "Low confidence — please verify manually"
- Animate in with a slide-up + fade transition

---

### TASK 12 — Screen: `MyReportsScreen`

Create `lib/features/hazard_reporting/presentation/screens/my_reports_screen.dart`.

Requirements:
- Uses `workerReportsProvider(currentUserId)` to stream the worker's reports
- Shows a `ListView` of report cards. Each card shows: category icon, severity badge (color-coded), one-line description preview, mine section, time ago (e.g., "2 hours ago"), and a `ReportStatusBadge`
- Tapping a card navigates to `ReportDetailScreen`
- Empty state: illustration + "No reports yet. Tap + to report a hazard."
- Loading state: shimmer placeholder cards
- Error state: retry button

---

### TASK 13 — Screen: `ReportDetailScreen`

Create `lib/features/hazard_reporting/presentation/screens/report_detail_screen.dart`.

Requirements:
- Receives `reportId` as a GoRouter path parameter
- Displays all report fields: full description, category, severity, mine section, submitted time, media gallery (horizontal scroll of images/videos), voice note player (if present), AI analysis summary, status timeline
- **Status timeline** — a vertical stepper showing the four lifecycle stages (Submitted, Acknowledged, In Progress, Resolved) with timestamps for completed stages and a greyed-out style for future stages
- If the current user is a **supervisor**, show action buttons based on current status:
  - `pending` → "Acknowledge" button
  - `acknowledged` → "Mark In Progress" button
  - `in_progress` → "Mark Resolved" button + optional note text field
- If the current user is a **worker**, status is read-only

---

### TASK 14 — GoRouter Integration

In the app's router configuration file, add the following routes:

```dart
GoRoute(
  path: '/report',
  builder: (context, state) => const ReportInputScreen(),
),
GoRoute(
  path: '/reports',
  builder: (context, state) => const MyReportsScreen(),
),
GoRoute(
  path: '/reports/:reportId',
  builder: (context, state) => ReportDetailScreen(
    reportId: state.pathParameters['reportId']!,
  ),
),
```

- Add "Report Hazard" as the third tab in the Worker bottom navigation bar, with a `Icons.warning_amber_rounded` icon
- Add "Pending Reports" as the third tab in the Supervisor bottom navigation bar

---

### TASK 15 — Firebase Cloud Function: Supervisor Notification

In `functions/src/index.ts` (or `functions/main.py` if using Python), add a Firestore trigger:

```
onDocumentCreated('hazard_reports/{reportId}')
```

When a new hazard report document is created:
1. Read `supervisorId` from the report
2. Fetch the supervisor's FCM token from `users/{supervisorId}`
3. Send an FCM notification:
   - **Title:** "New Hazard Report — {severity} severity"
   - **Body:** "{category} reported in {mineSection} by {workerName}"
   - **Data payload:** `{ reportId, mineId, severity }`
4. For `critical` severity, set `android.priority: 'high'` and `android.notification.channel_id: 'critical_safety'`

Also add a second trigger:

```
onDocumentUpdated('hazard_reports/{reportId}')
```

When `status` changes, send an FCM notification to the report's original `uid` (the worker):
- **Title:** "Report Update"
- **Body:** "Your {category} report has been marked as {newStatus}."

---

### TASK 16 — Supervisor Report Queue (Supervisor Dashboard Addition)

In the Supervisor Dashboard screen (built in Phase 7 placeholder), add a **Pending Reports** section:

- Uses `mineReportsProvider(mineId)` filtered to `status == pending || status == in_progress`
- Shows reports sorted by severity (critical first), then by time (oldest first)
- Each item shows: severity badge, category icon, worker name, mine section, time since submission
- Tapping navigates to `ReportDetailScreen`
- Badge on the bottom nav tab shows the count of pending reports (updates in real time)

---

## 🔗 Dependencies to Add

In `pubspec.yaml`, ensure the following packages are present:

```yaml
dependencies:
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  speech_to_text: ^6.6.0
  record: ^5.1.2
  firebase_storage: ^11.7.6
  connectivity_plus: ^6.0.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  timeago: ^3.6.1
  video_player: ^2.8.3

dev_dependencies:
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  build_runner: ^2.4.8
  hive_generator: ^2.0.1
```

In `requirements.txt` (FastAPI backend), ensure:
```
tensorflow==2.15.0
pillow==10.2.0
python-multipart==0.0.9
```

---

## 🧪 Verification Checklist

Before marking Phase 4 complete, confirm every item below works end-to-end:

- [ ] A worker can open the Report screen and select Photo, Voice, or Text input mode
- [ ] A worker can capture a photo from camera OR select from gallery
- [ ] After selecting a photo, the AI analysis card appears within 2 seconds
- [ ] The AI analysis card shows hazard type, confidence bar, and suggested severity
- [ ] "Accept Suggestion" pre-fills the severity picker correctly
- [ ] A worker can record a voice note; transcription appears in the text field
- [ ] Voice input works in at least Hindi and English
- [ ] Category and severity fields are required; submitting without them shows validation errors
- [ ] The report is saved to Firestore `hazard_reports/` with all fields populated correctly
- [ ] Media files appear in Firebase Storage at the correct path
- [ ] The supervisor receives a push notification within 5 seconds of submission
- [ ] Critical severity reports trigger a high-priority notification (loud, bypasses DND)
- [ ] The worker can view all their reports in `MyReportsScreen` with correct status badges
- [ ] The supervisor can open a report and tap "Acknowledge" — status updates in Firestore
- [ ] The worker receives a push notification when the supervisor changes the report status
- [ ] The status timeline in `ReportDetailScreen` correctly shows timestamps for completed stages
- [ ] Creating a report while offline saves it to the Hive queue
- [ ] When connectivity is restored, the queued report automatically syncs to Firestore
- [ ] The offline-created report is marked `isOfflineCreated: true` in Firestore after sync
- [ ] The FastAPI `/api/v1/image/detect` endpoint returns a valid JSON response
- [ ] The endpoint returns HTTP 401 for requests without a valid Firebase token
- [ ] The endpoint returns HTTP 422 for non-image file uploads

---

## 📌 Notes for Implementation

**Image compression** must happen before both the upload and the AI analysis call — send the compressed version to the backend, not the original.

**Voice note and transcription** are stored separately: the transcription goes into `voiceTranscription` (searchable text), the audio file URL goes into `voiceNoteUrl` (for playback). Both must be populated.

**Offline queue** items should be displayed in `MyReportsScreen` immediately — do not wait for sync. Show a small "⏳ Syncing..." badge on unsynced reports.

**Never block the submit button** due to AI analysis. If analysis is still loading when the worker taps submit, proceed with the worker's manually selected severity.

**The FastAPI model in Phase 4 uses mock outputs.** Real training data and fine-tuned weights will be integrated in Phase 6. The endpoint contract (input/output format) must not change between phases.

---

*MiningGuard · Phase 4 · Hazard Reporting System*
*Stack: Flutter · Firebase · FastAPI · TensorFlow MobileNetV2*
