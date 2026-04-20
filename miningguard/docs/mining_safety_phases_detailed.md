# ⛏️ MiningGuard — Complete Project Implementation Plan
### Intelligent Mining Safety Companion · Phase-by-Phase Development Guide

> This document is a detailed, non-technical explanation of every phase of the MiningGuard project —  
> what is being built, why it matters, how it works, and what the expected outcome is at each stage.

---

## 📌 How to Read This Document

This plan is organized into **10 phases**, each building on the previous one. Every phase contains:

- **What it is** — a plain-language explanation of the work
- **Why it matters** — the reasoning and importance
- **What gets built** — specific components and screens
- **How it works** — the logic and decisions behind each feature
- **Expected outcome** — what should be working by the end of the phase

The total estimated timeline is **12 weeks** for a single developer, or **6–8 weeks** for a small team of two.

---

## 🗓️ Timeline at a Glance

| Phase | Name | Duration |
|-------|------|----------|
| Phase 1 | Project Foundation & Setup | Week 1 |
| Phase 2 | Authentication & User System | Week 2 |
| Phase 3 | Daily Safety Checklist | Week 3 |
| Phase 4 | Hazard Reporting System | Week 4–5 |
| Phase 5 | Safety Education Module | Week 5–6 |
| Phase 6 | AI Backend & Machine Learning | Week 6–8 |
| Phase 7 | Dashboards & Analytics | Week 8–9 |
| Phase 8 | Notifications & Real-Time Sync | Week 9–10 |
| Phase 9 | Multi-Language, Offline & Security | Week 10–11 |
| Phase 10 | Testing, Deployment & Launch | Week 11–12 |

---

---

# Phase 1 — Project Foundation & Setup

**Duration:** Week 1  
**Type:** Infrastructure & Architecture

---

## What This Phase Is About

Before writing a single feature, the entire foundation of the project needs to be established correctly. This phase is about making decisions that will affect every other phase — how the app is structured, where data lives, how the AI backend is organized, and what tools and services will be used throughout the project.

Getting this phase right prevents costly restructuring later. A poorly planned foundation leads to spaghetti code, security vulnerabilities, and features that are hard to extend.

---

## Why This Phase Matters

Think of this phase like the blueprint and groundwork before constructing a building. You would not start laying bricks without first knowing where the walls go, how many floors there are, and where the electrical lines run. Similarly, MiningGuard cannot be built effectively without first deciding how the Flutter app communicates with Firebase, how the AI backend is structured, and how different screens will navigate to each other.

This phase also establishes the **development environment** — every developer on the project (current or future) should be able to set up the project on a new machine and have it running within minutes. That requires clear dependency management, configuration files, and documentation.

---

## What Gets Built in This Phase

### Flutter Application Skeleton

The Flutter project is initialized with a well-thought-out folder structure that separates concerns clearly. The app is divided into **features** (auth, checklist, hazard reporting, education, dashboard), **shared components** (reusable widgets, data models, utility functions), and **core services** (routing, networking, error handling).

This separation means that when work begins on the Hazard Reporting feature in Phase 4, the developer working on it does not need to understand the entire codebase — only their own feature folder and the shared components it uses.

### Firebase Project Configuration

A Firebase project is created and configured with all the services the app will need: Authentication for user login, Firestore as the main database, Storage for images and voice files, and Cloud Messaging for push notifications. The project is configured with two environments — a **development** environment for testing and a **production** environment for the real app — so that testing never contaminates real user data.

### FastAPI Backend Skeleton

The AI backend is a Python application built with FastAPI. In this phase, the project structure is set up with clearly defined folders for API routes, machine learning models, and data schemas. The backend is structured so that each AI feature (risk prediction, image detection, behavior analysis, recommendations) lives in its own isolated module. This makes it easy to work on one AI feature without breaking others.

### State Management Architecture

The app uses **Riverpod** as its state management solution. This is a decision made in Phase 1 that affects how every screen in the app works. Riverpod is chosen because it handles asynchronous data (like fetching a user's risk score from Firestore) cleanly and because it makes testing much easier. In this phase, the foundational Riverpod providers are set up — the building blocks that all screens will use to read and update data.

### Navigation System

The app's navigation is configured using **GoRouter**. This determines how screens transition between each other, how the app handles the back button, and — critically — how the app redirects users based on their login state and role. A worker who opens the app while logged in should go directly to the Home Dashboard. A user who is not logged in should be sent to the Login screen. A supervisor tapping a deep-link notification should land directly on the relevant report. All of this logic is configured in Phase 1.

### Automated Build Pipeline

A basic CI/CD (Continuous Integration / Continuous Deployment) pipeline is set up using GitHub Actions. This means that every time code is pushed to the repository, the pipeline automatically runs all tests, checks for code quality issues, and confirms the app builds successfully. This prevents broken code from being accidentally merged and gives the team confidence when making changes.

---

## Expected Outcome

By the end of Phase 1, there is a working Flutter app that opens successfully on Android, shows a placeholder home screen, and connects to Firebase. The FastAPI backend runs locally. No user-facing features exist yet, but the entire foundation is in place for everything that follows. A new developer could join the project, clone the repository, follow the setup guide, and have a running development environment in under an hour.

---

---

# Phase 2 — Authentication & User Management

**Duration:** Week 2  
**Type:** Core Feature

---

## What This Phase Is About

This phase builds the complete user identity system for MiningGuard. Every person who uses the app — whether a frontline mine worker, a shift supervisor, or an administrator — needs to be identified, authenticated, and given access only to what their role permits. This phase covers everything from the login screen a worker sees the first time they open the app to the complex role-based rules that determine what data each person can see and change.

---

## Why This Phase Matters

Authentication is the security backbone of the entire application. Every AI feature, every hazard report, every compliance record is tied to a specific user identity. Without a robust authentication system, there is no way to know which worker submitted a report, no way to calculate a personalized risk score, and no way to prevent one worker from accessing another's private data.

Additionally, MiningGuard serves three very different types of users. A mine worker needs a simple, fast interface in their own language. A supervisor needs to see their entire team's data. An admin needs to manage the whole system. These different needs are controlled by **roles** — and roles must be established at the identity level, not just in the UI.

---

## What Gets Built in This Phase

### Login Screen

The login screen is designed to be extremely simple because many mine workers may have limited experience with smartphones or apps. It presents two login options: email and password, or phone number with an OTP (one-time password) SMS code. The phone OTP option is critical for workers who do not have email accounts, which is common in rural Indian mining communities.

The screen is also designed with large text, clear buttons, and minimal friction. A worker at the start of a shift, wearing gloves, possibly in poor lighting, needs to be able to log in within seconds.

### Signup & Onboarding Flow

New users are registered by their supervisor or admin (to ensure only real mine workers can create accounts) or can self-register with a mine ID code. During signup, the following information is collected:

- Full name
- Mine ID (links the worker to their specific mine)
- Role (worker, supervisor, or admin)
- Department and shift (morning, afternoon, or night)
- Preferred language — this is shown as a dedicated screen with the language names written in their own script (so Hindi speakers see "हिन्दी" not "Hindi")

This information is stored in the Firestore database and will be used by every other feature in the app — the checklist system uses the role to generate the right checklist, the AI uses the shift to contextualize risk, and the notification system uses the language to deliver alerts in the right language.

### Role-Based Navigation

After login, the app automatically directs the user to the right experience based on their role. A worker sees the Worker Home Dashboard with their personal risk score and checklist. A supervisor is taken to the Supervisor Dashboard showing mine-wide data. An admin sees the Admin Panel.

This is not just a UI decision — it is enforced at the data level. Even if a worker somehow navigates to a supervisor screen, the Firestore security rules (configured in Phase 9) will prevent them from reading data they are not allowed to see.

### User Profile Screen

Workers can view and update their profile — changing their preferred language, updating their shift schedule, and viewing their compliance history. They cannot change their role (only admins can do that) or their mine assignment.

### Session Management

Once logged in, the user's session is maintained securely. They do not need to log in again every time they open the app unless they explicitly log out or their session expires after a long period of inactivity. This is important for workers who open the app at the start of each shift without wanting to re-enter credentials every time.

---

## How It Works

Firebase Authentication handles the actual credential verification — it manages passwords securely (they are never stored in plain text), handles OTP delivery via SMS, and issues secure tokens that prove a user is who they say they are. Every time the Flutter app calls Firebase or the FastAPI backend, it includes this token. The backend verifies the token before processing any request.

The user's profile data (role, mine, shift, language, risk score) is stored in Firestore separately from the authentication record. This is because authentication only proves identity — it does not store app-specific data. By keeping them separate, it is easy to update a worker's shift or risk score without touching the authentication system at all.

---

## Expected Outcome

By the end of Phase 2, the app has a fully working authentication system. Workers can sign up, log in with email or phone OTP, set their language, and be directed to the appropriate screen for their role. Logging out and logging back in works correctly. The foundation for all user-specific features (checklists, risk scores, reports) is in place because every action in the app can now be tied to a verified user identity.

---

---

# Phase 3 — Daily Safety Checklist System

**Duration:** Week 3  
**Type:** Core Feature

---

## What This Phase Is About

The daily safety checklist is the most frequently used feature in MiningGuard. Every single worker, every single shift, is expected to complete their checklist before beginning work. This phase builds the entire system — from automatically generating the right checklist for each worker when their shift begins, to tracking completion in real time, to feeding compliance data into the AI risk engine.

---

## Why This Phase Matters

Research into mining accidents consistently shows that a large proportion of incidents occur because pre-shift safety checks were skipped or performed carelessly. The DGMS mandates that certain safety checks must be performed before work begins, but in practice, paper-based checklists are often completed in bulk at the end of a shift (or not at all) because there is no enforcement mechanism.

A digital checklist with timestamps solves this problem. Because each item is marked with the exact time it was completed, patterns of dishonest completion (marking everything at once at the end of the shift) become visible. Additionally, a digital checklist can be role-specific — there is no reason to show roof support checks to an office administrator, and showing irrelevant items reduces the usefulness of the checklist for workers who actually need it.

---

## What Gets Built in This Phase

### Automatic Checklist Generation

When a worker opens the app at the start of their shift, the system checks whether they already have a checklist for today. If not, one is created automatically. The system knows which checklist template to use based on the worker's role and mine type.

Workers do not browse a library of checklists — there is exactly one checklist waiting for them when they open the app. This simplicity is intentional: the fewer decisions a worker needs to make, the more likely they are to actually complete the checklist.

### Checklist Content by Role

**For mine workers,** the checklist covers four critical areas:

The first area is Personal Protective Equipment. Before entering the mine, a worker must confirm they are wearing a properly fitted hard hat, safety boots, high-visibility vest, and safety gloves. They must confirm their cap lamp is charged and functional, and that their self-contained self-rescuer (an emergency breathing device) is on their person. These are mandatory items — skipping any of them raises the worker's risk score immediately.

The second area is Machinery. Before operating any equipment, the worker confirms a pre-shift inspection has been completed, that all guards and covers are in place, and that there are no oil or hydraulic fluid leaks visible. This prevents the most common cause of machinery-related injuries: operating equipment that has a known fault.

The third area is the Working Environment. The worker confirms that their gas detector is reading within safe limits (methane below 1%), that the roof and side walls of their work area have been inspected for loose material (the leading cause of fatal underground accidents), that ventilation is adequate, and that walkways are clear.

The fourth area is Emergency Preparedness. The worker confirms they know where the nearest emergency exit is, that their communication device is working, and that they can locate the nearest first aid kit.

**For supervisors,** all of the above items apply, plus additional checks specific to their management role: confirming all workers in their section have signed in, that a toolbox safety briefing has been conducted, that all DGMS permits and high-risk work authorizations have been reviewed, and that the emergency muster point has been communicated to the crew.

### Real-Time Completion Tracking

As a worker taps each item on their checklist, the completion is saved to Firestore immediately — not when they submit the checklist at the end. This means that if a worker's phone dies halfway through their checklist, their progress is not lost. It also creates a timestamped record of exactly when each safety check was performed, which is valuable for DGMS compliance audits.

Items are organized by category with collapsible sections so workers can navigate quickly. Mandatory items are visually distinct from optional items. A progress bar at the top shows how much of the checklist has been completed.

### Compliance Scoring

When a checklist is submitted, a compliance score is calculated. Mandatory items carry 70% of the weight; optional items carry 30%. A worker who completes every mandatory item but misses optional ones still scores 70% for that shift — a passing score. A worker who misses multiple mandatory items scores significantly lower.

This score is stored on the worker's profile and fed into the AI risk prediction engine. A pattern of low compliance scores, especially on mandatory items, raises the worker's predicted risk level.

### Missed Checklist Handling

If a worker does not open or submit their checklist within a reasonable time after their shift begins, two things happen: a push notification is sent reminding them to complete it, and after a further delay, the checklist is automatically marked as "missed." This missed checklist is recorded, increases the worker's consecutive missed days counter (a key input to the AI risk model), and triggers a notification to the supervisor.

---

## Expected Outcome

By the end of Phase 3, every worker who opens the app sees a daily checklist tailored to their role. They can complete it item by item, see their progress in real time, and submit it. Supervisors can see which workers have completed their checklists for the current shift. Compliance rates are being calculated and stored, ready to feed into the AI system built in Phase 6.

---

---

# Phase 4 — Hazard Reporting System

**Duration:** Week 4–5  
**Type:** Core Feature

---

## What This Phase Is About

The hazard reporting system gives every mine worker the ability to report an unsafe condition they have observed, in any format that is convenient for them — a photo, a short video, a voice message in their own language, or a typed description. This phase builds the complete reporting pipeline, from the worker taking a photo on their phone to the supervisor receiving a notification and viewing the report.

---

## Why This Phase Matters

Hazard reporting is the single most powerful safety tool available to a workforce, and it is chronically underused in most mining operations. Workers often don't report hazards because the process is too difficult (finding the right form, filling it out, submitting it to the right person), because they fear retaliation, because they don't speak the language the forms are in, or simply because they are wearing gloves and can't type easily.

MiningGuard removes every one of these barriers. The reporting process is three taps and a voice note. It works in Hindi. It works with gloves on. And it works underground with no internet connection (reports are queued and sent when connectivity returns).

Every hazard report also feeds the AI system. A worker who reports multiple high-severity hazards over a short period is in a high-risk environment. The AI uses this to adjust their risk score and alert the supervisor before an incident occurs.

---

## What Gets Built in This Phase

### Three Input Modes

**Photo and Video:** The worker opens the report screen and takes a photo or video of the hazard directly within the app, or selects from their phone's gallery. The app compresses images before uploading to keep data usage low (important in areas with limited connectivity). Multiple photos can be attached to a single report.

**Voice Input:** The worker taps a large microphone button and speaks their report in their own language. The device's speech-to-text engine transcribes their words into text automatically. The original voice recording is also saved as an audio file attached to the report. This is the fastest input method for workers wearing gloves or in situations where they cannot type. It supports six regional languages.

**Text Description:** Workers who prefer typing can write a description directly. The text field supports all Indian language scripts, so a worker can type in Hindi or Bengali using their phone's keyboard without any special configuration.

### Hazard Categorization and Severity

After choosing their input method, the worker selects a hazard category from a simple visual menu: Roof Fall, Gas Leak, Fire, Machinery, Electrical, or Other. They also tag the severity: Low, Medium, High, or Critical. These tags are used to route the report to the right person (critical reports go directly to the site safety officer, not just the immediate supervisor) and to prioritize the supervisor's review queue.

If the worker has attached a photo, the AI image analysis feature (built in Phase 6) analyzes the image automatically and suggests a severity level. The worker can accept or override this suggestion before submitting.

### Location Tagging

Every report is automatically tagged with the mine section or zone where the worker is located. This is entered manually by the worker (selecting their current section from a list) since GPS does not work underground. This location data allows supervisors to see which areas of the mine are generating the most hazard reports — a heat map of risk.

### Report Lifecycle Management

Once submitted, a report moves through a defined lifecycle:

**Pending** — the report has been submitted and is waiting for the supervisor to acknowledge it. The supervisor receives an immediate push notification.

**Acknowledged** — the supervisor has seen the report and confirmed they are aware of it. The worker receives a notification that their report has been seen.

**In Progress** — the supervisor has assigned someone to address the hazard. The worker can see that action is being taken.

**Resolved** — the hazard has been addressed and the supervisor has marked the report as resolved, optionally adding a note explaining what was done. The worker receives a final notification confirming resolution.

This lifecycle serves two purposes: it closes the feedback loop for workers (they see their reports are taken seriously, which encourages future reporting), and it creates a documented audit trail that satisfies DGMS record-keeping requirements.

### Media Storage

All photos, videos, and voice recordings are uploaded to Firebase Storage with automatic organization by mine and report ID. The upload happens in the background while the worker continues using the app, so they are not forced to wait for a large video to finish uploading before they can do anything else. If the upload fails due to connectivity loss, it automatically retries when connectivity returns.

---

## Expected Outcome

By the end of Phase 4, any worker can submit a hazard report using photo, video, voice, or text in any of six supported languages. Reports are stored in Firestore with all their media, timestamped, and visible to supervisors immediately. The full report lifecycle (pending → acknowledged → in progress → resolved) is implemented with notifications at each stage. Workers can view the history of all their submitted reports and track their status.

---

---

# Phase 5 — Safety Education Module

**Duration:** Week 5–6  
**Type:** Engagement & Training Feature

---

## What This Phase Is About

This phase builds MiningGuard's safety education system — a short-form video-based learning experience designed to feel familiar to workers who already use YouTube or Instagram Reels. The goal is not to replace formal safety training but to reinforce safety knowledge continuously, in small daily doses, in a format that workers actually enjoy.

---

## Why This Phase Matters

Traditional safety training in mining happens in a classroom, once a quarter, with a long PowerPoint presentation. It is not effective because humans do not retain information from passive, infrequent learning sessions. The most effective safety training is frequent, short, contextualized, and immediately applicable to the worker's current job.

MiningGuard's education module delivers a three-to-five minute safety video every day, chosen specifically for that worker based on their role, their recent hazard reports, and their compliance history. A worker who filed a roof condition hazard report yesterday will see a video about proper roof support techniques today. A worker who has been consistently missing their cap lamp check will see a video about underground illumination and lamp maintenance.

This is not possible with a generic training schedule — it requires personalization, which is why the video selection is powered by the AI system.

---

## What Gets Built in This Phase

### Video of the Day

The most prominent feature of the Education screen is the "Video of the Day" — a single, personalized video shown as a large banner at the top of the screen. This video is automatically selected each morning based on the worker's profile and recent activity. The selection logic prioritizes:

First, videos that match the category of hazard reports the worker has recently submitted (if they reported a gas leak, they see a video about gas detection and ventilation). Second, content matched to the worker's current risk level (high-risk workers see videos on emergency procedures and critical PPE). Third, content matched to the worker's role and any patterns identified by the behavior analysis engine. Finally, a rotating schedule covering all safety topics ensures no category is neglected for too long.

### Video Categories

The content library is organized into categories that correspond directly to the hazard categories in the reporting system:

Personal Protective Equipment videos cover how to properly wear, inspect, and maintain each piece of PPE, including common mistakes workers make that reduce PPE effectiveness.

Gas and Ventilation videos explain how methane, carbon monoxide, and other mine gases behave underground, how to interpret gas detector readings, and what to do when readings exceed safe limits.

Roof and Ground Support videos address the most lethal category of underground mining accidents. They cover how to recognize signs of roof instability, proper use of support equipment, and what to do when conditions deteriorate unexpectedly.

Emergency Response videos cover evacuation procedures, the use of self-contained self-rescuers, mine fire response, and how to assist an injured colleague safely.

Machinery Safety videos cover pre-shift inspection procedures, safe operation zones around moving machinery, lockout/tagout procedures, and conveyor safety.

Content is sourced from DGMS India, MSHA USA, HSE UK, WorkSafe Australia, and custom videos that can be uploaded by the mine's own safety team. All videos are hosted as unlisted YouTube links, which means there is no storage cost and videos stream at the same quality as any YouTube video, even on limited data connections.

### Browse by Category

Workers can also explore the full video library by browsing categories. This gives workers who want to learn more about a specific topic the ability to do so without waiting for the daily recommendation to cover it.

### Watch Progress Tracking

The app tracks what percentage of each video the worker has watched. This data is used in two ways: the Continue Watching section shows videos the worker started but did not finish, and the watch completion rate feeds into the AI risk model as a positive behavioral signal. Workers who regularly watch safety videos have better safety knowledge and are slightly less likely to engage in high-risk behaviors.

### Comprehension Quiz

At 90% completion of any video, a short three-question quiz appears. The questions are simple, directly related to the video content, and presented with visual answer options (not long text) to be accessible for workers with limited literacy. Passing the quiz awards compliance points and reinforces the key lesson from the video. Workers who fail the quiz see the correct answers with brief explanations and can retry.

---

## Expected Outcome

By the end of Phase 5, the Education module is fully functional. Workers see a personalized Video of the Day every time they open the Education tab. They can browse videos by category, track their own progress, and take quizzes. Video watch history is recorded and ready to feed into the AI system in the next phase.

---

---

# Phase 6 — AI Backend & Machine Learning

**Duration:** Week 6–8  
**Type:** Core Intelligence Layer

---

## What This Phase Is About

This is the most technically complex and strategically important phase of the entire project. The AI backend is the intelligence layer that transforms MiningGuard from a digital checklist app into a genuine safety companion — one that learns from each worker's behavior, predicts who is at risk before an accident happens, analyzes images for safety violations, and ensures every recommendation is relevant to the individual worker.

All AI runs on a self-hosted FastAPI backend, using open-source machine learning libraries. No paid AI APIs are used, keeping the operating cost at zero.

---

## Why This Phase Matters

The entire value proposition of MiningGuard over a paper-based or simple digital safety system rests on the AI features. A paper checklist can record that a worker completed their PPE check. Only the AI can notice that this worker has been completing their PPE check 30 seconds faster than usual over the past three shifts, which correlates with lower accuracy, which correlates with a spike in near-miss incidents across the mine. Only the AI can analyze a photo uploaded with a hazard report and confirm "yes, this is a structural hazard, and based on the visual characteristics, this should be rated High severity, not Medium." Only the AI can look at this specific worker's history and know that they need a roof support video today, not a gas detection video.

---

## What Gets Built in This Phase

### Risk Prediction Engine

The risk prediction engine is a machine learning model that takes a set of behavioral features about a worker and predicts their current risk level as Low, Medium, or High. The model is trained on synthetic data generated from domain knowledge about mining safety — what patterns in behavior precede accidents.

The features the model considers include: how many checklists have been missed in the last seven days, how many consecutive days the worker has gone without completing a checklist, the worker's overall compliance rate, how many high-severity hazard reports they have filed recently, how many safety videos they have watched recently (a positive signal that reduces predicted risk), their role, and their shift type (night shift workers consistently show different safety profiles than day shift workers).

The model outputs not just a risk level but also a risk score from 0 to 100 and a list of the specific contributing factors that drove the prediction. This list is shown to the worker and their supervisor so the risk level is not just a number but an actionable insight: "Your risk level is High because you have missed three checklists this week and filed two high-severity reports."

The model is retrained as real usage data accumulates, improving its predictions over time.

### Behavior Analysis Engine

While the risk prediction engine looks at a snapshot of recent activity, the behavior analysis engine looks for patterns over a longer period — typically 30 days. It is looking for systematic behaviors that cannot be detected by looking at individual events.

Patterns it detects include:

A **weekly skip pattern** — a worker who consistently misses their checklist on Mondays is exhibiting a pattern. A single missed Monday is normal; five consecutive missed Mondays is a behavioral pattern that suggests the worker is deliberately skipping the start-of-week safety check, possibly because they find it inconvenient after a weekend away.

A **night shift compliance gap** — some workers complete checklists diligently on day and afternoon shifts but their compliance drops sharply on night shifts. This is often due to fatigue. The night shift is the highest-risk shift in most mines, so this pattern demands supervisor attention.

**Escalating severity in reports** — if a worker's recent hazard reports are progressively more severe (a Low last week, a Medium this week, a High this week), this suggests their working environment is deteriorating and may be heading toward a serious incident.

**Repeated same-item misses** — if a worker consistently skips the same checklist item across multiple shifts, this suggests either that item is genuinely impractical (in which case the checklist should be reviewed) or the worker has a blind spot for that specific risk.

When patterns are detected, the engine generates structured alerts that are sent to the supervisor with a clear, readable description of what was found and a suggested action.

### Image-Based Hazard Detection

This feature analyzes photos uploaded with hazard reports and automatically identifies safety violations or hazardous conditions.

The model is a convolutional neural network based on the MobileNetV2 architecture, which is specifically designed to be fast and accurate enough to run on modest hardware without a GPU. It is pre-trained on a large image dataset and then fine-tuned on mining-specific safety images.

The model can detect: a worker not wearing a helmet, a worker not wearing a high-visibility vest, general unsafe environmental conditions (standing water, exposed wiring, collapsed materials), and machinery hazards (unguarded moving parts, damaged equipment).

When a worker uploads a photo with their hazard report, the image is sent to this model before the report is submitted. Within one to two seconds, the model returns its findings: what hazard it detected, how confident it is, what severity level it suggests, and what corrective action it recommends. The worker sees this analysis before submitting and can accept or override it.

This serves two purposes. For the worker, it provides immediate validation that the hazard they identified is real and serious. For the supervisor, it adds an independent AI assessment to the report, which is useful when severity is disputed.

### Personalized Recommendation Engine

The recommendation engine decides what content — safety videos, tips, targeted checklists — each worker should see. It pulls from multiple sources of information about the worker: their recent behavior patterns, their risk level, the categories of hazards they have reported, the checklist items they most frequently miss, their role, and their shift.

The engine's primary output is the "Video of the Day" selection, which it chooses by scoring every available video against the worker's current profile and selecting the highest-scoring one. It also generates personalized safety tips that appear as brief cards on the worker's dashboard — concise, specific, actionable advice like "You've missed your gas detector check three times this week. Before you enter your work area today, confirm your meter is reading below 1% CH₄."

### Early Warning Alert System

The early warning system is the real-time component of the AI backend. While risk prediction and behavior analysis run periodically (triggered by events like checklist submission), the early warning system monitors Firestore in real time and fires alerts when thresholds are crossed.

Alert conditions include: risk level crossing from Medium to High, three or more checklists missed in a seven-day window, a pattern detection with high severity, multiple high-severity hazard reports from the same area of the mine within a short time (which may indicate a developing emergency), and unusual worker inactivity during an active shift.

Alerts are stored in the Firestore alerts collection, displayed in the worker's app immediately, and sent as high-priority push notifications. Critical alerts trigger a full-screen notification even if the phone is locked.

### Automated Trigger System

Rather than requiring the app to explicitly call the AI backend for every event, the system uses Firebase Cloud Functions as automated triggers. When a checklist is submitted, a function automatically calls the risk prediction endpoint and updates the worker's risk score. When a hazard report is filed, a function automatically calls the behavior analysis endpoint. When a video is watched to completion, a function updates the worker's activity profile.

This means the AI is always working in the background, keeping every worker's risk profile up to date, without requiring any deliberate action from the app.

---

## Expected Outcome

By the end of Phase 6, MiningGuard has a fully operational AI backend. Every worker has a risk score that updates automatically after each significant action. The image detection analyzes every uploaded photo in real time. Behavior patterns are detected and turned into supervisor alerts. The recommendation engine is personalizing content for each worker. The early warning system is monitoring for risk threshold crossings and generating alerts. The AI layer is the heart of what makes MiningGuard genuinely different from any other safety app.

---

---

# Phase 7 — Dashboards & Analytics

**Duration:** Week 8–9  
**Type:** Interface & Insights

---

## What This Phase Is About

The dashboards are where all the data collected by the previous phases — checklists, reports, AI risk scores, behavior patterns — becomes visible and actionable. This phase builds three distinct dashboard experiences: one for workers focused on personal safety performance, one for supervisors focused on mine-wide risk management, and one for administrators focused on systemic analytics and system management.

---

## Why This Phase Matters

Data is only valuable when it can be understood and acted upon quickly. A supervisor who must navigate three screens and run a manual query to find out which workers are at high risk today will not do it. The same information presented as a single screen with color-coded badges and a sorted list takes seconds to absorb and leads to faster intervention.

For workers, seeing their own risk score and compliance rate creates a personal accountability loop. When a worker can see that their compliance rate dropped to 60% because they missed three checklists, and they can see their risk level is now Medium because of it, they are more motivated to change their behavior than if they received an abstract warning message.

---

## What Gets Built in This Phase

### Worker Dashboard

The worker dashboard is the first thing a worker sees when they open MiningGuard. It is designed to be understood in under five seconds, even by someone who is not comfortable with technology.

At the top, the worker's risk level is displayed as a large, color-coded badge: green for Low, amber for Medium, red for High. Below this is a brief explanation of what is driving the current risk level — the contributing factors identified by the AI, written in plain language.

The next section shows today's checklist status. If the checklist is incomplete, a prominent button invites the worker to continue. If it is completed, the section shows the compliance score for that shift.

Below the checklist is the Video of the Day card, showing the video thumbnail and title with a play button. This is placed here deliberately — the worker sees it every time they check their dashboard, making it easy to integrate the daily video into their routine.

The bottom of the dashboard shows recent hazard reports and their current status, and any active alerts.

### Supervisor Dashboard

The supervisor dashboard gives a shift supervisor a complete view of their team's safety status at any moment during the shift.

The top of the screen shows mine-wide metrics: total workers on shift, number at each risk level, percentage of checklists completed so far for the day, and the number of pending hazard reports. These numbers are live — they update in real time as workers complete checklists and file reports.

The main section is a filterable list of all workers. By default, it is sorted by risk level (high-risk workers at the top). The supervisor can filter to show only high-risk workers, only workers with pending reports, or only workers who have not yet completed their checklist. Each worker in the list shows their name, current risk level badge, and a one-line summary of their status.

Tapping a worker opens their individual profile with their full compliance history, all their filed reports, and the AI's explanation of their current risk score. The supervisor can also send that worker a direct alert from this screen.

The pending reports section shows all unresolved hazard reports in the mine, sorted by severity. The supervisor can acknowledge, assign, and resolve reports from this view.

A compliance trend chart at the bottom shows the mine's average compliance rate over the past 30 days, making it easy to spot whether safety culture is improving or deteriorating over time.

### Admin Panel

The admin panel is used by the mine's safety officer or management. It covers user management (creating and deactivating accounts, assigning roles and mine IDs, bulk importing workers from a spreadsheet), content management (uploading new safety videos, creating and editing checklist templates, sending announcements to all workers), and analytics (mine-wide incident trends by month and quarter, DGMS compliance report generation, and a risk heatmap showing which sections of the mine generate the most hazard reports and highest risk scores).

---

## Expected Outcome

By the end of Phase 7, all three user roles have fully functional dashboards that display their most important information at a glance. Workers can see their personal safety performance. Supervisors can monitor their entire team in real time and take action on hazard reports. Admins can manage the system and generate compliance reports.

---

---

# Phase 8 — Notifications & Real-Time Sync

**Duration:** Week 9–10  
**Type:** Engagement & Communication Layer

---

## What This Phase Is About

Notifications are the system's voice. They are how MiningGuard communicates with workers and supervisors when they are not actively using the app — reminding workers to complete their checklists, alerting supervisors to newly filed hazard reports, and urgently notifying workers when a critical safety issue is detected. This phase also ensures that all data in the app stays synchronized in real time, so that when a supervisor resolves a report, the worker sees that resolution immediately without refreshing.

---

## Why This Phase Matters

An app that only communicates when the user actively opens it is not suitable for a safety context. Safety events happen continuously throughout a shift. A hazard that is reported at 9 AM needs to reach the supervisor's attention at 9 AM, not when they happen to open the app at 11 AM. An AI risk alert generated because a worker missed their third checklist of the week needs to reach the supervisor before the worker's next shift, not days later.

Real-time sync is equally important. The supervisor dashboard is only useful if it shows live data. If a checklist is submitted at 10:15 AM, the supervisor's dashboard should reflect that at 10:15 AM.

---

## What Gets Built in This Phase

### Push Notification Channels

Different types of notifications are delivered with different levels of urgency. The system establishes two notification channels on Android: a standard channel for regular notifications (reminders, updates, new videos) and a critical channel for safety alerts that must be seen immediately.

The critical channel uses the phone's maximum volume, bypasses Do Not Disturb mode, and on Android displays a full-screen notification that appears even when the phone is locked. This is the same behavior used by emergency call apps. It is used only for genuine critical safety events — risk level reaching High, a critical-severity hazard report in the worker's area, or an early warning from the AI behavior analysis. Overusing it would cause workers to ignore it.

### Notification Types and Triggers

Checklist reminders are sent automatically if a worker has not opened their checklist within one hour of their shift starting. A follow-up notification is sent if they still have not completed it 90 minutes into their shift. The timing accounts for the fact that workers may be in the middle of a task and cannot immediately stop to open the app.

Risk level notifications are sent when the AI updates a worker's risk level. If the change is from Low to Medium, a gentle notification informs the worker. If the change is from Medium to High, a high-priority notification is sent to both the worker and their supervisor simultaneously.

Hazard report notifications are sent to the supervisor immediately when a new report is filed. When the supervisor updates the report status (acknowledged, in progress, resolved), a notification is sent to the worker who filed the report.

The daily compliance summary is sent to supervisors at the end of each shift — a brief summary of the shift's safety performance: how many checklists were completed, any reports filed, any AI alerts triggered.

Video of the Day notifications are sent at the start of each shift to encourage workers to watch their daily video early in the day.

### Real-Time Data Sync

The app uses Firestore's real-time listener capability to keep all displayed data current. Rather than fetching data once and displaying it statically, the app listens for changes to Firestore documents and updates the UI automatically when changes occur.

The supervisor's worker list updates in real time as workers complete checklists. The hazard reports queue updates the moment a new report is filed. The worker's risk score badge updates immediately when the AI recalculates it. The alert feed updates as soon as a new alert is generated. Workers never need to pull-to-refresh — the data is always current.

---

## Expected Outcome

By the end of Phase 8, MiningGuard communicates proactively with all users through appropriately urgent notifications. Critical safety events trigger immediate high-priority alerts. Routine events trigger gentle reminders. All app data is synchronized in real time across devices — when a supervisor marks a report as resolved, the worker who filed it sees the update within seconds.

---

---

# Phase 9 — Multi-Language, Offline Support & Security

**Duration:** Week 10–11  
**Type:** Accessibility, Resilience & Protection

---

## What This Phase Is About

This phase addresses three critical requirements that determine whether MiningGuard is actually usable in real Indian mining conditions: the app must work in the worker's own language, it must work without an internet connection, and it must be secure enough to protect sensitive safety and personal data.

---

## Why This Phase Matters

Underground mines often have poor or no internet connectivity. A safety app that stops working underground is useless as a safety tool — which is precisely where safety tools are most needed. Offline support is not a nice-to-have feature; it is a fundamental requirement.

Multi-language support is equally non-negotiable. India's major coal mining regions span states where Hindi, Bengali, Telugu, Odia, and Marathi are the primary languages. A worker who is not literate in English cannot effectively use a safety app written entirely in English, particularly under the time pressure of a safety emergency. Language accessibility is a safety issue, not just a usability preference.

Security protects workers and supervisors. Hazard reports may contain sensitive information about conditions in the mine. Risk scores and compliance records are personal data. The identity of a worker who filed a harassment or safety violation report must be protected. Without proper security rules, this data could be read or altered by anyone with basic technical knowledge.

---

## What Gets Built in This Phase

### Full Localization in Six Languages

Every piece of text visible in the app — every screen title, button label, notification message, alert text, checklist item, error message, and tooltip — is translated into six languages: English, Hindi, Bengali, Telugu, Marathi, and Odia. These languages cover the primary linguistic groups found in India's major mining states.

The translation is implemented using Flutter's official localization system, which means the app automatically displays in the correct language based on the user's profile preference. Switching languages is instant and does not require restarting the app.

Special care is taken with safety-critical text — checklist items, hazard categories, severity labels, and alert messages are translated by people with domain knowledge of mining safety, not by general translation tools, to ensure that technical terms are accurate and unambiguous.

Voice input already supports all six languages through the device's speech-to-text engine. In this phase, the voice input prompts and feedback messages are also localized so a Hindi-speaking worker receives guidance in Hindi, not English.

### Offline-First Architecture

The app is redesigned in this phase to work as an offline-first application. This means that the app's default behavior is to read from and write to local storage on the device. Synchronization with Firestore happens in the background when connectivity is available, rather than being required for the app to function.

**Daily checklists** are downloaded to the device each morning when the worker first opens the app. If the worker then goes underground without connectivity, their checklist is already on their device. They complete it offline. When they return to a connected area, the completed checklist syncs to Firestore automatically.

**Hazard reports** created without connectivity are saved to a local queue on the device. The queue is managed by a background service that constantly monitors connectivity status. The moment internet access is restored — even briefly — the service uploads all queued reports in order of submission. Media files (photos, voice recordings) are queued separately and uploaded when a stronger connection is available.

**Alerts and notifications** received while offline are stored locally and displayed when the app opens, ensuring the worker does not miss important safety information.

### Firebase Security Rules

Security rules are the enforcement layer that ensures each user can only access data they are authorized to see. These rules are evaluated on Firebase's servers before any data is read or written, which means they cannot be bypassed by modifying the app.

The rules are organized around the principle of least privilege: every user has access to exactly the data they need, and nothing more.

Workers can read and update their own user profile and their own checklists and hazard reports. They cannot read other workers' data, even if they know those workers' user IDs.

Supervisors can read all worker profiles and all checklists and reports for their mine. They can update report statuses. They cannot read data from other mines.

Admins can read and write all data across all mines.

All users must be authenticated with a valid Firebase token to access any data at all. Unauthenticated requests are rejected before they reach any database.

Storage rules enforce file type and size restrictions — uploaded files must be images, videos, or audio recordings, and no individual file may exceed 100 MB. This prevents the storage bucket from being used to store arbitrary files.

The FastAPI backend verifies Firebase tokens on every request. No AI endpoint processes a request from an unauthenticated caller.

---

## Expected Outcome

By the end of Phase 9, MiningGuard is fully accessible to workers in six regional languages. The app functions completely offline for checklist completion and hazard report creation, with automatic sync when connectivity returns. The entire data infrastructure is protected by security rules that enforce role-based access control at the database level. The app is ready for deployment in a real mining environment.

---

---

# Phase 10 — Testing, Deployment & Launch

**Duration:** Week 11–12  
**Type:** Quality Assurance & Release

---

## What This Phase Is About

This final phase transforms MiningGuard from a development project into a production application that can be used by real workers in real mines. It covers comprehensive testing to find and fix issues before they affect users, optimizing the app's performance for the constrained hardware and connectivity conditions of mine environments, deploying all backend services to production hosting, and preparing the app for release on the Google Play Store.

---

## Why This Phase Matters

A safety application that crashes, shows wrong data, or loses a hazard report is worse than no safety application at all. If workers experience unreliable behavior, they will stop trusting the app, stop using it, and the entire project's value is lost. A thorough testing phase is not optional — it is the quality gate that determines whether MiningGuard is fit for its intended purpose.

Deployment is also not just a technical step. It includes preparing the production infrastructure to handle real load, configuring monitoring so that any problems in production are detected and addressed quickly, and setting up the processes that will keep the app running and improving after launch.

---

## What Gets Built in This Phase

### Unit Testing

Every significant piece of logic in the app is tested in isolation. The compliance scoring calculation is tested with multiple scenarios — all items complete, only mandatory items complete, zero items complete, different numbers of consecutive missed days — to confirm it produces the correct score in every case. The risk prediction API is tested with feature vectors representing Low, Medium, and High risk profiles to confirm the model predicts correctly.

Unit tests are automated and run as part of the CI/CD pipeline, so any code change that breaks existing functionality is caught immediately.

### Integration Testing

Integration tests verify that different components of the system work together correctly. A complete hazard report submission is tested end-to-end: the worker submits a report with an attached image, the image is uploaded to Firebase Storage, the AI analysis is called, the result is saved to Firestore, and the supervisor receives a push notification. Each step in this chain is verified.

### User Acceptance Testing

Before launch, the app is tested with real end users — ideally a small group of actual mine workers and supervisors who represent the target audience. This testing is invaluable because real users will interact with the app in ways that developers never anticipate. They will try to submit a voice report while walking, complete a checklist with dirty gloves, and navigate the app in bright outdoor sunlight on a low-end Android phone with 2 GB of RAM.

Feedback from user acceptance testing is used to make final adjustments to the UI, fix any confusing navigation flows, and identify any features that are working correctly technically but are not intuitive in practice.

### Performance Optimization

The app is profiled on representative hardware — a mid-range Android phone (around INR 8,000–15,000 price point, which is typical for mine workers in India) — to identify performance bottlenecks. The app must start up in under two seconds, load the home dashboard in under one second, and upload a 5 MB photo within five seconds on a 4G connection. Any feature that does not meet these targets is optimized.

The FastAPI backend is load-tested to ensure it can handle multiple concurrent requests. Since the AI models are the most compute-intensive part of the backend, they are profiled to confirm they can respond within one second even when multiple requests arrive simultaneously.

### Production Deployment

The FastAPI backend is deployed to a production hosting environment. For the zero-cost approach described in the earlier free-tier analysis, this means Render.com for initial deployment, with a migration path to Google Cloud Run as usage grows.

The production deployment includes: environment variable configuration (keeping API keys and secrets out of the codebase), logging so that errors in production can be diagnosed, and health monitoring so that if the backend goes offline, the team is alerted immediately.

### Play Store Release

The Flutter app is built in release mode (with code obfuscation and optimization), signed with a production signing key, and submitted to the Google Play Store. The Play Store listing includes screenshots in all supported languages, a complete feature description, a privacy policy (required because the app handles personal data), and clear information about the app's purpose and target audience.

### Post-Launch Monitoring Plan

The launch is the beginning, not the end. After the app is live, the following monitoring and improvement processes are established:

Firebase Analytics tracks which features are being used, how long workers spend on each screen, and where users drop out of multi-step flows (like the hazard report submission). This data drives future prioritization decisions.

Firebase Crashlytics automatically captures and reports any crashes in the production app, with full stack traces to aid diagnosis. Crash reports trigger immediate investigation.

A feedback channel is established — a simple in-app feedback button that allows workers to report problems or suggestions. This is particularly important because the workers who need the app most are least likely to leave a formal Play Store review.

A regular retraining schedule is established for the AI risk prediction model. As real behavioral data accumulates from actual mine workers, the model can be retrained on this data to improve its predictions. The first retraining is scheduled at 90 days post-launch.

---

## Expected Outcome

By the end of Phase 10, MiningGuard is a tested, deployed, production-ready application available on the Google Play Store. All features work correctly and perform within acceptable limits on mid-range Android hardware. The backend is live and handling real requests. Monitoring is in place to detect and respond to any issues. The app is ready to be piloted at an initial mine site, with a clear plan for collecting feedback, monitoring performance, and improving the system over time.

---

---

## 📊 Phase Dependencies Summary

```
Phase 1 (Setup)
    │
    └── Phase 2 (Auth)
            │
            ├── Phase 3 (Checklist)
            │       │
            │       └── Phase 6 (AI Backend) ◄─── Phase 4 (Reports)
            │                   │                        │
            │                   │                   Phase 5 (Education)
            │                   │
            │                   └── Phase 7 (Dashboards)
            │                               │
            │                           Phase 8 (Notifications)
            │                               │
            │                           Phase 9 (Language + Offline + Security)
            │                               │
            └───────────────────────────────┴── Phase 10 (Testing + Launch)
```

Phases 3, 4, and 5 can be developed in parallel by different developers.  
Phase 6 depends on Phases 3, 4, and 5 having their data structures finalized.  
Phases 7 and 8 can begin once Phase 6 is at least partially complete.  
Phase 9 work (localization and offline) can run in parallel with Phases 7 and 8.  
Phase 10 begins only after all previous phases are functionally complete.

---

## 🎯 Success Criteria

The project will be considered successfully completed when the following conditions are met:

A worker can open the app, complete their shift checklist, file a hazard report with a photo and voice description, and watch the Video of the Day — all within ten minutes and entirely in their preferred language, including in areas with no internet connectivity.

A supervisor can open the app and within thirty seconds see which workers on their current shift are at high risk, which checklists have not been completed, and which hazard reports are pending their action.

The AI correctly identifies at least 80% of test images containing a missing helmet or unsafe environment, with a false positive rate below 15%.

The risk prediction model's High risk classification has a precision of at least 75% on hold-out test data — meaning when the model says a worker is at high risk, it is correct at least three out of four times.

The app launches, loads the home dashboard, and is ready for interaction in under two seconds on a device with 2 GB of RAM and a mid-range processor.

All six supported languages display correctly, all notifications arrive in the user's preferred language, and voice input correctly transcribes speech in all six languages.

The app functions completely offline for checklist completion and hazard report creation, and all offline-created data successfully syncs to Firestore within thirty seconds of connectivity being restored.

---

*MiningGuard Project Plan · Version 1.0*  
*Stack: Flutter · Firebase · FastAPI · Scikit-learn · TensorFlow*  
*Built for mine workers across India — in their language, on their terms ⛏️🛡️*
