# ⛏️ MiningGuard — Intelligent Mining Safety Companion
### AI-Powered Mobile Application for Mine Worker Safety

> Aligned with DGMS (India) · MSHA (USA) · HSE (UK) · WorkSafe (Australia)  
> Built for India's Digital India & Make in India missions

---

## 📖 Project Overview

Mining is one of the most hazardous occupations globally. Accidents arising from non-compliance with safety protocols, inadequate training, roof and side-fall incidents, machinery entanglement, and poor hazard communication continue to claim lives — despite comprehensive regulations by the **Directorate General of Mines Safety (DGMS)** under the Mines Act, 1952.

**MiningGuard** is an AI-powered mobile safety companion that promotes a safety-first culture among mine workers through personalized, role-based guidance and continuous behavioral reinforcement. It leverages workers' existing familiarity with short-form video platforms to embed Health, Safety & Environment (HSE) awareness as a natural part of the daily routine.

---

## 🎯 Goals

- Reduce accident frequency in mines through proactive AI-driven risk detection
- Strengthen compliance with DGMS safety guidelines
- Empower workers to report hazards quickly in their native language
- Provide supervisors with real-time visibility into worker risk levels
- Build a scalable, affordable safety platform for Indian mines

---

## 👥 User Roles

| Role | Access Level | Primary Use |
|------|-------------|-------------|
| **Worker / Miner** | Standard | Checklists, hazard reports, safety videos, personal risk dashboard |
| **Supervisor** | Elevated | All worker data, pending reports, mine-wide risk overview, alert management |
| **Admin** | Full | User management, content upload, analytics, system configuration |

---

## ✨ Features

---

### 1. 🔐 Authentication & User Management

- Email/password login and Phone OTP login (for workers without email)
- Role-based access control — Worker, Supervisor, Admin
- Secure Firebase Authentication with session handling
- User profile with mine ID, shift, department, and language preference
- Risk score and compliance rate stored per user
- FCM token management for push notifications

---

### 2. 📊 User Profile & Risk Tracking

Each worker has a live profile tracking:

- **Risk Score** (0–100, updated by AI after every event)
- **Risk Level** — Low 🟢 / Medium 🟡 / High 🔴
- **Compliance Rate** — percentage of checklists completed
- **Total Hazard Reports** submitted
- **Activity History** — checklist completions, videos watched, reports filed
- **Consecutive Missed Days** — feeds into risk calculation
- Language preference for localized content delivery

---

### 3. ✅ Daily Safety Checklist System

- Automatically generated every shift based on the worker's role
- **Worker checklist covers:**
  - PPE verification (helmet, boots, vest, gloves, cap lamp, SCSR)
  - Machinery pre-inspection
  - Environmental checks (gas readings, roof condition, ventilation)
  - Emergency preparedness (exit locations, communication devices)
- **Supervisor checklist adds:**
  - Worker attendance and sign-in
  - Toolbox talk confirmation
  - DGMS permit-to-work review
  - High-risk work permit verification
- Mark items complete in real time
- **Compliance scoring** — mandatory items weighted at 70%, optional at 30%
- Missed checklists reduce risk score and trigger supervisor notifications
- Reminder push notification if checklist not started by shift time

---

### 4. ⚠️ Hazard Reporting System

The core worker-facing feature. Supports three input modes:

#### 📷 Photo / Video Upload
- Select or capture images and videos directly
- Files uploaded to Firebase Storage with size validation
- AI image analysis runs automatically on uploaded photos

#### 🎤 Voice Input
- Speech-to-text in 6 regional languages (English, Hindi, Bengali, Telugu, Marathi, Odia)
- Hands-free operation — critical for workers wearing gloves
- Voice note saved as audio file alongside text transcription

#### ✏️ Text Description
- Freeform text entry with language support
- Category selection: Roof Fall · Gas Leak · Fire · Machinery · Electrical · Other
- Severity tagging: Low · Medium · High · Critical
- Auto-location tagging with mine section/zone

#### Report Lifecycle
```
Submitted → Acknowledged → In Progress → Resolved
```
- AI suggests severity based on image analysis
- Supervisor receives instant FCM notification on new report
- Worker receives status update notifications
- All reports timestamped and stored permanently

---

### 5. 🧠 AI-Powered Features

The core differentiator of MiningGuard. All AI runs on a self-hosted FastAPI backend — no paid APIs required.

---

#### 5.1 ⚡ Risk Prediction Engine

**Technology:** Scikit-learn Gradient Boosting Classifier

Predicts worker risk level as **Low / Medium / High** using 8 behavioral features:

| Feature | Weight |
|---------|--------|
| Missed checklists (last 7 days) | High |
| Consecutive missed days | High |
| Compliance rate (overall) | High |
| High-severity reports filed | Medium |
| Total hazard reports (7 days) | Medium |
| Safety videos watched (7 days) | Low (positive signal) |
| Role (worker/supervisor) | Context |
| Shift type (morning/afternoon/night) | Context |

Risk scores update automatically after every checklist submission, hazard report, and video watch event.

---

#### 5.2 🔍 Behavior Analysis Engine

Detects unsafe patterns over time that individual events would not reveal:

- **Weekly skip pattern** — consistently missing checklists on specific days
- **Night shift compliance gap** — significant drop in compliance on night shifts vs day shifts
- **Escalating severity** — recent reports showing increasingly serious hazards
- **Repeated PPE violations** — same safety item missed across multiple checklists
- **Inactivity spike** — sudden drop in app engagement after regular use

When patterns are detected, the system generates structured alerts sent to both the worker and their supervisor.

---

#### 5.3 🖼️ Image-Based Hazard Detection

**Technology:** TensorFlow MobileNetV2 (fine-tuned, runs on CPU)

Automatically analyzes photos uploaded with hazard reports:

| Detection Class | Action Triggered |
|----------------|-----------------|
| Missing helmet | High severity — immediate PPE alert |
| Missing hi-vis vest | Medium severity — PPE notice |
| Unsafe environment | Critical — stop work order recommended |
| Machinery hazard | High — isolate equipment alert |
| Safe | No action required |

Returns confidence score, suggested severity override, and recommended corrective action — all shown to the worker before they submit the report.

---

#### 5.4 🎯 Personalized Recommendation Engine

Recommends safety videos and tips based on:

1. Worker's recent hazard report categories
2. Checklist items most frequently missed
3. Current risk level (high-risk workers get emergency/PPE content)
4. Role and shift type
5. Regional best practices (DGMS/MSHA/HSE sourced content)

Falls back to scheduled category rotation when no behavioral signals are present.

---

#### 5.5 🚨 Early Warning Alert System

Proactive alerts generated before an incident occurs:

- Risk level crosses from Medium → High
- 3 or more checklists missed in a 7-day window
- Behavior pattern detected (e.g., night-shift compliance gap)
- Multiple high-severity reports from same area of the mine
- Worker not active in app for unusual duration during shift

Alerts are sent via FCM push notification and stored in the in-app alert feed. Critical alerts use full-screen intent on Android.

---

### 6. 🎥 Safety Education Module

- **Video of the Day** — one personalized safety video shown prominently each day
- Category-based browsing: PPE · Gas Safety · Roof Support · Emergency Drills · Machinery
- Video sources: DGMS advisories, MSHA USA, HSE UK, WorkSafe Australia, custom mine content
- Progress tracking — videos marked as watched, feeds into AI risk scoring
- Short quiz popup at 90% watch completion (gamified compliance points)
- Continue Watching section for partially viewed videos
- Videos hosted as unlisted YouTube links — zero storage cost

---

### 7. 📈 Dashboards

#### Worker Dashboard
- Personal risk level badge with score bar
- Today's checklist progress with quick-continue button
- Video of the Day card with autoplay preview
- Recent hazard reports with status
- Active alerts feed
- Weekly compliance trend mini-chart

#### Supervisor Dashboard
- Mine-wide worker count by risk level (Low / Medium / High)
- Risk distribution pie chart
- Filterable worker list: All · High Risk · Pending Reports
- Compliance trend line chart (last 30 days)
- Pending hazard reports queue with severity badges
- Quick actions: Send alert to all, export compliance report

#### Admin Panel
- User management: add, deactivate, bulk import via CSV
- Safety video upload and content management
- Checklist template editor
- Mine-wide incident analytics (monthly/quarterly)
- DGMS compliance report generator
- System health and API status monitoring

---

### 8. 🔔 Notification System

| Notification | Recipient | Priority |
|-------------|-----------|----------|
| Checklist reminder (shift start) | Worker | Medium |
| Risk level changed to HIGH | Worker + Supervisor | High |
| New hazard report submitted | Supervisor | High |
| Critical hazard in mine area | All workers | Critical |
| Video of the Day available | Worker | Low |
| Report status updated | Reporter | Medium |
| Daily compliance summary (7 PM) | Supervisor | Low |

- Critical alerts use Android full-screen intent and loud sound channel
- Notifications respect worker's language preference

---

### 9. 🌐 Multi-Language Support

Full localization for 6 languages spoken in Indian mining regions:

| Language | Code | States |
|----------|------|--------|
| English | en | All |
| Hindi | hi | Jharkhand, MP, UP, Chhattisgarh |
| Bengali | bn | West Bengal |
| Telugu | te | Andhra Pradesh, Telangana |
| Marathi | mr | Maharashtra |
| Odia | or | Odisha |

- UI text, notifications, alerts, and checklist items all localized
- Voice input supports all 6 languages via device speech-to-text
- Language selectable per user profile, changeable at any time

---

### 10. 📡 Offline Support

- Checklists cached locally using Hive (NoSQL on-device storage)
- Hazard reports queued locally when offline and auto-synced when connection restored
- Safety videos available via YouTube cache (native player caching)
- Connectivity monitor runs in background — triggers sync automatically on reconnect
- Worker can complete their shift checklist with zero connectivity

---

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
│                                                                   │
│  ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌───────┐ ┌────────┐  │
│  │   Auth    │ │Checklist │ │  Hazard  │ │  Edu  │ │Dashbrd │  │
│  │  Screen   │ │  Screen  │ │  Report  │ │Module │ │        │  │
│  └───────────┘ └──────────┘ └──────────┘ └───────┘ └────────┘  │
│                                                                   │
│  State Management: Riverpod  │  Routing: GoRouter                │
│  Local Storage: Hive         │  HTTP: Dio                        │
└──────────────┬──────────────────────────┬────────────────────────┘
               │                          │
   ┌───────────▼────────────┐   ┌─────────▼──────────────────┐
   │     Firebase Suite      │   │    FastAPI AI Backend       │
   │                         │   │    (Hosted on Render/       │
   │  ┌─────────────────┐   │   │     Cloud Run — Free)       │
   │  │ Firebase Auth   │   │   │                             │
   │  └─────────────────┘   │   │  ┌──────────────────────┐  │
   │                         │   │  │  /risk/predict        │  │
   │  ┌─────────────────┐   │   │  │  Gradient Boosting    │  │
   │  │ Cloud Firestore │◄──┼───┼──│  Classifier           │  │
   │  │  (Real-time DB) │   │   │  └──────────────────────┘  │
   │  └─────────────────┘   │   │                             │
   │                         │   │  ┌──────────────────────┐  │
   │  ┌─────────────────┐   │   │  │  /image/detect        │  │
   │  │Firebase Storage │   │   │  │  MobileNetV2 (TF)     │  │
   │  │ (Images/Voice)  │   │   │  └──────────────────────┘  │
   │  └─────────────────┘   │   │                             │
   │                         │   │  ┌──────────────────────┐  │
   │  ┌─────────────────┐   │   │  │  /behavior/analyze    │  │
   │  │      FCM        │   │   │  │  Pattern Detection    │  │
   │  │ (Notifications) │   │   │  └──────────────────────┘  │
   │  └─────────────────┘   │   │                             │
   └─────────────────────────┘   │  ┌──────────────────────┐  │
                                  │  │  /recommendations    │  │
                                  │  │  Content Engine      │  │
                                  │  └──────────────────────┘  │
                                  └────────────────────────────┘
```

---

## 🔄 Application Workflows

---

### Workflow 1 — Worker Daily Shift Flow

```
Worker Opens App
        │
        ▼
┌───────────────┐
│  Login Check  │──── Not logged in ────► Login / OTP Screen
└───────┬───────┘
        │ Authenticated
        ▼
┌───────────────────────────────────────┐
│           Home Dashboard              │
│  Shows: Risk Level · Checklist · Alert│
└───────┬───────────────────────────────┘
        │
        ▼
┌──────────────────┐
│  Open Checklist  │◄──── Push reminder if not opened by 9 AM
└────────┬─────────┘
         │
         ▼
  Complete Items
  (tap to check off)
         │
    All done?
    ┌────┴────┐
   Yes        No
    │          │
    ▼          ▼
Submit     Partial save
Checklist  (resume later)
    │
    ▼
Firebase Firestore updated
    │
    ▼
FastAPI called → Risk Score Recalculated
    │
    ▼
Risk Level Changed?
    ┌────┴────┐
   Yes        No
    │          │
    ▼          ▼
FCM Alert  No action
sent to
Supervisor
```

---

### Workflow 2 — Hazard Report Submission Flow

```
Worker Spots Hazard
        │
        ▼
  Opens Report Screen
        │
   Choose Input Mode
  ┌─────┼──────┐
  │     │      │
Photo  Voice  Text
  │     │      │
  └─────┴──────┘
        │
        ▼
  Select Category
  (Roof / Gas / Fire
   Machinery / Other)
        │
        ▼
  ┌────────────────────┐
  │  Image Uploaded?   │
  └──────┬─────────────┘
         │ Yes
         ▼
  FastAPI /image/detect
  ← Returns hazard type
    + suggested severity
         │
         ▼
  Worker reviews AI
  suggestion, confirms
  or overrides severity
         │
         ▼
  Submit Report
         │
    ┌────┴──────────────────────┐
    │                           │
    ▼                           ▼
Firestore saved          Firebase Storage
(report metadata)        (media files)
    │
    ▼
FCM → Supervisor
notified instantly
    │
    ▼
Supervisor Reviews
    │
    ├── Acknowledge → Status: "In Progress"
    │
    └── Resolve → Status: "Resolved"
                       │
                       ▼
                 FCM → Worker
                 notified of
                 resolution
```

---

### Workflow 3 — AI Risk Engine Flow

```
Triggering Event
(Checklist submitted / Hazard report filed / Video watched)
        │
        ▼
Cloud Function (or direct Flutter call)
        │
        ▼
Fetch user's last 7-day behavioral data from Firestore:
  - Missed checklists count
  - Compliance rate
  - High-severity report count
  - Consecutive missed days
  - Videos watched
  - Shift type + role
        │
        ▼
POST /api/v1/risk/predict
  ┌─────────────────────────┐
  │  GradientBoosting Model │
  │  8 input features       │
  │  Output: Low/Med/High   │
  └──────────┬──────────────┘
             │
             ▼
      Risk Score (0–100)
      + Contributing Factors
             │
             ▼
  Update Firestore user document:
  { riskLevel, riskScore, riskUpdatedAt }
             │
     Risk = HIGH?
     ┌───────┴────────┐
    Yes               No
     │                 │
     ▼                 ▼
FCM Alert         No alert sent
to Worker
+ Supervisor
     │
     ▼
In-app alert
stored in
/alerts collection
```

---

### Workflow 4 — Behavior Analysis Flow

```
Scheduled trigger (daily) OR after 3+ consecutive missed checklists
        │
        ▼
POST /api/v1/behavior/analyze  { uid }
        │
        ▼
Fetch 30 days of:
  - Checklist records (by day of week, by shift)
  - Hazard report severity history
  - App engagement data
        │
        ▼
  Run Pattern Detection:
  ┌────────────────────────────────────┐
  │ • Weekly skip pattern?             │
  │ • Night shift compliance gap?      │
  │ • Escalating report severity?      │
  │ • Repeated same PPE item missed?   │
  │ • Sudden activity drop?            │
  └─────────────────┬──────────────────┘
                    │
              Patterns found?
          ┌─────────┴──────────┐
         Yes                   No
          │                    │
          ▼                    ▼
  Generate alerts         Return clean
  for HIGH patterns       behavior report
          │
          ▼
  FCM → Supervisor
  "Worker showing repeated
   night-shift non-compliance"
          │
          ▼
  Supervisor can:
  ├── Schedule a 1:1 safety briefing
  ├── Assign targeted training video
  └── Flag for DGMS compliance review
```

---

### Workflow 5 — Video of the Day Selection Flow

```
Worker opens Education tab
        │
        ▼
VideoOfDayService.getVideoOfDay(userId)
        │
        ▼
  Check recent hazard reports (last 7 days)
        │
  Has reports?
  ┌──────┴──────┐
 Yes             No
  │               │
  ▼               ▼
Match video   Check risk level
category to     │
report type   HIGH risk?
  │           ┌────┴──────┐
  │          Yes           No
  │           │             │
  │           ▼             ▼
  │       Emergency     AI Recommendation
  │       / PPE video   from FastAPI based
  │                     on behavior history
  │
  └──────────────────┐
                     ▼
             Return video
             Show as hero
             banner on
             Education screen
                     │
             Worker watches
                     │
             > 90% watched?
                  │
                  ▼
           Quiz popup (3 Qs)
                  │
             Pass quiz?
             ┌────┴──────┐
            Yes           No
             │             │
             ▼             ▼
       +5 compliance   Show correct
       points awarded  answers + retry
             │
             ▼
       Firestore updated
       (videos_watched count)
             │
             ▼
       Next AI risk
       calculation uses
       this as positive signal
```

---

## 🗄️ Data Architecture

### Firestore Collections

```
firestore/
│
├── users/              One document per registered user
│   └── {uid}
│       ├── Profile info (name, role, mine, language, shift)
│       └── AI outputs (riskScore, riskLevel, complianceRate)
│
├── mines/              Mine metadata
│   └── {mineId}
│       ├── name, location, type (underground/opencast)
│       └── supervisorIds[]
│
├── checklists/         One per worker per shift
│   └── {checklistId}
│       ├── items[] with completion status
│       ├── completionRate, status
│       └── submittedAt
│
├── hazard_reports/     All submitted hazard reports
│   └── {reportId}
│       ├── description, category, severity
│       ├── mediaUrls[], voiceNoteUrl
│       ├── aiAnalysis { hazardDetected, confidence, severity }
│       └── status (pending → resolved)
│
├── safety_videos/      Video content library
│   └── {videoId}
│       ├── title (multilingual), category, source
│       ├── youtubeId or videoUrl
│       └── targetRoles[], tags[]
│
└── alerts/             AI-generated and system alerts
    └── {alertId}
        ├── userId, type, message
        ├── isRead, severity
        └── createdAt
```

### Firebase Storage Buckets

```
storage/
├── reports/
│   └── {mineId}/
│       └── {reportId}/
│           ├── image_0.jpg
│           ├── video_0.mp4
│           └── voice_note.aac
│
└── thumbnails/
    └── {videoId}.jpg
```

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter + Dart | Cross-platform Android & iOS |
| **State Management** | Riverpod | Reactive state, dependency injection |
| **Navigation** | GoRouter | Role-based routing |
| **Database** | Cloud Firestore | Real-time NoSQL database |
| **Authentication** | Firebase Auth | Email, Phone OTP login |
| **File Storage** | Firebase Storage | Images, videos, voice notes |
| **Notifications** | Firebase FCM | Push notifications |
| **Local Storage** | Hive | Offline checklist/report caching |
| **AI Backend** | FastAPI (Python) | REST API for all ML features |
| **Risk Prediction** | Scikit-learn | Gradient Boosting Classifier |
| **Image Detection** | TensorFlow / MobileNetV2 | PPE and hazard detection |
| **Speech-to-Text** | Device API (speech_to_text) | Voice input, 6 languages |
| **Video Hosting** | YouTube (unlisted) | Zero-cost safety video delivery |
| **Backend Hosting** | Render.com / Cloud Run | Free tier AI backend hosting |

---

## 🔐 Security Model

- All API calls to FastAPI require a valid **Firebase ID token** — verified server-side
- Firestore security rules enforce:
  - Workers can only read/write their own data
  - Supervisors can read all workers in their mine
  - Admins have full access
- Firebase Storage rules enforce:
  - 100 MB per upload max
  - Only image, video, and audio MIME types accepted
  - No public write access — authenticated users only
- Sensitive data (risk scores, incident records) never exposed client-side without role verification

---

## 🌍 Compliance Alignment

| Standard | Organization | Alignment |
|----------|-------------|-----------|
| Mines Act, 1952 | DGMS India | Checklist categories, reporting formats |
| Coal Mines Regulation 2017 | DGMS India | PPE requirements, gas monitoring |
| 30 CFR Part 50 | MSHA USA | Incident reporting workflow |
| HSG65 Framework | HSE UK | Risk management approach |
| Work Health & Safety Act | WorkSafe Australia | Behavior-based safety model |

---

## 📱 App Screen Map

```
App
├── Splash Screen
├── Auth
│   ├── Login Screen
│   ├── Signup Screen
│   └── Language Selection (first login)
│
└── Main App (bottom nav)
    ├── 🏠 Home Dashboard
    │   ├── Risk Level Card
    │   ├── Checklist Progress Card
    │   ├── Video of the Day Card
    │   └── Active Alerts
    │
    ├── ✅ Checklist
    │   ├── Today's Checklist
    │   └── History / Missed
    │
    ├── ⚠️ Report Hazard
    │   ├── Choose Input (Photo/Voice/Text)
    │   ├── AI Analysis Preview
    │   └── My Reports (with status)
    │
    ├── 🎥 Education
    │   ├── Video of the Day
    │   ├── Browse by Category
    │   └── Continue Watching
    │
    └── 👤 Profile
        ├── Personal Info
        ├── Risk History
        ├── Language Setting
        └── Notification Preferences

Supervisor Additional Screens:
    ├── 📊 Mine Dashboard
    ├── 👷 Workers List (with risk filter)
    └── 📋 Pending Reports Queue

Admin Additional Screens:
    ├── 🛠️ User Management
    ├── 📹 Content Upload
    └── 📈 Analytics & Reports
```

---

## 🚀 Deployment

```
Development     → Local Flutter + Firebase Emulator + Render (free)
Staging         → Firebase project (staging) + Render.com free tier
Production      → Firebase (Spark/Blaze) + Google Cloud Run (free tier)
```

**Estimated cost at launch: $0/month**  
Free tiers cover Firebase Auth, Firestore (1 GB), Storage (5 GB), FCM (unlimited), Cloud Run (2M requests/month), and Render.com (750 hrs/month).

---

*MiningGuard — Building a Safety-First Culture, One Shift at a Time ⛏️🛡️*  
*Version 1.0 | Stack: Flutter · Firebase · FastAPI · TensorFlow · Scikit-learn*
