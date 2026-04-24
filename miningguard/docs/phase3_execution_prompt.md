# MiningGuard — Phase 3 Execution Prompt
## Daily Safety Checklist System

> **Stack:** Flutter · Riverpod · Firestore · Firebase Cloud Functions  
> **Duration:** Week 3 (solo) / ~4–5 days (pair)  
> **Depends on:** Phase 1 (project skeleton, routing, Riverpod setup) + Phase 2 (Firebase Auth, user profile with role/shift/mine fields in Firestore)  
> **Feeds into:** Phase 6 (AI risk engine consumes compliance scores + missed-day counters)

---

## 1. Goal

Build the complete daily safety checklist experience end-to-end:

- Auto-generate the correct checklist for each worker the moment their shift begins
- Let workers check off items in real time with persistent progress
- Score compliance on submission (mandatory items 70%, optional items 30%)
- Surface missed checklists to supervisors and trigger the AI risk pipeline
- Store every submission as a timestamped, auditable record in Firestore

No AI logic lives in this phase. This phase only **produces** the structured data that Phase 6 will consume.

---

## 2. Prerequisites Checklist

Before writing a single line of Phase 3 code, confirm these are already in place from Phases 1–2:

- [ ] `users/{uid}` Firestore document exists with fields: `role`, `mineId`, `shift` (`morning` | `afternoon` | `night`), `language`, `consecutiveMissedDays` (int), `complianceRate` (double 0–1)
- [ ] Riverpod `authProvider` exposes the current `AppUser` (uid, role, shift, mineId)
- [ ] GoRouter has named routes: `home`, `checklist`, `checklist-history`
- [ ] Firebase project has Firestore enabled and local emulator configured
- [ ] `hive` and `hive_flutter` packages are added to `pubspec.yaml` (needed for offline cache in Phase 9, but the Hive box registration should happen now to avoid migration pain later)

---

## 3. Data Architecture

### 3.1 Firestore Schema

#### `checklist_templates/{templateId}`

Stores the master checklist definitions. **Never mutated by workers.** Only admins write here.

```
templateId          String   — "{mineId}_{role}" e.g. "mine001_worker"
mineId              String
role                String   — "worker" | "supervisor"
version             int      — increment when items change; stored on submissions for audit
items               List<Map>
  └── itemId        String   — stable unique ID e.g. "ppe_helmet"
      category      String   — "ppe" | "machinery" | "environment" | "emergency" | "supervisor"
      labelKey      String   — ARB localisation key e.g. "checklist_ppe_helmet"
      mandatory     bool
      order         int      — display order within category
```

#### `checklists/{checklistId}`

One document per worker per shift-day. Created automatically on first open.

```
checklistId         String   — "{uid}_{mineId}_{date}" e.g. "uid123_mine001_2025-07-14"
uid                 String
mineId              String
shift               String
date                String   — "YYYY-MM-DD" (local mine timezone)
templateVersion     int      — copied from template at generation time
status              String   — "in_progress" | "submitted" | "missed"
items               List<Map>
  └── itemId        String
      mandatory     bool
      completed     bool
      completedAt   Timestamp | null
createdAt           Timestamp
submittedAt         Timestamp | null
complianceScore     double   — 0.0–1.0, calculated on submission
mandatoryScore      double   — mandatory-only compliance (0.0–1.0)
```

#### `users/{uid}` — fields updated by this phase

```
complianceRate          double   — rolling 30-day average of complianceScore
consecutiveMissedDays   int      — reset to 0 on any submission; incremented by Cloud Function nightly
lastChecklistDate       String   — "YYYY-MM-DD"
```

---

### 3.2 Compliance Scoring Formula

```
mandatory_completed   = count of mandatory items where completed == true
mandatory_total       = count of mandatory items
optional_completed    = count of optional items where completed == true
optional_total        = count of optional items

mandatory_score = mandatory_completed / mandatory_total          // 0.0–1.0
optional_score  = optional_total > 0
                  ? optional_completed / optional_total
                  : 1.0                                          // full marks if no optional items

compliance_score = (mandatory_score * 0.70) + (optional_score * 0.30)
```

Store all three values (`complianceScore`, `mandatoryScore`, and the individual `optional_score` is derivable) on the submission document.

---

## 4. Checklist Item Definitions

Implement the following items in `checklist_templates`. Use these exact `itemId` values — Phase 6 references them by ID for pattern detection (e.g. "repeated gas detector misses").

### Worker Checklist

#### Category: PPE (`category: "ppe"`)

| itemId | Label Key | Mandatory |
|---|---|---|
| `ppe_helmet` | `checklist_ppe_helmet` | ✅ |
| `ppe_boots` | `checklist_ppe_boots` | ✅ |
| `ppe_vest` | `checklist_ppe_vest` | ✅ |
| `ppe_gloves` | `checklist_ppe_gloves` | ✅ |
| `ppe_lamp_charged` | `checklist_ppe_lamp_charged` | ✅ |
| `ppe_scsr_present` | `checklist_ppe_scsr_present` | ✅ |

#### Category: Machinery (`category: "machinery"`)

| itemId | Label Key | Mandatory |
|---|---|---|
| `mach_preshift_done` | `checklist_mach_preshift_done` | ✅ |
| `mach_guards_in_place` | `checklist_mach_guards_in_place` | ✅ |
| `mach_no_leaks` | `checklist_mach_no_leaks` | ✅ |

#### Category: Environment (`category: "environment"`)

| itemId | Label Key | Mandatory |
|---|---|---|
| `env_gas_detector_ok` | `checklist_env_gas_detector_ok` | ✅ |
| `env_roof_inspected` | `checklist_env_roof_inspected` | ✅ |
| `env_ventilation_ok` | `checklist_env_ventilation_ok` | ✅ |
| `env_walkways_clear` | `checklist_env_walkways_clear` | ⬜ |

#### Category: Emergency (`category: "emergency"`)

| itemId | Label Key | Mandatory |
|---|---|---|
| `emg_exit_known` | `checklist_emg_exit_known` | ✅ |
| `emg_comms_working` | `checklist_emg_comms_working` | ✅ |
| `emg_first_aid_located` | `checklist_emg_first_aid_located` | ⬜ |

### Supervisor Checklist

All 15 worker items above **plus** the following supervisor-only items:

#### Category: Supervisor (`category: "supervisor"`)

| itemId | Label Key | Mandatory |
|---|---|---|
| `sup_attendance_confirmed` | `checklist_sup_attendance_confirmed` | ✅ |
| `sup_toolbox_talk_done` | `checklist_sup_toolbox_talk_done` | ✅ |
| `sup_dgms_permits_reviewed` | `checklist_sup_dgms_permits_reviewed` | ✅ |
| `sup_high_risk_permits_checked` | `checklist_sup_high_risk_permits_checked` | ✅ |
| `sup_muster_point_communicated` | `checklist_sup_muster_point_communicated` | ⬜ |

---

## 5. Feature Breakdown

### Feature A — Checklist Generation Service

**File:** `lib/features/checklist/services/checklist_generation_service.dart`

**Trigger:** Called from `ChecklistScreen` `initState` / `ref.read` on first load each shift-day.

**Logic:**

```
1. Compute today's date string in mine-local timezone (use `intl` package)
2. Build checklistId = "{uid}_{mineId}_{date}"
3. Check Firestore: does checklists/{checklistId} already exist?
   ├── YES → return existing document (resume in-progress or show submitted state)
   └── NO  → fetch checklist_templates/{mineId}_{role}
             └── create new checklists/{checklistId} with:
                 - all items set to completed=false, completedAt=null
                 - status="in_progress"
                 - createdAt=now
```

**Edge cases to handle:**
- Template not found → log error + show "Contact your supervisor" message; do NOT crash
- Firestore offline → return cached Hive data if available (stub the Hive call now; full offline implementation is Phase 9)
- Role is `supervisor` → use `{mineId}_supervisor` template

---

### Feature B — Checklist Screen UI

**File:** `lib/features/checklist/screens/checklist_screen.dart`

**Layout:**

```
AppBar
  └── Title: "Today's Checklist"  (localised)
  └── Trailing: ComplianceProgressChip (e.g. "12 / 15")

Body (StreamBuilder on checklists/{checklistId})
  └── LinearProgressIndicator (overall % at top, full width)
  └── ListView
        └── For each category (sorted by defined order):
              └── CategoryHeader (collapsible)
                    └── For each item in category:
                          └── ChecklistItemTile

Sticky Bottom Bar (visible only when status == "in_progress")
  └── SubmitButton (enabled only when all MANDATORY items are completed)
  └── SubText: "X optional items remaining" (if any unchecked optional items)
```

**`ChecklistItemTile` widget:**

- Large tap target (minimum 56dp height) — glove-friendly
- Leading: `Checkbox` or custom animated check circle
- Title: localised item label in user's language
- Trailing: mandatory badge (`"Required"` chip) or nothing for optional
- On tap: call `checklistProvider.markItem(itemId, completed: true)`, write to Firestore immediately (do NOT batch — each tap is its own write so progress is never lost)
- Completed items: greyed out with strikethrough, non-interactive

**Category collapsing:**
- All categories start expanded
- Tapping a category header collapses it
- Show count of completed/total items in collapsed header

**Submit button behaviour:**
- Disabled + greyed out if any mandatory item is incomplete
- When tapped: show `AlertDialog` confirmation → on confirm, call submission logic
- Show `CircularProgressIndicator` during write
- After successful submission: navigate to `ChecklistSuccessScreen`

---

### Feature C — Item Completion Writer

**File:** `lib/features/checklist/providers/checklist_provider.dart`

Use `AsyncNotifier` (Riverpod 2.x). Expose:

```dart
// Marks a single item and writes to Firestore immediately
Future<void> markItem(String checklistId, String itemId, bool completed)

// Submits the checklist: calculates scores, updates status, triggers risk recalc
Future<void> submitChecklist(String checklistId)
```

**`markItem` implementation:**
- Optimistic update: update local state first, then write to Firestore
- On Firestore write failure: revert local state + show `SnackBar` error
- Write only the changed item field using dot-notation update:  
  `checklists/{id}` → `{ "items.{index}.completed": true, "items.{index}.completedAt": FieldValue.serverTimestamp() }`
  
  > Note: Firestore cannot update individual array elements by index with dot-notation. Store items as a `Map<String, ItemData>` keyed by `itemId` rather than as a `List` — this allows `items.ppe_helmet.completed = true` updates without rewriting the whole array.

**`submitChecklist` implementation:**
```
1. Read current items from local state
2. Calculate complianceScore, mandatoryScore (see formula in section 3.2)
3. Batch write to Firestore:
   a. checklists/{id}: { status: "submitted", submittedAt: now, complianceScore, mandatoryScore }
   b. users/{uid}: { lastChecklistDate: today, consecutiveMissedDays: 0 }
4. Trigger rolling complianceRate update (see Feature E)
5. Call FastAPI risk endpoint (Phase 6 stub — see section 7)
```

---

### Feature D — Checklist Success Screen

**File:** `lib/features/checklist/screens/checklist_success_screen.dart`

Shown immediately after successful submission. Keep it simple and positive.

**Contents:**
- Large green check animation (use `Lottie` package or a simple `AnimatedContainer`)
- Compliance score displayed prominently: e.g. `"85%"` in large text
- One-liner feedback based on score:
  - ≥ 90%: "Excellent — full compliance today!"
  - 70–89%: "Good — all critical items checked."
  - 50–69%: "Some items were missed. Stay safe."
  - < 50%: "Multiple items missed. Please speak with your supervisor."
- "Back to Home" button (navigates to `home` route, clearing checklist from back-stack)
- Do **not** show this screen again if the user navigates back and returns — detect `status == "submitted"` in `ChecklistScreen` and show a read-only submitted view instead

---

### Feature E — Rolling Compliance Rate Update

**File:** `functions/src/updateComplianceRate.ts` (Firebase Cloud Function)

**Trigger:** Firestore `onUpdate` on `checklists/{checklistId}` where `status` changes to `"submitted"`.

**Logic:**
```
1. Read last 30 submitted checklists for this uid (ordered by submittedAt desc, limit 30)
2. Average their complianceScore values
3. Write result to users/{uid}.complianceRate
```

Implement as a background function (not a callable). Keep it simple — no retry logic needed in Phase 3; Phase 8 adds retry/idempotency.

---

### Feature F — Missed Checklist Detection

**File:** `functions/src/detectMissedChecklists.ts` (Firebase Cloud Function)

**Trigger:** Cloud Scheduler — runs once daily at **23:30 mine local time** (configure per mine timezone; use a hardcoded UTC offset for now, make it configurable in Phase 7).

**Logic:**
```
For each user where role == "worker" OR role == "supervisor":
  today = current date string "YYYY-MM-DD"
  checklistId = "{uid}_{mineId}_{today}"

  doc = Firestore.get(checklists/{checklistId})

  if doc does not exist OR doc.status == "in_progress":
    // Mark as missed
    if doc exists:
      Firestore.update(checklists/{checklistId}, { status: "missed" })
    else:
      Firestore.create(checklists/{checklistId}, {
        uid, mineId, shift, date: today,
        status: "missed", createdAt: now,
        items: {},   // empty — never started
        complianceScore: 0.0,
        mandatoryScore: 0.0
      })

    // Increment consecutiveMissedDays on user profile
    Firestore.update(users/{uid}, {
      consecutiveMissedDays: FieldValue.increment(1)
    })

    // Write alert to alerts collection (Phase 8 will surface this via FCM)
    Firestore.create(alerts/{autoId}, {
      uid,
      supervisorUid: user.supervisorUid,
      type: "missed_checklist",
      severity: consecutiveMissedDays >= 3 ? "high" : "medium",
      message: "Worker missed checklist",
      date: today,
      isRead: false,
      createdAt: now
    })
```

---

### Feature G — Checklist History Screen

**File:** `lib/features/checklist/screens/checklist_history_screen.dart`

Reachable from the Worker Dashboard and via GoRouter named route `checklist-history`.

**Contents:**
- List of past checklists, ordered newest first
- Each row shows: date, shift, status badge (`Submitted` / `Missed`), compliance score
- Tapping a row opens a **read-only** detail view of that checklist's items and completion times
- Filtering: show last 7 days by default; "Load more" button for older history
- Missed entries shown with a red left border

---

### Feature H — Supervisor Checklist Overview

**File:** `lib/features/dashboard/widgets/supervisor_checklist_overview_widget.dart`

A widget for the Supervisor Dashboard (built in Phase 7, but the data query belongs to this phase).

**Riverpod provider:** `supervisorChecklistStatusProvider(mineId, date)` — returns a stream of all `checklists` documents for the given mine and date.

**Widget output (to be consumed by Phase 7 dashboard):**
- Total workers on shift
- Count with `status == "submitted"`
- Count with `status == "in_progress"`  
- Count with `status == "missed"` or document missing (= not started)
- List of workers who have NOT submitted, with their names

This widget can be stubbed/hidden in Phase 3 and activated when the Supervisor Dashboard is built in Phase 7. The **provider** must work correctly in Phase 3.

---

## 6. Localisation Keys (Phase 3 scope)

Add all of the following to `lib/l10n/app_en.arb` (and parallel files for hi, bn, te, mr, or):

```arb
{
  "checklist_title": "Today's Checklist",
  "checklist_submit_button": "Submit Checklist",
  "checklist_submit_confirm_title": "Submit your checklist?",
  "checklist_submit_confirm_body": "You cannot change your answers after submitting.",
  "checklist_submit_confirm_yes": "Submit",
  "checklist_submit_confirm_no": "Keep editing",
  "checklist_mandatory_badge": "Required",
  "checklist_progress_chip": "{completed} / {total}",
  "checklist_mandatory_incomplete_hint": "Complete all required items to submit",

  "checklist_ppe_helmet": "Hard hat fitted and in good condition",
  "checklist_ppe_boots": "Safety boots worn",
  "checklist_ppe_vest": "High-visibility vest worn",
  "checklist_ppe_gloves": "Safety gloves available",
  "checklist_ppe_lamp_charged": "Cap lamp charged and functional",
  "checklist_ppe_scsr_present": "Self-rescuer on person",

  "checklist_mach_preshift_done": "Pre-shift machinery inspection completed",
  "checklist_mach_guards_in_place": "All guards and covers in place",
  "checklist_mach_no_leaks": "No visible oil or hydraulic leaks",

  "checklist_env_gas_detector_ok": "Gas detector reading within safe limits (CH₄ < 1%)",
  "checklist_env_roof_inspected": "Roof and side walls inspected — no loose material",
  "checklist_env_ventilation_ok": "Ventilation is adequate",
  "checklist_env_walkways_clear": "Walkways and exits are clear",

  "checklist_emg_exit_known": "Nearest emergency exit location confirmed",
  "checklist_emg_comms_working": "Communication device working",
  "checklist_emg_first_aid_located": "Nearest first aid kit location known",

  "checklist_sup_attendance_confirmed": "All workers signed in for shift",
  "checklist_sup_toolbox_talk_done": "Toolbox safety briefing conducted",
  "checklist_sup_dgms_permits_reviewed": "DGMS permit-to-work documents reviewed",
  "checklist_sup_high_risk_permits_checked": "High-risk work authorisations verified",
  "checklist_sup_muster_point_communicated": "Muster point communicated to crew",

  "checklist_success_excellent": "Excellent — full compliance today!",
  "checklist_success_good": "Good — all critical items checked.",
  "checklist_success_fair": "Some items were missed. Stay safe.",
  "checklist_success_poor": "Multiple items missed. Please speak with your supervisor.",

  "checklist_status_submitted": "Submitted",
  "checklist_status_in_progress": "In Progress",
  "checklist_status_missed": "Missed",

  "checklist_history_title": "Checklist History",
  "checklist_history_load_more": "Load more",
  "checklist_already_submitted": "Checklist submitted for today",
  "checklist_error_template_not_found": "Checklist template not found. Contact your supervisor.",
  "checklist_reminder_notification_title": "Don't forget your safety checklist",
  "checklist_reminder_notification_body": "Your shift checklist is waiting — stay safe today."
}
```

Hindi (`app_hi.arb`), Bengali, Telugu, Marathi, and Odia translations to be supplied by a domain-knowledgeable translator before Phase 9 testing. Stub with English values for now with a `// TODO: translate` comment in each file.

---

## 7. Phase 6 Stub — Risk Recalculation Call

Phase 6 builds the FastAPI AI backend. Phase 3 must wire the call so Phase 6 only needs to implement the endpoint — not hunt for where to add the trigger.

**File:** `lib/core/services/ai_service.dart`

```dart
class AiService {
  /// Called after checklist submission.
  /// In Phase 3 this is a no-op that logs the call.
  /// Phase 6 replaces the body with a real HTTP POST.
  Future<void> triggerRiskRecalculation(String uid) async {
    debugPrint('[AiService] triggerRiskRecalculation called for $uid — stub, no-op in Phase 3');
    // Phase 6: POST /api/v1/risk/predict with uid and feature vector
  }
}
```

Call `AiService.triggerRiskRecalculation(uid)` at the end of `submitChecklist()` in the checklist provider.

---

## 8. Notification Stub — Checklist Reminder

Phase 8 builds the full FCM notification system. Phase 3 must create the data that Phase 8 will use to send reminders.

When a worker's checklist exists with `status == "in_progress"` and `createdAt` is older than 60 minutes, write a document to:

```
reminders/{uid}_checklist_{date}  →  { uid, type: "checklist_reminder", scheduledFor: <now+60min>, sent: false }
```

Phase 8's notification service will query `reminders` where `sent == false AND scheduledFor <= now` and deliver the FCM push. The data contract is established in Phase 3; delivery is Phase 8.

---

## 9. File & Folder Structure

```
lib/
└── features/
    └── checklist/
        ├── models/
        │   ├── checklist.dart              — Checklist data class + fromFirestore/toFirestore
        │   ├── checklist_item.dart         — ChecklistItem data class
        │   └── checklist_template.dart     — ChecklistTemplate data class
        ├── providers/
        │   ├── checklist_provider.dart     — AsyncNotifier: load, markItem, submitChecklist
        │   └── checklist_history_provider.dart
        ├── screens/
        │   ├── checklist_screen.dart       — Main checklist UI
        │   ├── checklist_success_screen.dart
        │   └── checklist_history_screen.dart
        ├── services/
        │   └── checklist_generation_service.dart
        └── widgets/
            ├── checklist_item_tile.dart
            ├── category_header.dart
            └── compliance_progress_chip.dart

functions/
└── src/
    ├── updateComplianceRate.ts
    └── detectMissedChecklists.ts
```

---

## 10. Firestore Security Rules (Phase 3 additions)

Add to `firestore.rules`:

```js
match /checklist_templates/{templateId} {
  // Any authenticated user can read templates for their mine
  allow read: if request.auth != null
              && resource.data.mineId == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.mineId;
  // Only admins can write
  allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

match /checklists/{checklistId} {
  // Workers can read/write only their own checklists
  allow read, update: if request.auth != null
                      && resource.data.uid == request.auth.uid;
  allow create: if request.auth != null
                && request.resource.data.uid == request.auth.uid;

  // Supervisors can read all checklists in their mine
  allow read: if request.auth != null
              && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'supervisor'
              && resource.data.mineId == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.mineId;

  // Admins have full access
  allow read, write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## 11. Testing Checklist

### Unit Tests (`test/features/checklist/`)

- [ ] `compliance_score_test.dart` — test scoring formula across 6 scenarios:
  - All mandatory + all optional complete → 1.0
  - All mandatory + no optional complete → 0.70
  - No mandatory + all optional complete → 0.30
  - No mandatory + no optional → 0.70 (no optional items treated as full optional score)
  - 50% mandatory + 50% optional → 0.50
  - Zero items total → handle gracefully, do not divide by zero

- [ ] `checklist_generation_service_test.dart` — mock Firestore; verify:
  - Existing checklist is returned unchanged
  - New checklist is created with correct `checklistId` format
  - Correct template is selected by role

### Widget Tests (`test/features/checklist/widgets/`)

- [ ] `checklist_item_tile_test.dart` — verify tap fires `markItem`, verify disabled state when `status == submitted`
- [ ] `submit_button_test.dart` — verify disabled when mandatory items incomplete; enabled when all mandatory complete

### Integration Tests (`integration_test/`)

- [ ] Full submission flow: generate → mark all mandatory → submit → verify Firestore document has `status=="submitted"` and `complianceScore > 0`
- [ ] Missed checklist function: write an `in_progress` checklist 2 hours old → trigger function manually → verify status becomes `"missed"` and `consecutiveMissedDays` incremented

---

## 12. Definition of Done

Phase 3 is complete when **all** of the following are true:

- [ ] Worker opens app → checklist auto-generated for their role and shift with correct items
- [ ] Tapping a checklist item saves to Firestore immediately (verify in Firebase console — each tap creates a write, not just on submit)
- [ ] Submitting a checklist calculates and stores `complianceScore` and `mandatoryScore` correctly
- [ ] Submit button is disabled until all mandatory items are checked
- [ ] Submitted checklist shows a read-only view on revisit — worker cannot resubmit for the same shift-day
- [ ] Checklist history screen shows last 7 days with correct status and score for each day
- [ ] Cloud Function `updateComplianceRate` runs on submission and updates `users/{uid}.complianceRate`
- [ ] Cloud Function `detectMissedChecklists` marks uncompleted checklists as `missed` at 23:30 and increments `consecutiveMissedDays`
- [ ] Supervisor can query (via provider) which workers have not submitted today's checklist
- [ ] All UI text is served via ARB localisation keys — no hardcoded English strings in widgets
- [ ] All unit and widget tests pass
- [ ] Firestore security rules prevent a worker from reading another worker's checklist
- [ ] `AiService.triggerRiskRecalculation` stub is called on submission (confirmed by `debugPrint` output)
- [ ] Reminder document is written to `reminders/` collection on checklist creation (Phase 8 stub)

---

## 13. Known Constraints & Notes

**Firestore array vs map for items:** Store checklist items as a Firestore `Map` (keyed by `itemId`), NOT a `List`. This is non-negotiable. Firestore cannot atomically update individual array elements; a map allows `items.ppe_helmet.completed = true` without rewriting the full items structure. This distinction matters for concurrent writes (e.g. supervisor and worker viewing the same document) and for the Phase 6 feature-vector extraction that reads specific items by ID.

**Timestamp authority:** Always use `FieldValue.serverTimestamp()` for `completedAt` and `submittedAt` writes. Never use `DateTime.now()` on the client. The AI risk engine uses completion time gaps to detect rushed checklists; client-side timestamps can be manipulated.

**Template versioning:** Store `templateVersion` on each checklist document at creation time. When a template changes (admin adds a new item), old submitted checklists are not invalidated — they are a historical record. New checklists pick up the new version. This ensures Phase 7 analytics can correctly compare checklists across template versions.

**Mine timezone:** Always compute today's date in the mine's local timezone, not the device's timezone. Store mine timezone in `mines/{mineId}.timezone` (e.g. `"Asia/Kolkata"`). Use the `timezone` Flutter package. Failing to do this causes split-day issues for night-shift workers whose phones may be in a different timezone than the mine.

---

*MiningGuard Phase 3 · Execution Prompt v1.0*  
*Next: Phase 4 — Hazard Reporting System*
