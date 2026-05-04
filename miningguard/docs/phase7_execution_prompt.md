# Phase 7 — Dashboards & Analytics
## Claude Code Execution Prompt · MiningGuard

> **Scope:** Week 8–9  
> **Depends on:** Phases 1–6 complete (Auth, Checklist, Hazard Reports, Education, AI Backend all functional)  
> **Produces:** Worker Dashboard, Supervisor Dashboard, Admin Panel — all wired to live Firestore + AI data

---

## Context for Claude Code

You are implementing Phase 7 of MiningGuard — an AI-powered mining safety Flutter app backed by Firebase and a FastAPI AI backend.

**Stack already in place from previous phases:**
- Flutter + Dart, state management via Riverpod, routing via GoRouter
- Firebase: Auth, Firestore, Storage, FCM
- FastAPI AI backend at `lib/core/services/api_service.dart` (base URL in `.env`)
- Existing Firestore collections: `users`, `checklists`, `hazard_reports`, `safety_videos`, `alerts`, `mines`
- Existing feature folders: `lib/features/auth/`, `lib/features/checklist/`, `lib/features/hazard/`, `lib/features/education/`
- Shared widget library at `lib/shared/widgets/`
- App theme/colors at `lib/core/theme/app_theme.dart`

**This phase adds:** `lib/features/dashboard/` (worker), `lib/features/supervisor/`, `lib/features/admin/`

---

## Step 0 — Read Existing Code Before Writing Anything

Before creating any file, run these reads to understand what already exists:

```
Read lib/core/theme/app_theme.dart          — color constants, text styles
Read lib/core/services/api_service.dart     — how FastAPI is called (base URL, auth headers)
Read lib/core/routing/app_router.dart       — existing routes, role-based redirect logic
Read lib/shared/widgets/                    — list all files; understand reusable components
Read lib/features/auth/data/user_model.dart — UserModel fields: uid, name, role, mineId, shift,
                                              riskScore, riskLevel, complianceRate, language,
                                              consecutiveMissedDays
Read lib/features/checklist/data/          — ChecklistModel, ChecklistItem
Read lib/features/hazard/data/             — HazardReportModel fields, status enum
Read lib/features/education/data/          — SafetyVideoModel
```

**Do not create a file that duplicates something already in shared/ or the existing feature folders.**

---

## Step 1 — Establish Color & Status Constants

If `app_theme.dart` does not already define these, add them there — do not scatter magic colors across widgets.

```dart
// Risk level colors
static const Color riskLow    = Color(0xFF2E7D32); // green[800]
static const Color riskMedium = Color(0xFFF57F17); // amber[900]
static const Color riskHigh   = Color(0xFFC62828); // red[800]

// Severity colors (for hazard reports)
static const Color severityLow      = Color(0xFF1565C0);
static const Color severityMedium   = Color(0xFFF57F17);
static const Color severityHigh     = Color(0xFFE65100);
static const Color severityCritical = Color(0xFFB71C1C);

// Status colors (report lifecycle)
static const Color statusPending    = Color(0xFF6A1B9A);
static const Color statusAcknowledged = Color(0xFF0277BD);
static const Color statusInProgress = Color(0xFFF57F17);
static const Color statusResolved   = Color(0xFF2E7D32);
```

---

## Step 2 — Shared Dashboard Widgets

Create `lib/shared/widgets/dashboard/` with these reusable components. Each must be a standalone StatelessWidget accepting only typed parameters — no Firestore calls inside widgets.

### 2a. `risk_level_badge.dart`

```
RiskLevelBadge({ required String level, bool large = false })
```

- Displays a pill/chip with background color from Step 1 constants
- `large = true` → 48px height, 20px text (used on Worker Dashboard hero card)
- `large = false` → 28px height, 13px text (used in worker list rows)
- level values: `"low"`, `"medium"`, `"high"` (case-insensitive)
- Shows: 🟢 LOW / 🟡 MEDIUM / 🔴 HIGH with icon + label

### 2b. `risk_score_bar.dart`

```
RiskScoreBar({ required int score })   // score: 0–100
```

- Horizontal linear progress bar, full width
- Color interpolates: 0–33 green, 34–66 amber, 67–100 red
- Shows score number to the right: `"72 / 100"`
- Animated on first render (300ms ease-in)

### 2c. `compliance_trend_chart.dart`

```
ComplianceTrendChart({ required List<ComplianceDataPoint> data, String? title })

class ComplianceDataPoint {
  final DateTime date;
  final double rate;   // 0.0–1.0
}
```

- Line chart using `fl_chart` package (add to pubspec if not present)
- X-axis: dates (show day/month labels every 5 points)
- Y-axis: 0–100% 
- Line color: green below 80% threshold shows amber, above shows green
- Threshold line at 80% drawn as dashed horizontal
- `title` renders as chart section header if provided

### 2d. `stat_card.dart`

```
StatCard({ required String label, required String value,
           required IconData icon, Color? color, VoidCallback? onTap })
```

- Square card with icon top-left, large value center, label below
- Used in Supervisor Dashboard top metrics row
- Tappable if `onTap` provided (shows ripple)

### 2e. `report_status_badge.dart`

```
ReportStatusBadge({ required String status })
```

- status values: `"pending"`, `"acknowledged"`, `"in_progress"`, `"resolved"`
- Uses colors from Step 1 constants
- Displays human-readable label with dot indicator

### 2f. `severity_badge.dart`

```
SeverityBadge({ required String severity })
```

- severity values: `"low"`, `"medium"`, `"high"`, `"critical"`
- Compact, inline use in report list rows

### 2g. `worker_list_tile.dart`

```
WorkerListTile({
  required String name,
  required String riskLevel,
  required int riskScore,
  required bool checklistDone,
  required int pendingReports,
  required VoidCallback onTap,
})
```

- Leading: Avatar with worker's initials
- Title: worker name + RiskLevelBadge (small)
- Subtitle: checklist status icon + pending report count
- Trailing: chevron icon
- Background tint: very faint version of risk level color (5% opacity)

---

## Step 3 — Riverpod Providers

Create `lib/features/dashboard/providers/` and `lib/features/supervisor/providers/` and `lib/features/admin/providers/`.

### 3a. Worker Dashboard Providers (`lib/features/dashboard/providers/worker_dashboard_provider.dart`)

```dart
// Stream of current user's Firestore document (already exists from Phase 2 — reuse it)
// If it doesn't exist, create:
final currentUserProvider = StreamProvider<UserModel>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => UserModel.fromFirestore(s));
});

// Today's checklist for current user
final todayChecklistProvider = StreamProvider<ChecklistModel?>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return FirebaseFirestore.instance
      .collection('checklists')
      .where('uid', isEqualTo: uid)
      .where('date', isEqualTo: today)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : ChecklistModel.fromFirestore(s.docs.first));
});

// Worker's last 5 hazard reports
final workerRecentReportsProvider = StreamProvider<List<HazardReportModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('hazard_reports')
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((s) => s.docs.map(HazardReportModel.fromFirestore).toList());
});

// Worker's unread alerts
final workerAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('alerts')
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(AlertModel.fromFirestore).toList());
});

// 30-day compliance history for mini trend chart
final workerComplianceHistoryProvider = FutureProvider<List<ComplianceDataPoint>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final since = DateTime.now().subtract(const Duration(days: 30));
  final snap = await FirebaseFirestore.instance
      .collection('checklists')
      .where('uid', isEqualTo: uid)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt')
      .get();
  return snap.docs.map((d) {
    final m = ChecklistModel.fromFirestore(d);
    return ComplianceDataPoint(date: m.createdAt, rate: m.completionRate);
  }).toList();
});
```

### 3b. Supervisor Dashboard Providers (`lib/features/supervisor/providers/supervisor_dashboard_provider.dart`)

```dart
// All workers in same mine as current supervisor
final mineWorkersProvider = StreamProvider<List<UserModel>>((ref) {
  final supervisor = ref.watch(currentUserProvider).valueOrNull;
  if (supervisor == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('role', isEqualTo: 'worker')
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
});

// Filter state for worker list
enum WorkerFilter { all, highRisk, pendingReports, checklistIncomplete }
final workerFilterProvider = StateProvider<WorkerFilter>((ref) => WorkerFilter.all);

// Derived: filtered + sorted worker list
final filteredWorkersProvider = Provider<List<UserModel>>((ref) {
  final workers = ref.watch(mineWorkersProvider).valueOrNull ?? [];
  final filter = ref.watch(workerFilterProvider);
  List<UserModel> filtered;
  switch (filter) {
    case WorkerFilter.highRisk:
      filtered = workers.where((w) => w.riskLevel == 'high').toList();
      break;
    case WorkerFilter.pendingReports:
      filtered = workers.where((w) => w.pendingReportCount > 0).toList();
      break;
    case WorkerFilter.checklistIncomplete:
      filtered = workers.where((w) => !w.todayChecklistDone).toList();
      break;
    case WorkerFilter.all:
    default:
      filtered = workers;
  }
  // Sort: high risk first, then medium, then low
  const order = {'high': 0, 'medium': 1, 'low': 2};
  filtered.sort((a, b) =>
      (order[a.riskLevel] ?? 3).compareTo(order[b.riskLevel] ?? 3));
  return filtered;
});

// Pending hazard reports for supervisor's mine, sorted by severity
final pendingReportsProvider = StreamProvider<List<HazardReportModel>>((ref) {
  final supervisor = ref.watch(currentUserProvider).valueOrNull;
  if (supervisor == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('hazard_reports')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('status', whereIn: ['pending', 'acknowledged', 'in_progress'])
      .orderBy('severity', descending: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(HazardReportModel.fromFirestore).toList());
});

// Mine-wide 30-day compliance trend
final mineComplianceTrendProvider = FutureProvider<List<ComplianceDataPoint>>((ref) async {
  final supervisor = ref.watch(currentUserProvider).valueOrNull;
  if (supervisor == null) return [];
  final since = DateTime.now().subtract(const Duration(days: 30));
  final snap = await FirebaseFirestore.instance
      .collection('checklists')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt')
      .get();
  // Group by date and average compliance rates per day
  // Return one ComplianceDataPoint per day
  final grouped = <String, List<double>>{};
  for (final doc in snap.docs) {
    final m = ChecklistModel.fromFirestore(doc);
    final key = DateFormat('yyyy-MM-dd').format(m.createdAt);
    grouped.putIfAbsent(key, () => []).add(m.completionRate);
  }
  return grouped.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return ComplianceDataPoint(
        date: DateFormat('yyyy-MM-dd').parse(e.key), rate: avg);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// Mine-wide summary counts (derived from stream data, no extra Firestore reads)
final mineSummaryProvider = Provider<MineSummary>((ref) {
  final workers = ref.watch(mineWorkersProvider).valueOrNull ?? [];
  final reports = ref.watch(pendingReportsProvider).valueOrNull ?? [];
  return MineSummary(
    totalWorkers: workers.length,
    highRiskCount: workers.where((w) => w.riskLevel == 'high').length,
    mediumRiskCount: workers.where((w) => w.riskLevel == 'medium').length,
    lowRiskCount: workers.where((w) => w.riskLevel == 'low').length,
    checklistCompletedCount: workers.where((w) => w.todayChecklistDone).length,
    pendingReportsCount: reports.length,
  );
});

class MineSummary {
  final int totalWorkers, highRiskCount, mediumRiskCount, lowRiskCount;
  final int checklistCompletedCount, pendingReportsCount;
  const MineSummary({...}); // generate constructor
  double get checklistCompletionRate =>
      totalWorkers == 0 ? 0 : checklistCompletedCount / totalWorkers;
}
```

### 3c. Admin Providers (`lib/features/admin/providers/admin_provider.dart`)

```dart
// All users across all mines (admin only — security rules enforce this)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
});

// All mines
final allMinesProvider = StreamProvider<List<MineModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('mines')
      .snapshots()
      .map((s) => s.docs.map(MineModel.fromFirestore).toList());
});

// All safety videos
final allVideosProvider = StreamProvider<List<SafetyVideoModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('safety_videos')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SafetyVideoModel.fromFirestore).toList());
});

// Monthly incident counts for bar chart (last 6 months)
final monthlyIncidentTrendProvider = FutureProvider<List<MonthlyIncidentData>>((ref) async {
  // Query hazard_reports grouping by month
  // Return list of MonthlyIncidentData { month, reportCount, criticalCount }
});

// Risk heatmap data: mine section → average risk score
final riskHeatmapProvider = FutureProvider<Map<String, double>>((ref) async {
  // Query users, group by mineSection, average riskScore
});

// State for user management operations
final userManagementProvider = AsyncNotifierProvider<UserManagementNotifier, void>(
  UserManagementNotifier.new,
);

class UserManagementNotifier extends AsyncNotifier<void> {
  Future<void> deactivateUser(String uid) async { ... }
  Future<void> updateUserRole(String uid, String newRole) async { ... }
  Future<void> bulkImportWorkers(List<Map<String, dynamic>> rows) async { ... }
}
```

---

## Step 4 — Worker Dashboard Screen

**File:** `lib/features/dashboard/screens/worker_dashboard_screen.dart`

This is the app's most-seen screen. Design it for speed of comprehension — a worker should know their safety status in 3 seconds.

### Layout (single scrollable column, no tabs)

```
┌────────────────────────────────────┐
│  AppBar: "Good morning, [Name]"    │  ← Greeting from currentUserProvider
│           [Mine Name]  [Alerts 🔔] │
├────────────────────────────────────┤
│                                    │
│  ╔══ RISK LEVEL CARD ════════════╗ │  ← Card with 16px elevation shadow
│  ║  [LARGE RiskLevelBadge]       ║ │
│  ║  [RiskScoreBar  72/100]       ║ │
│  ║                               ║ │
│  ║  Why: • 2 missed checklists   ║ │  ← AI contributing factors from
│  ║       • 1 high-severity rpt   ║ │    user.riskFactors list
│  ╚═══════════════════════════════╝ │
│                                    │
│  ── TODAY'S CHECKLIST ──────────── │
│  [Progress: 8/12 ▓▓▓▓▓▓░░  67%]  │
│  [▶ CONTINUE CHECKLIST  ───────►] │  ← ElevatedButton → checklist route
│  (or if done: ✅ Completed · 94%) │
│                                    │
│  ── VIDEO OF THE DAY ───────────── │
│  [Thumbnail  │  Title             │  ← SafetyVideoModel from education
│              │  Duration  ▶ Watch │    VideoOfDayService
│              └────────────────── ]│
│                                    │
│  ── RECENT REPORTS ─────────────── │
│  [Report row] Roof Fall  🔴HIGH   │  ← workerRecentReportsProvider
│  [Report row] PPE Issue  🟡MED    │    Each row taps → report detail
│  [Report row] ✅ Resolved         │
│  [+ File New Report  →]            │
│                                    │
│  ── ACTIVE ALERTS ──────────────── │
│  [Alert row] Risk elevated · 2h   │  ← workerAlertsProvider
│  [Alert row] Checklist reminder   │
│                                    │
│  ── MY COMPLIANCE (30 DAYS) ─────  │
│  [ComplianceTrendChart, height 160]│  ← workerComplianceHistoryProvider
│                                    │
└────────────────────────────────────┘
```

### Implementation notes

- Use `ConsumerWidget`. Watch all providers via `ref.watch(...)`.
- Wrap each section in a `Card` with `margin: EdgeInsets.symmetric(horizontal:16, vertical:6)`.
- Each section title uses `Text(style: Theme.of(context).textTheme.labelLarge)` in uppercase.
- Show `SkeletonLoader` (shimmer effect) while `AsyncValue` is loading — do not show empty space.
- Show `ErrorCard` widget if a provider returns an error — log but do not crash.
- The CONTINUE CHECKLIST button must use `context.go('/checklist')` via GoRouter.
- The VIDEO OF THE DAY card: if video is a YouTube link, tap opens YouTube via `url_launcher`. Show thumbnail with `CachedNetworkImage`.
- Mark alerts as read (`isRead = true` in Firestore) when the worker opens the alerts section.
- The greeting changes by time: "Good morning" before 12:00, "Good afternoon" 12–17:00, "Good evening" after 17:00.

---

## Step 5 — Supervisor Dashboard Screen

**File:** `lib/features/supervisor/screens/supervisor_dashboard_screen.dart`

Supervisors need speed and action — this screen is about scanning risk and dispatching responses.

### Layout (single scrollable column)

```
┌────────────────────────────────────────┐
│  AppBar: "Shift Dashboard"  [Export 📄]│
│  [Mine Name] · Morning Shift           │
├────────────────────────────────────────┤
│                                        │
│  ── MINE AT A GLANCE ───────────────── │
│  ┌────────┐┌────────┐┌────────┐┌────┐  │
│  │  24    ││  🔴 3  ││  12/24 ││ 5  │  │  ← StatCard row (horizontal scroll)
│  │Workers ││High Risk││Chkl✅  ││Rprt│  │
│  └────────┘└────────┘└────────┘└────┘  │
│                                        │
│  ── WORKERS ──────────────────────[▼]─ │  ← Filter dropdown
│  [All] [High Risk] [No Checklist] [Rpt]│  ← FilterChip row
│                                        │
│  ┌─ WorkerListTile ─────────────────┐  │
│  │  JK  John Kumar    🔴 HIGH  ›   │  │  ← Sorted high→low
│  │      ✗ checklist · 2 reports    │  │
│  └──────────────────────────────────┘  │
│  ┌─ WorkerListTile ─────────────────┐  │
│  │  PS  Priya Singh   🟡 MED   ›   │  │
│  │      ✓ checklist · 0 reports    │  │
│  └──────────────────────────────────┘  │
│  ... (ListView.builder, shrinkWrap)    │
│                                        │
│  ── PENDING REPORTS (5) ────────────── │
│  ┌─ Report tile ─────────────────────┐ │
│  │  🔴 CRITICAL · Roof Fall          │ │
│  │  Section B · Ram Prasad · 09:14am │ │
│  │  [Acknowledge] [View Details]     │ │
│  └───────────────────────────────────┘ │
│  ... (sorted by severity desc)         │
│                                        │
│  ── COMPLIANCE TREND (30 DAYS) ─────── │
│  [ComplianceTrendChart  height: 200]   │
│                                        │
└────────────────────────────────────────┘
```

### Sub-screen: Worker Detail (`supervisor_worker_detail_screen.dart`)

Opened when a worker tile is tapped. Shows:

```
AppBar: [Worker Name] + [Send Alert 🚨] action button

┌── RISK PROFILE ──────────────────────────┐
│  [Large RiskLevelBadge]  Score: 74/100    │
│  [RiskScoreBar]                           │
│  Contributing factors:                    │
│    • 3 missed checklists in 7 days        │
│    • Night shift compliance gap detected  │
│  Last updated: 2 hours ago               │
└──────────────────────────────────────────┘

┌── COMPLIANCE HISTORY (30 DAYS) ──────────┐
│  [ComplianceTrendChart]                   │
│  Overall rate: 72%  │  Missed: 4 shifts  │
└──────────────────────────────────────────┘

┌── HAZARD REPORTS ────────────────────────┐
│  [Report tile] ... [Report tile] ...     │
│  (last 10, tap to expand full report)    │
└──────────────────────────────────────────┘

┌── CHECKLIST HISTORY ─────────────────────┐
│  Mon 3 Jun · ✅ 94%                       │
│  Sun 2 Jun · ❌ MISSED                    │
│  Sat 1 Jun · ✅ 88%                       │
│  (last 14 days, simple list)             │
└──────────────────────────────────────────┘
```

**Send Alert dialog:** `AlertDialog` with `TextField` for message, fires `FirebaseFirestore.instance.collection('alerts').add({...})` with the worker's uid.

### Report action buttons

In the pending reports section, each report card has:

- **Acknowledge** button: sets `status = "acknowledged"` in Firestore
- **View Details** button: navigates to full report screen (already built in Phase 4)
- **Resolve** button (shown when status is `in_progress`): opens dialog with resolution note, sets `status = "resolved"`

All three are `OutlinedButton` / `ElevatedButton` with their respective status colors.

---

## Step 6 — Admin Panel Screen

**File:** `lib/features/admin/screens/admin_panel_screen.dart`

Use a `DefaultTabController` with 3 tabs: **Users**, **Content**, **Analytics**.

### Tab 1 — User Management

```
AppBar tab: Users

Search bar at top (filters allUsersProvider list by name/mineId)

┌── Add User FAB (bottom right) ─────┐

ListView of UserAdminTile:
  Avatar | Name · Role badge | Mine | Active toggle
  Tap → UserEditBottomSheet

UserEditBottomSheet:
  - Name (read-only display)
  - Role dropdown: worker / supervisor / admin
  - Mine assignment dropdown (from allMinesProvider)
  - Active / Deactivated toggle
  - Save button → userManagementProvider.updateUserRole(...)

Bulk Import section (at bottom):
  [📂 Import CSV] button
  Shows format hint: "CSV format: name, email, mineId, role, shift"
  On tap: FilePicker → parse CSV → userManagementProvider.bulkImportWorkers(...)
  Shows progress dialog with row count
```

### Tab 2 — Content Management

```
Section 1: Safety Videos
  - StreamBuilder on allVideosProvider
  - VideoAdminTile: thumbnail | title | category | [Edit] [Delete]
  - [+ Add Video] → AddVideoBottomSheet:
      - Title (English, localizable fields optional for now)
      - YouTube ID field
      - Category dropdown: PPE / Gas / Roof / Emergency / Machinery
      - Target roles: multi-select checkboxes
      - Tags text field (comma-separated)
      - Save → Firestore add to safety_videos

Section 2: Announcements
  - TextField for announcement message
  - Mine selector (all mines or specific)
  - [Send to All Workers] → writes to alerts collection for each worker in mine
    (use a batched write, max 500 per batch)
```

### Tab 3 — Analytics

```
Row 1: KPI Cards (StatCard × 4)
  Total Workers | Avg Compliance Rate | Total Reports (30d) | High Risk Workers

Row 2: Monthly Incident Bar Chart (fl_chart BarChart)
  X: last 6 months  Y: report count
  Two series: total reports (blue) + critical reports (red)
  Data from monthlyIncidentTrendProvider

Row 3: Risk Level Pie Chart (fl_chart PieChart)
  Three slices: Low (green) / Medium (amber) / High (red)
  Show percentages + absolute counts in legend below

Row 4: Risk Heatmap Table
  Simple DataTable: Mine Section | Avg Risk Score | Report Count | Trend
  Rows sorted by Avg Risk Score descending
  Data from riskHeatmapProvider

Row 5: DGMS Compliance Report Export
  [Export Report — PDF] button
  On tap: generates a plain-text/HTML summary and shares via share_plus package
  Report includes: mine name, date range, total checklists, completion %, 
  high-severity incidents count, worker count, avg compliance rate
```

---

## Step 7 — Routing Integration

Open `lib/core/routing/app_router.dart` and add/update these routes. **Do not remove existing routes.**

```dart
// Worker routes
GoRoute(
  path: '/dashboard',
  name: 'workerDashboard',
  builder: (ctx, state) => const WorkerDashboardScreen(),
),

// Supervisor routes
GoRoute(
  path: '/supervisor',
  name: 'supervisorDashboard',
  builder: (ctx, state) => const SupervisorDashboardScreen(),
  routes: [
    GoRoute(
      path: 'worker/:uid',
      name: 'supervisorWorkerDetail',
      builder: (ctx, state) => SupervisorWorkerDetailScreen(
        workerUid: state.pathParameters['uid']!,
      ),
    ),
  ],
),

// Admin routes
GoRoute(
  path: '/admin',
  name: 'adminPanel',
  builder: (ctx, state) => const AdminPanelScreen(),
),
```

Update the role-based redirect in the router's `redirect` callback:

```dart
// After successful login, redirect based on role:
if (role == 'worker')     return '/dashboard';
if (role == 'supervisor') return '/supervisor';
if (role == 'admin')      return '/admin';
```

Update the bottom navigation bar (in the shell route or main scaffold) to include the dashboard tab for workers and ensure supervisors land on `/supervisor`. The bottom nav for **workers** should be:

```
🏠 Home (/dashboard) | ✅ Checklist | ⚠️ Report | 🎥 Education | 👤 Profile
```

For **supervisors**, replace Home with:
```
📊 Dashboard (/supervisor) | ⚠️ Reports | 👷 Workers | 👤 Profile
```

---

## Step 8 — Data Model Updates

Check these models. If the fields below are missing, add them now.

### `UserModel` additions

```dart
final bool todayChecklistDone;    // computed: does today's checklist exist + status == 'submitted'?
final int pendingReportCount;     // from a denormalized counter in Firestore, updated by Cloud Function
final List<String> riskFactors;   // from AI: contributing factor strings, e.g. ["3 missed checklists"]
final String? mineName;           // denormalized from mines/ for display
```

**Important:** `todayChecklistDone` and `pendingReportCount` should be denormalized fields in the `users` Firestore document (updated by Cloud Functions from Phase 6), not computed with extra Firestore queries in the UI. If Phase 6 Cloud Functions do not yet write these fields, add a comment `// TODO Phase 6 CF must write this field` and show `false` / `0` as defaults.

### `HazardReportModel` additions (if missing)

```dart
final String workerName;     // denormalized at report creation time
final String mineSectionId;  // which section of the mine
final String mineId;         // for supervisor filtering
```

---

## Step 9 — Export / Share Feature

The supervisor's dashboard AppBar has an [Export] icon button. Implement this as:

```dart
// Generates a plain-text shift report and shares via share_plus
Future<void> exportShiftReport(MineSummary summary, List<UserModel> workers) async {
  final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());
  final buffer = StringBuffer();
  buffer.writeln('MiningGuard — Shift Safety Report');
  buffer.writeln('Generated: $now');
  buffer.writeln('─' * 40);
  buffer.writeln('Total workers on shift: ${summary.totalWorkers}');
  buffer.writeln('Checklists completed: ${summary.checklistCompletedCount}/${summary.totalWorkers}');
  buffer.writeln('Completion rate: ${(summary.checklistCompletionRate * 100).toStringAsFixed(1)}%');
  buffer.writeln('');
  buffer.writeln('RISK DISTRIBUTION:');
  buffer.writeln('  🔴 High:   ${summary.highRiskCount}');
  buffer.writeln('  🟡 Medium: ${summary.mediumRiskCount}');
  buffer.writeln('  🟢 Low:    ${summary.lowRiskCount}');
  buffer.writeln('');
  buffer.writeln('PENDING REPORTS: ${summary.pendingReportsCount}');
  buffer.writeln('');
  buffer.writeln('HIGH RISK WORKERS:');
  for (final w in workers.where((w) => w.riskLevel == 'high')) {
    buffer.writeln('  • ${w.name} — Score: ${w.riskScore}');
  }
  await Share.share(buffer.toString(), subject: 'MiningGuard Shift Report — $now');
}
```

---

## Step 10 — pubspec.yaml Dependencies

Check `pubspec.yaml`. Add any of the following that are not already present:

```yaml
dependencies:
  fl_chart: ^0.68.0          # Charts (compliance trend, bar, pie)
  cached_network_image: ^3.3.1 # Video thumbnails
  share_plus: ^9.0.0          # Export/share shift report
  file_picker: ^8.0.7         # CSV import in admin panel
  url_launcher: ^6.2.6        # Open YouTube links
  intl: ^0.19.0               # Date formatting
  shimmer: ^3.0.0             # Loading skeleton effect
```

Run `flutter pub get` after updating.

---

## Step 11 — Skeleton / Loading States

Every `AsyncValue` consumer must handle all three states:

```dart
ref.watch(someProvider).when(
  loading: () => const DashboardSkeletonLoader(),
  error:   (e, st) => ErrorCard(message: e.toString()),
  data:    (data) => ActualWidget(data: data),
);
```

Create `lib/shared/widgets/dashboard/dashboard_skeleton_loader.dart`:

- Uses `shimmer` package
- Shows grey rounded rectangles mimicking the real layout
- One variant for worker dashboard, one for supervisor dashboard
- The supervisor skeleton shows 3 StatCard shimmer boxes + 4 list tile shimmers

---

## Step 12 — Testing Checklist

After implementing all screens, verify the following manually in the emulator:

**Worker Dashboard**
- [ ] Risk level badge color matches riskLevel field in Firestore
- [ ] Risk score bar fills proportionally and is the correct color
- [ ] Contributing factors list shows AI-populated text (or "No factors available" if empty)
- [ ] Checklist card shows correct completion percentage
- [ ] Continue button routes to `/checklist`
- [ ] Video of the Day thumbnail loads and tapping opens YouTube
- [ ] Recent reports section shows correct status badges
- [ ] Alerts appear and tapping marks them as read
- [ ] Compliance trend chart renders with at least one data point

**Supervisor Dashboard**
- [ ] StatCard row shows correct live counts
- [ ] Worker list sorted high → medium → low risk
- [ ] All three filter chips work and update the list
- [ ] Tapping a worker navigates to their detail screen
- [ ] Worker detail shows correct compliance history and reports
- [ ] Send Alert dialog creates a Firestore document in `alerts/`
- [ ] Acknowledge / Resolve buttons update report status in Firestore
- [ ] Compliance trend chart shows mine-wide data (not individual worker)
- [ ] Export button generates and shares a text report

**Admin Panel**
- [ ] Users tab shows all users, search filters by name
- [ ] Role dropdown saves correctly to Firestore
- [ ] Deactivate toggle sets `isActive = false` in Firestore (user cannot log in)
- [ ] Add Video saves to `safety_videos/` with correct fields
- [ ] Announcement sends alerts to all workers in selected mine
- [ ] Monthly bar chart renders last 6 months
- [ ] Pie chart percentages sum to 100%
- [ ] Export report button triggers share sheet

---

## File Creation Order

Follow this order to avoid import errors:

1. `lib/core/theme/app_theme.dart` — add color constants (Step 1)
2. `lib/shared/widgets/dashboard/` — all 7 shared widgets (Step 2)
3. `lib/features/dashboard/providers/worker_dashboard_provider.dart` (Step 3a)
4. `lib/features/supervisor/providers/supervisor_dashboard_provider.dart` (Step 3b)
5. `lib/features/admin/providers/admin_provider.dart` (Step 3c)
6. `lib/features/dashboard/screens/worker_dashboard_screen.dart` (Step 4)
7. `lib/features/supervisor/screens/supervisor_dashboard_screen.dart` (Step 5)
8. `lib/features/supervisor/screens/supervisor_worker_detail_screen.dart` (Step 5)
9. `lib/features/admin/screens/admin_panel_screen.dart` (Step 6)
10. `lib/core/routing/app_router.dart` — add routes (Step 7)
11. `pubspec.yaml` — add dependencies (Step 10)
12. Run `flutter pub get`

---

## Common Pitfalls — Avoid These

| Pitfall | Correct approach |
|---|---|
| Making extra Firestore reads inside a widget's `build()` | Put all reads in Riverpod providers; widgets only call `ref.watch()` |
| Using `StreamBuilder` directly in screens | Use `StreamProvider` + `ref.watch(...).when(...)` pattern |
| Sorting in the UI from unsorted Firestore data | Sort in the provider (derived `Provider`), not in `build()` |
| Hardcoding colors in widget files | Always use `AppTheme.riskHigh` etc. from Step 1 constants |
| `ListView` inside a `Column` without `shrinkWrap: true` | Use `shrinkWrap: true, physics: NeverScrollableScrollPhysics()` for nested lists |
| Calling `context.go()` from inside a provider | Pass callbacks or use the router from the widget layer only |
| Not handling null `currentUser` in providers | Guard with `if (user == null) return const Stream.empty()` |
| Calling Firestore in `initState` | Use `ref.listen` or `FutureProvider`; never call Firebase in `initState` |

---

## Expected Outcome

When Phase 7 is complete:

- A **worker** opens the app → sees their risk level, checklist status, video and recent reports in under 3 seconds on a mid-range Android device
- A **supervisor** opens the app → sees mine-wide metrics, can filter workers by risk, tap into any worker's profile, and action pending reports — all within 30 seconds
- An **admin** opens the app → can manage users, upload content, and view analytics with charts for the past 30 days
- All three dashboards update **live** as Firestore documents change (no manual refresh needed)
- The app does not crash, show empty states, or freeze on any of the above paths

---

*MiningGuard · Phase 7 Execution Prompt · v1.0*  
*For Claude Code — implement top-to-bottom, read before writing, test after each screen*
