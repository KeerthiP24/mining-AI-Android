# MiningGuard — Architecture Overview

## System Architecture

MiningGuard follows a three-tier architecture:

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

## Mobile App Architecture

### State Management — Riverpod

All application state flows through Riverpod providers:

- **Firebase Providers** (`shared/providers/firebase_providers.dart`): Single source of truth for Firebase instances
- **Auth State**: Stream-based authentication state via `authStateChangesProvider`
- **Feature Providers**: Each feature module has its own providers directory

### Navigation — GoRouter

Central route configuration in `core/router/app_router.dart`:
- Route constants in `AppRoutes` class prevent hardcoded strings
- Role-based routing (Worker, Supervisor, Admin)
- Placeholder screens auto-generated for unimplemented routes

### Data Layer

- **Models** (`shared/models/`): Dart classes with Firestore serialization
- **Services**: Feature-specific Firebase and API interactions
- **Offline Storage**: Hive boxes for checklist caching and report queuing

## Backend Architecture

### FastAPI Application Structure

```
backend/app/
├── main.py          → Application entry point, CORS, lifespan
├── config.py        → Environment-based settings
├── api/
│   ├── deps.py      → Shared dependencies (auth)
│   └── v1/          → Versioned API routes
├── ml/              → ML model implementations
├── schemas/         → Pydantic request/response models
└── core/            → Firebase Admin, security, logging
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness probe |
| POST | `/api/v1/risk/predict` | Risk level prediction |
| POST | `/api/v1/behavior/analyze` | Behavior pattern detection |
| POST | `/api/v1/image/detect` | Image hazard detection |
| POST | `/api/v1/recommendations/` | Personalized recommendations |

### Security

- All AI endpoints require Firebase ID token in Authorization header
- Token verification handled by `core/security.py`
- Dependency injection via `api/deps.py`

## Data Architecture

### Firestore Collections

| Collection | Purpose | Key Fields |
|-----------|---------|------------|
| `users` | User profiles & risk data | uid, role, riskScore, complianceRate |
| `mines` | Mine metadata | name, location, supervisorIds |
| `checklists` | Daily safety checklists | uid, date, items[], complianceScore |
| `hazard_reports` | Submitted hazard reports | reporterId, category, severity, status |
| `safety_videos` | Video content library | titleEn, category, youtubeId |
| `alerts` | AI-generated alerts | userId, type, severity, isRead |

## Phase Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Project Foundation & Setup | ✅ Complete |
| 2 | Authentication & User Management | 🔲 Pending |
| 3 | Daily Safety Checklist | 🔲 Pending |
| 4 | Hazard Reporting System | 🔲 Pending |
| 5 | Safety Education Module | 🔲 Pending |
| 6 | AI Backend & Machine Learning | 🔲 Pending |
| 7 | Dashboards & Analytics | 🔲 Pending |
| 8 | Notifications & Real-Time Sync | 🔲 Pending |
| 9 | Multi-Language, Offline & Security | 🔲 Pending |
| 10 | Testing, Deployment & Launch | 🔲 Pending |
