# MiningGuard — Phase 5 Execution Prompt
## Safety Education Module
**Stack:** Flutter · Riverpod · GoRouter · Firebase Firestore · Firebase Storage · FastAPI · YouTube API  
**Depends on:** Phase 1 (project structure), Phase 2 (auth + user profile), Phase 3 (checklist data), Phase 4 (hazard report data)  
**Parallel safe:** Phase 5 can be developed in parallel with Phase 4 by a second developer, provided the shared Firestore data models from Phase 3 are finalized.

---

## 1. Objective

Build the Safety Education Module — a short-form video learning experience that delivers a personalized daily safety video to each worker, supports category browsing, tracks watch progress, and serves comprehension quizzes. All watch data must be written to Firestore so the Phase 6 AI backend can use it as a positive behavioral signal in risk scoring.

By the end of this phase, every worker sees a Video of the Day tailored to their role and recent activity, can browse the full content library, earns compliance points for passing quizzes, and has their engagement recorded in a format the AI engine can consume.

---

## 2. Firestore Data Models

### 2.1 `safety_videos` collection

Create this collection in Firestore. Each document represents one video.

```
safety_videos/{videoId}
├── videoId: String            // auto-generated Firestore ID
├── title: Map<String, String> // localized: { "en": "...", "hi": "...", "bn": "...", "te": "...", "mr": "...", "or": "..." }
├── description: Map<String, String> // localized description
├── category: String           // "ppe" | "gas_ventilation" | "roof_support" | "emergency" | "machinery"
├── source: String             // "DGMS" | "MSHA" | "HSE" | "WorkSafe" | "Custom"
├── youtubeId: String          // YouTube video ID (unlisted link, extract the ID portion)
├── thumbnailUrl: String       // YouTube thumbnail URL: https://img.youtube.com/vi/{youtubeId}/hqdefault.jpg
├── durationSeconds: int       // total video duration in seconds
├── targetRoles: List<String>  // ["worker"] | ["supervisor"] | ["worker", "supervisor"]
├── tags: List<String>         // e.g. ["helmet", "ppe", "underground"]
├── quizQuestions: List<Map>   // see quiz schema below
├── uploadedAt: Timestamp
└── isActive: bool             // false = hidden from app
```

Quiz question schema (embedded in `quizQuestions` array):

```
{
  "questionId": String,
  "question": Map<String, String>,     // localized question text
  "options": List<Map<String, String>>, // 4 options, each localized
  "correctOptionIndex": int,            // 0–3
  "explanation": Map<String, String>    // localized explanation shown on wrong answer
}
```

### 2.2 `video_watches` collection

One document per worker-per-video-per-date. This is the primary data source for the AI risk engine and the recommendation engine.

```
video_watches/{watchId}
├── watchId: String            // auto-generated
├── userId: String             // references users/{uid}
├── videoId: String            // references safety_videos/{videoId}
├── watchedAt: Timestamp       // when the watch session started
├── completionPercent: int     // 0–100, updated continuously
├── isCompleted: bool          // true when completionPercent >= 90
├── quizAttempted: bool
├── quizPassed: bool
├── quizScore: int             // 0–3 (number of correct answers)
├── compliancePointsAwarded: int // 5 if quiz passed, 0 otherwise
└── mineId: String             // denormalized for supervisor queries
```

### 2.3 `users/{uid}` additions

Add these fields to the existing user document (established in Phase 2):

```
videosWatched7Days: int        // rolling 7-day count — updated by Cloud Function
totalVideosWatched: int        // lifetime count
lastVideoWatchedAt: Timestamp
compliancePoints: int          // running total of points from quizzes
videoOfDayVideoId: String      // set by recommendation logic each morning
videoOfDayDate: String         // "YYYY-MM-DD" — invalidate if date changes
```

---

## 3. Flutter Feature Structure

Inside the existing `lib/features/` directory, create:

```
lib/features/education/
├── data/
│   ├── education_repository.dart        // Firestore read/write for videos + watches
│   └── video_of_day_service.dart        // selection logic for Video of the Day
├── domain/
│   ├── safety_video.dart                // SafetyVideo model + fromFirestore()
│   ├── video_watch.dart                 // VideoWatch model + fromFirestore()
│   └── quiz_question.dart              // QuizQuestion model
├── presentation/
│   ├── screens/
│   │   ├── education_screen.dart        // root tab screen (Video of Day + Browse)
│   │   ├── video_player_screen.dart     // full-screen player + quiz
│   │   └── category_browse_screen.dart  // filtered list by category
│   └── widgets/
│       ├── video_of_day_card.dart
│       ├── video_list_tile.dart
│       ├── category_chip_row.dart
│       ├── continue_watching_section.dart
│       ├── quiz_overlay.dart
│       └── quiz_result_card.dart
└── providers/
    ├── education_providers.dart         // Riverpod providers
    └── video_player_provider.dart
```

---

## 4. Riverpod Providers

Define the following providers in `education_providers.dart`:

```dart
// Fetches the full video library for the current user's role
final videoLibraryProvider = StreamProvider.autoDispose<List<SafetyVideo>>(...);

// Returns the Video of the Day for the current user
final videoOfDayProvider = FutureProvider.autoDispose<SafetyVideo?>(...);

// Returns videos the user has started but not completed
final continueWatchingProvider = StreamProvider.autoDispose<List<VideoWatch>>(...);

// Filtered videos by category — takes category string as family param
final videosByCategoryProvider = StreamProvider.autoDispose.family<List<SafetyVideo>, String>(...);

// Watch state for a specific video — tracks completion percent
final videoWatchStateProvider = StateNotifierProvider.autoDispose.family<VideoWatchNotifier, VideoWatch?, String>(...);
```

---

## 5. Video of the Day Selection Logic

Implement `VideoOfDayService.getVideoForUser(String uid)` in `video_of_day_service.dart`. This runs client-side for Phase 5. It will be replaced by the FastAPI recommendation engine in Phase 6, but the interface must remain the same so the swap is seamless.

**Selection priority (evaluate in order, return on first match):**

1. If the user has filed a hazard report in the last 7 days, find videos whose `tags` array intersects with the report's `category`. Return the highest-priority match not watched in the last 7 days.

2. If the user's `riskLevel` is `"high"`, return a video from `category == "emergency"` or `category == "ppe"` not watched in the last 7 days.

3. If the behavior analysis (Phase 6) has stored a `recommendedCategory` on the user document, return a video from that category not watched in the last 7 days.

4. Rotating schedule fallback: cycle through categories in order `["ppe", "gas_ventilation", "roof_support", "emergency", "machinery"]` using `(dayOfYear % 5)` as the category index. Return the least-recently-watched video in that category.

5. If all videos in the selected category have been watched recently, fall back to any unwatched video.

**Caching:** Store the selected `videoId` and today's date in the user's Firestore document under `videoOfDayVideoId` and `videoOfDayDate`. On subsequent calls within the same calendar day, return the cached selection immediately without rerunning the logic.

---

## 6. Screen Specifications

### 6.1 Education Screen (`education_screen.dart`)

This is the root screen for the Education tab. It has two sections stacked vertically in a `CustomScrollView`.

**Section 1 — Video of the Day hero card**

Display a full-width card with:
- YouTube thumbnail image loaded from `thumbnailUrl`
- Localized video title (use `video.title[userLanguage] ?? video.title["en"]` throughout — apply this fallback pattern everywhere localized text is displayed)
- Source badge (DGMS / MSHA / HSE / WorkSafe / Custom) rendered as a small pill with source-specific color
- "Watch Now" button

Tapping anywhere on the card navigates to `VideoPlayerScreen` with the video object passed as a route extra.

**Section 2 — Continue Watching**

Show a horizontally scrolling row of `VideoListTile` widgets for videos with `completionPercent > 0` and `completionPercent < 90`. Show a thin linear progress indicator on each tile reflecting completion. If no in-progress videos exist, hide this section entirely (do not show an empty state).

**Section 3 — Browse by Category**

A `CategoryChipRow` with filter chips for: All, PPE, Gas & Ventilation, Roof Support, Emergency, Machinery. Default is All. Selecting a chip rebuilds the list below using `videosByCategoryProvider(selectedCategory)`.

Below the chips, a `ListView` of `VideoListTile` widgets. Exclude videos that match the Video of the Day (they appear in the hero card above, not the list).

### 6.2 Video Player Screen (`video_player_screen.dart`)

Use the `youtube_player_flutter` package to embed the YouTube player. The player renders at 16:9 at the top of the screen. Below the player:

- Localized video title (large, bold)
- Source + category metadata row
- Localized description text

**Watch progress tracking:** The `youtube_player_flutter` package exposes a `YoutubePlayerController` with a `value.position` stream. On every position update, calculate `completionPercent = (position.inSeconds / durationSeconds * 100).clamp(0, 100).toInt()`. Debounce writes to Firestore to no more than once every 5 seconds. Use `VideoWatchNotifier` to manage this. On initial load, check Firestore for an existing `VideoWatch` document for this user+video+today and restore progress (seek to the saved position if `completionPercent < 90` and user has not yet completed the video).

**Quiz trigger:** When `completionPercent` crosses 90 for the first time (track with a boolean flag to avoid re-triggering), pause the video and display the `QuizOverlay`. Do not trigger the quiz if the video has already been completed today.

**Back navigation:** If the user exits before the quiz is triggered, save progress. If the user exits mid-quiz, do not award points but save watch progress.

### 6.3 Quiz Overlay (`quiz_overlay.dart`)

Display as a `showModalBottomSheet` with `isScrollControlled: true` so it covers most of the screen.

Structure:
- "Quick Check" heading with the video title
- Progress indicator showing question X of 3
- Question text (localized)
- 4 answer option buttons — visually styled as full-width outlined buttons
- "Submit" button (disabled until an option is selected)

On submit:
- If correct: button turns green, brief positive label shown, advance to next question
- If incorrect: button turns red, correct answer highlighted in green, localized explanation shown beneath. Still advance after 2 seconds.

After question 3, show `QuizResultCard`:
- If 2 or 3 correct: "Well done!" card with compliance points awarded (+5), update `users/{uid}.compliancePoints` in Firestore, set `quizPassed: true` on the `VideoWatch` document
- If 0 or 1 correct: "Try again next time" card with correct answers summarized, no points awarded
- "Continue" button dismisses overlay and resumes video from the saved position

### 6.4 Category Browse Screen (`category_browse_screen.dart`)

This screen is navigated to when the user taps a category chip on the Education Screen and the library is long enough to warrant a full screen (optional — acceptable to keep everything on the Education Screen using an in-place list rebuild if the UX is clean).

---

## 7. Firestore Write Operations

All Firestore writes for this feature must go through `EducationRepository`. Do not call Firestore directly from widgets or providers.

| Method | Trigger | Firestore operation |
|---|---|---|
| `initWatchSession(uid, videoId)` | Player screen opens | Create `video_watches` doc with `completionPercent: 0` |
| `updateWatchProgress(watchId, percent)` | Every 5s during playback | Update `completionPercent`, set `isCompleted: true` when percent >= 90 |
| `saveQuizResult(watchId, passed, score)` | Quiz dismissed | Update `quizAttempted`, `quizPassed`, `quizScore`, `compliancePointsAwarded` |
| `awardCompliancePoints(uid, points)` | Quiz passed | Increment `users/{uid}.compliancePoints` |
| `cacheVideoOfDay(uid, videoId, date)` | After selection | Update `users/{uid}.videoOfDayVideoId` and `videoOfDayDate` |

---

## 8. Cloud Function: `onVideoWatched`

Create a Firebase Cloud Function triggered by a Firestore `onWrite` event on `video_watches/{watchId}` when `isCompleted` changes to `true`.

The function updates `users/{uid}`:
- Increments `totalVideosWatched` by 1
- Updates `lastVideoWatchedAt` to current timestamp
- Recomputes `videosWatched7Days` by counting `video_watches` documents for this user where `watchedAt > now - 7 days` and `isCompleted == true`

This field is consumed directly by the Phase 6 risk prediction engine as a positive behavioral signal.

---

## 9. YouTube Integration Notes

All videos are stored as unlisted YouTube links. The app never streams video through Firebase Storage — YouTube is the CDN.

- `youtubeId` is the 11-character ID from a YouTube URL: `https://www.youtube.com/watch?v=XXXXXXXXXXX`
- Thumbnail URL pattern: `https://img.youtube.com/vi/{youtubeId}/hqdefault.jpg`
- Use `youtube_player_flutter: ^10.0.0` (or latest stable) in `pubspec.yaml`
- The player requires the phone to have the YouTube app installed OR falls back to WebView player — `YoutubePlayerController` handles this automatically
- For offline scenarios: YouTube's native caching handles partial caching. The app cannot force-cache YouTube videos. This is acceptable per the project spec — the offline requirement applies to checklists and hazard reports, not video playback.

---

## 10. Localization

All user-facing strings in this feature must be added to each of the six `.arb` localization files established in Phase 9 preparation. For Phase 5, stub the non-English translations with English fallback text — the full translations will be completed in Phase 9.

String keys to define:

```
education_tab_title
video_of_day_label
continue_watching_label
browse_by_category_label
watch_now_button
category_all
category_ppe
category_gas_ventilation
category_roof_support
category_emergency
category_machinery
quiz_heading
quiz_question_of_total       // "Question {current} of {total}"
quiz_submit_button
quiz_well_done_heading
quiz_points_awarded          // "+{points} compliance points"
quiz_try_again_heading
quiz_continue_button
source_dgms
source_msha
source_hse
source_worksafe
source_custom
```

When displaying localized video titles, descriptions, and quiz content from Firestore, use the helper:

```dart
String localize(Map<String, String> map, String langCode) =>
    map[langCode] ?? map['en'] ?? map.values.first;
```

---

## 11. Navigation Integration

In GoRouter (configured in Phase 1), add the following routes under the authenticated shell route:

```dart
GoRoute(
  path: '/education',
  builder: (_, __) => const EducationScreen(),
  routes: [
    GoRoute(
      path: 'player',
      builder: (context, state) => VideoPlayerScreen(
        video: state.extra as SafetyVideo,
      ),
    ),
    GoRoute(
      path: 'category/:categoryId',
      builder: (context, state) => CategoryBrowseScreen(
        category: state.pathParameters['categoryId']!,
      ),
    ),
  ],
),
```

Add the Education tab to the `BottomNavigationBar` in the main shell scaffold (4th position, icon: `Icons.play_circle_outline`, label: localized "Education").

---

## 12. Seed Data Script

Create `scripts/seed_safety_videos.py`. This script reads from a local `seed_videos.json` file and writes to the `safety_videos` Firestore collection using the Firebase Admin SDK.

Minimum seed dataset required for testing: at least 2 videos per category (10 total). For each video:
- Find a real unlisted or Creative Commons YouTube video ID from DGMS, MSHA, or HSE channels, OR use publicly available mining safety content
- Provide English title and description (other language translations are stubs for now)
- Write at least 3 quiz questions per video

Run instructions:

```bash
pip install firebase-admin
python scripts/seed_safety_videos.py --project YOUR_FIREBASE_PROJECT_ID --creds path/to/service-account.json
```

---

## 13. pubspec.yaml Dependencies

Add to `pubspec.yaml` if not already present:

```yaml
dependencies:
  youtube_player_flutter: ^10.0.0   # YouTube embed player
  cached_network_image: ^3.3.1      # Thumbnail caching
  flutter_riverpod: ^2.4.0          # Already from Phase 1
  cloud_firestore: ^4.13.0          # Already from Phase 1
  firebase_auth: ^4.15.0            # Already from Phase 2
```

---

## 14. Testing Checklist

Before marking this phase complete, verify all of the following manually and with unit tests:

**Unit tests** (in `test/features/education/`):

- `VideoOfDayService` selects a hazard-category-matched video when recent reports exist
- `VideoOfDayService` falls back to rotating schedule when no behavioral signals exist
- `VideoOfDayService` returns cached video when `videoOfDayDate` matches today
- Localize helper returns English fallback when requested language is missing
- `VideoWatchNotifier` does not trigger quiz twice for the same video on the same day
- Quiz result correctly awards 5 points for 2+ correct answers and 0 for 1 or fewer

**Manual smoke tests:**

- [ ] Education tab loads without errors for a freshly seeded user
- [ ] Video of the Day card shows correct thumbnail and localized title
- [ ] Tapping "Watch Now" opens the player and begins playback
- [ ] Progress persists when user exits and re-enters the player screen
- [ ] Quiz overlay appears at 90% completion and not before
- [ ] Passing quiz increments `compliancePoints` on user document in Firestore
- [ ] Failing quiz shows correct answers and awards no points
- [ ] Category chip filtering works correctly
- [ ] Continue Watching section shows only partially-watched videos
- [ ] Switching app language (via profile screen) updates all localized strings on the Education tab without restarting the app
- [ ] `video_watches` documents are created correctly and `isCompleted` is set when threshold is crossed
- [ ] Cloud Function `onVideoWatched` fires and increments `videosWatched7Days` correctly

---

## 15. Phase 6 Interface Contract

The following fields and collection structures must be in place and correctly populated by the end of Phase 5, as Phase 6 depends on them:

| Data point | Location | Used by Phase 6 for |
|---|---|---|
| `videosWatched7Days` | `users/{uid}` | Risk prediction feature vector (positive signal, weight: Low) |
| `lastVideoWatchedAt` | `users/{uid}` | Inactivity spike detection |
| `isCompleted: true` records | `video_watches/` | Recommendation engine — exclude already-watched videos |
| `quizPassed` | `video_watches/` | Behavioral engagement signal |
| `category` of completed watches | `video_watches/` via `videoId` | Recommendation engine content matching |

Do not rename or restructure these fields without updating this contract and notifying the Phase 6 developer.

---

## 16. Definition of Done

Phase 5 is complete when:

1. A worker can open the Education tab and see a personalized Video of the Day based on their role and recent hazard report history.
2. The worker can tap the video, watch it in the embedded YouTube player, and have their progress saved to Firestore.
3. The quiz overlay appears at 90% completion, awards compliance points on pass, and shows correct answers on fail.
4. The worker can browse the full video library by category.
5. The Continue Watching section correctly surfaces in-progress videos.
6. All strings render in the worker's preferred language (English for now, with stubs for other languages).
7. `video_watches` documents are written correctly for every watch session.
8. The Cloud Function `onVideoWatched` correctly updates `videosWatched7Days` on the user document.
9. All unit tests pass.
10. All manual smoke tests above are checked off.

---

*MiningGuard · Phase 5 Execution Prompt · v1.0*  
*Builds on: Phase 1, Phase 2, Phase 3, Phase 4*  
*Feeds into: Phase 6 (AI risk engine), Phase 7 (worker dashboard — Video of Day card), Phase 9 (localization completion)*
