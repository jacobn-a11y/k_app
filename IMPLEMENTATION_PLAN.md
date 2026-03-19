# Hallyu — Implementation Plan

## Scope

This plan covers **Phase 1: Foundation** (Q2–Q3 2026) as defined in the PRD. The goal is to ship a functional iOS app with: Hangul engine, core SRS, Claude comprehension coach, initial media library, pronunciation system Levels 1–2, and monetization infrastructure.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  iOS App (SwiftUI)                   │
│  ┌───────────┐ ┌──────────┐ ┌────────────────────┐  │
│  │  Hangul    │ │  Media   │ │  SRS / Learning    │  │
│  │  Engine    │ │  Player  │ │  Engine            │  │
│  └───────────┘ └──────────┘ └────────────────────┘  │
│  ┌───────────┐ ┌──────────┐ ┌────────────────────┐  │
│  │  Voice /  │ │  Claude  │ │  Onboarding /      │  │
│  │  ASR      │ │  Coach   │ │  Placement         │  │
│  └───────────┘ └──────────┘ └────────────────────┘  │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS
┌──────────────────────▼──────────────────────────────┐
│               Backend API (Swift Vapor)              │
│  ┌───────────┐ ┌──────────┐ ┌────────────────────┐  │
│  │  Auth /   │ │  Content │ │  Learner Model     │  │
│  │  Users    │ │  Catalog │ │  Service           │  │
│  └───────────┘ └──────────┘ └────────────────────┘  │
│  ┌───────────┐ ┌──────────┐ ┌────────────────────┐  │
│  │  Claude   │ │  Whisper │ │  SRS Scheduling    │  │
│  │  Proxy    │ │  Proxy   │ │  Service           │  │
│  └───────────┘ └──────────┘ └────────────────────┘  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Data Layer                              │
│  PostgreSQL (users, content, learner models)         │
│  Redis (caching, Claude response cache)              │
│  S3/CloudFront (media assets)                        │
└─────────────────────────────────────────────────────┘
```

### Technology Decisions

| Layer | Choice | Rationale |
|---|---|---|
| iOS App | Swift 5.9+ / SwiftUI / iOS 17+ | PRD requirement; native performance for audio |
| Backend | Swift Vapor | Full-stack Swift; strong async/await; type-safe |
| Database | PostgreSQL | Relational integrity for learner models, content metadata |
| Cache | Redis | Claude response caching, session state |
| Media Storage | S3 + CloudFront CDN | Streaming video/audio with low latency |
| Auth | Sign in with Apple + email/password | iOS-native; Apple requirement for App Store |
| Payments | StoreKit 2 (Apple IAP) | Required for iOS subscriptions |
| CI/CD | Xcode Cloud + Fastlane | Native iOS pipeline |
| Local Storage | SwiftData (Core Data successor) | Offline SRS, downloaded content |

---

## Milestone Breakdown

### Milestone 0: Project Scaffold & Infrastructure (Week 1–2)

**Goal:** Runnable Xcode project with backend skeleton, CI, and deployment pipeline.

- [ ] Initialize Xcode project with SwiftUI App lifecycle, target iOS 17+
- [ ] Set up Swift Package Manager dependencies (Alamofire/URLSession networking, SwiftData, AVFoundation)
- [ ] Create Vapor backend project with folder structure (Controllers, Models, Migrations, Services)
- [ ] Set up PostgreSQL schema: `users`, `sessions`, `content_items`, `media_assets`
- [ ] Configure Redis for caching layer
- [ ] Set up S3 bucket + CloudFront distribution for media assets
- [ ] Configure Xcode Cloud CI: build, test, lint on every PR
- [ ] Set up Fastlane for TestFlight distribution
- [ ] Create shared Swift package for models shared between iOS and backend
- [ ] Implement basic app navigation shell (TabView: Learn, Library, Review, Profile)
- [ ] Set up logging and crash reporting (Sentry or similar)

**Deliverable:** App builds and runs showing empty tab navigation. Backend responds to health check. CI passes.

---

### Milestone 1: Authentication & User Management (Week 2–3)

**Goal:** Users can create accounts, sign in, and maintain a profile.

- [ ] Implement Sign in with Apple (ASAuthorizationController)
- [ ] Implement email/password auth with backend JWT token flow
- [ ] Create Vapor auth middleware (JWT verification)
- [ ] Design and implement `User` model: id, email, display name, created_at, subscription tier
- [ ] Build onboarding survey screen: motivation selector (K-drama, K-pop, webtoons, news, general), daily time goal (10/15/20/30 min)
- [ ] Create user profile screen with settings
- [ ] Implement secure token storage (Keychain)
- [ ] Add offline session support (queue API calls when offline)

**Deliverable:** User can sign up, sign in, complete onboarding survey, and see their profile.

---

### Milestone 2: Hangul Acquisition Engine (Week 3–6)

**Goal:** Complete Hangul learning experience covering all 24 basic jamo with stroke-order animation, voice input, syllable-block assembly, and media micro-tasks.

#### 2A: Jamo Data & Animation System (Week 3–4)
- [ ] Create jamo data model: 14 consonants + 10 vowels with stroke paths, audio files, romanization, example words
- [ ] Build stroke-order animation view using Canvas/Path with step-by-step playback
- [ ] Record or license multi-speaker audio for each jamo (minimum 4 speakers per PRD's HVPT principle)
- [ ] Implement jamo card UI: animated stroke order + audio playback + romanization hint

#### 2B: Voice-First Learning (Week 4–5)
- [ ] Integrate iOS Speech framework (SFSpeechRecognizer) for basic Korean ASR
- [ ] Build audio recording component with waveform visualization (AVAudioEngine)
- [ ] Implement phoneme-level comparison: learner recording vs. native model
- [ ] Create visual feedback UI: waveform overlay, color-coded accuracy indicators
- [ ] Build pronunciation result screen with score and corrective hint

#### 2C: Syllable-Block Assembly (Week 5)
- [ ] Implement drag-and-drop syllable block builder (initial, medial, final positions)
- [ ] Build block validation logic (valid vs. invalid Korean syllable combinations)
- [ ] Create assembly exercises with progressive difficulty (CV → CVC → CVCC)
- [ ] Add pronunciation challenge after each successful assembly

#### 2D: "Spot It in the Wild" Micro-Tasks (Week 5–6)
- [ ] Build media micro-task UI: short clip/image with tap-to-identify overlay
- [ ] Curate initial set of K-drama clips and webtoon panels for each jamo
- [ ] Implement tap-target detection and scoring
- [ ] Create lesson flow: jamo intro → practice → voice → spot-in-wild → SRS entry

#### 2E: Hangul Lesson Flow & Progression (Week 6)
- [ ] Design lesson sequencing: vowels first (ㅏㅓㅗㅜㅡㅣ), then consonants, then compound jamo
- [ ] Build lesson progress tracker (local + synced)
- [ ] Implement lesson completion celebrations and "can-do" milestone messaging
- [ ] Create Hangul review dashboard showing mastery per jamo

**Deliverable:** User completes full Hangul curriculum in ~14 days with voice practice, animations, and media connections. All jamo enter SRS.

---

### Milestone 3: Core SRS / Adaptive Learning Engine (Week 5–8)

**Goal:** Functional spaced repetition system with half-life regression scheduling across all item types.

#### 3A: SRS Data Model & Scheduling (Week 5–6)
- [ ] Design SRS item schema: `srs_items` (item_id, user_id, item_type, skill_tags, easiness_factor, half_life, last_reviewed, next_review, correct_count, incorrect_count)
- [ ] Implement half-life regression scheduler: predict memory strength from review history
- [ ] Build within-session fast loop: re-present errors and near-threshold items
- [ ] Build across-days slow loop: schedule reviews with expanding intervals

#### 3B: Review Interface (Week 6–7)
- [ ] Create review card UI supporting multiple item types:
  - Jamo recognition (see → pronounce)
  - Jamo production (hear → write/select)
  - Vocabulary recognition (Korean → meaning)
  - Vocabulary production (meaning → Korean)
  - Listening comprehension (hear clip → answer)
- [ ] Implement swipe/tap response mechanism with timing measurement (for speed tracking)
- [ ] Build review session flow: queue generation, card presentation, response grading, session summary
- [ ] Add review notifications (local push notifications for due items)

#### 3C: Learner Model (Week 7–8)
- [ ] Implement per-skill mastery tracking: accuracy, speed, retention dimensions
- [ ] Build skill map structure: vocabulary items, grammar constructions, phoneme contrasts, Hangul recognition/production
- [ ] Create Bayesian knowledge tracing update logic
- [ ] Build learner model sync between device and backend
- [ ] Create progress visualization: skill radar chart, CEFR-aligned milestones

**Deliverable:** Items from Hangul lessons automatically enter SRS. User gets daily review sessions with adaptive scheduling. Learner model updates in real-time.

---

### Milestone 4: Media Library & Content Engine (Week 7–10)

**Goal:** Browsable media library with 50 K-drama clips, 30 webtoon excerpts, and 20 news articles, all with scaffolding.

#### 4A: Content Ingestion Pipeline (Week 7–8)
- [ ] Design content schema: `content_items` (id, type, title, difficulty_score, lexical_coverage, speech_rate, transcript_ko, transcript_en, grammar_tags, vocabulary_tags, duration, media_url)
- [ ] Build morphological analysis service (Korean NLP: KoNLPy or similar via Python microservice)
- [ ] Implement difficulty scoring: composite of lexical frequency, syntactic complexity, speech rate
- [ ] Create content admin tools for bulk import and annotation review
- [ ] Process and upload initial content set to S3

#### 4B: Media Player (Week 8–9)
- [ ] Build video player with AVPlayer: play/pause, speed control (0.5x–2.0x), seek
- [ ] Implement subtitle overlay system: no subs → Korean subs → Korean+English toggle
- [ ] Build text reader for webtoon/news content with tap-to-lookup
- [ ] Create audio waveform display for pronunciation segments
- [ ] Implement offline media download and playback (background download manager)

#### 4C: Media Library UI (Week 9–10)
- [ ] Build library browse screen: filter by content type, difficulty, topic
- [ ] Implement content cards with thumbnail, difficulty badge, duration, completion status
- [ ] Create "For You" recommendation section based on learner model
- [ ] Build content detail screen with pre-task vocabulary preview
- [ ] Implement content bookmarking and history

#### 4D: Scaffolded Media Tasks (Week 10)
- [ ] Build comprehension question framework: multiple choice, true/false, short answer
- [ ] Implement listen-first → Korean subs → comprehension questions → vocabulary extraction flow
- [ ] Create vocabulary extraction: tap any word in transcript → add to SRS
- [ ] Build post-media summary: new words learned, grammar encountered, comprehension score

**Deliverable:** User browses media library, watches K-drama clips with progressive scaffolding, reads webtoon/news content, and extracts vocabulary into SRS.

---

### Milestone 5: Claude AI Integration (Week 9–12)

**Goal:** Claude serves as comprehension coach, pronunciation tutor, and grammar explainer within structured learning contexts.

#### 5A: Claude Proxy Service (Week 9)
- [ ] Build Claude API proxy in Vapor backend (rate limiting, auth, context injection)
- [ ] Implement response caching for high-frequency vocabulary/grammar explanations
- [ ] Create prompt templates for each of Claude's 5 roles with pedagogical guardrails
- [ ] Add response length enforcement (~150 words for glosses, ~300 for grammar)
- [ ] Implement cost tracking per user per role

#### 5B: Comprehension Coach (Role 1) (Week 9–10)
- [ ] Build highlight-to-explain UI: user selects word/phrase/sentence in media content
- [ ] Implement retrieval-first flow: "What do you think this means?" → user attempts → Claude explains
- [ ] Create Claude prompt with full context: media content, surrounding text, learner proficiency, previously studied items
- [ ] Display explanation card: literal meaning, contextual meaning, grammar pattern, simpler example, register note
- [ ] Allow saving explanation to personal notes

#### 5C: Pronunciation Tutor (Role 2) (Week 10–11)
- [ ] Integrate Claude feedback after ASR scoring for below-threshold attempts
- [ ] Build articulatory coaching prompt: Claude analyzes specific phoneme errors and provides targeted drills
- [ ] Create pronunciation coaching UI: native model → learner attempt → Claude feedback → retry
- [ ] Implement focused drill generation based on recurring error patterns

#### 5D: Grammar Explainer (Role 3) (Week 11)
- [ ] Build grammar explanation request flow from media context
- [ ] Implement Claude prompt: concise rule + contrastive example + retrieval question
- [ ] Create grammar card UI with expandable sections
- [ ] Add grammar pattern tracking to learner model

#### 5E: Content Adapter (Role 4) (Week 11–12)
- [ ] Implement exercise generation after media consumption
- [ ] Build Claude prompt for context-appropriate exercises: fill-in-blank, role-play prompts, inference questions
- [ ] Create exercise UI components for each exercise type
- [ ] Add generated exercises to review queue

#### 5F: Cultural Context Interpreter (Role 5) (Week 12)
- [ ] Build "Why did this happen?" flag UI for media moments
- [ ] Implement Claude prompt with scene context for cultural explanation
- [ ] Create cultural note cards with save-to-collection option

**Deliverable:** Claude is accessible from within every media and learning activity, providing constrained pedagogical coaching across all 5 roles.

---

### Milestone 6: Onboarding, Placement & Assessment (Week 11–13)

**Goal:** Smooth zero-knowledge onboarding and adaptive placement for returning learners.

#### 6A: Zero-Knowledge Onboarding (Week 11)
- [ ] Build first-session experience: 5 most common vowels via voice-first interaction
- [ ] Create "I can do this" moment: speak Korean → see score → spot in K-drama within 15 minutes
- [ ] Implement guided tutorial overlay for core app features
- [ ] Build daily learning plan introduction

#### 6B: Adaptive Placement (Week 12)
- [ ] Implement IRT-based item selection for placement assessment
- [ ] Build placement test UI: media-based comprehension items across reading, listening, vocabulary, grammar
- [ ] Create proficiency estimation algorithm from placement responses
- [ ] Map placement results to learner model initialization and content recommendations

#### 6C: Progress & Assessment (Week 12–13)
- [ ] Build CEFR-aligned "can-do" milestone system with notifications
- [ ] Create progress dashboard: skills overview, streaks, time invested, milestones achieved
- [ ] Implement Monthly Media Challenge framework (summative assessment)
- [ ] Build challenge results screen with CEFR-aligned scoring

**Deliverable:** New users have a polished onboarding experience. Returning learners skip ahead via placement. Progress is visible and motivating.

---

### Milestone 7: Monetization & Subscription (Week 12–14)

**Goal:** Three-tier subscription model with Apple IAP integration.

- [ ] Implement StoreKit 2 integration for subscriptions (Core $12.99/mo, Pro $19.99/mo, annual options)
- [ ] Build paywall screen with feature comparison table
- [ ] Create subscription management screen (upgrade, downgrade, cancel)
- [ ] Implement feature gating: free tier = Hangul + 3 clips per type + basic SRS; Core = full library + Claude; Pro = unlimited + challenges + offline
- [ ] Build receipt validation on backend (App Store Server API)
- [ ] Add upgrade prompts at natural conversion points (post-Hangul completion, after first media taste)
- [ ] Implement free trial flow (7-day trial for Core)

**Deliverable:** Users can subscribe, and features are correctly gated by tier.

---

### Milestone 8: Accessibility, Polish & Launch Prep (Week 14–16)

**Goal:** WCAG 2.2 AA compliance, performance optimization, and App Store submission.

#### 8A: Accessibility (Week 14)
- [ ] Full VoiceOver audit and fixes for all interactive elements
- [ ] Implement adjustable playback speed (0.5x–2.0x) across all audio/video
- [ ] Add high-contrast mode and Dynamic Type support
- [ ] Implement haptic feedback complement for pronunciation exercises
- [ ] Build alternative text-input mode for non-voice users (romanization fallback)

#### 8B: Performance & Polish (Week 15)
- [ ] Profile and optimize app launch time (<2 seconds)
- [ ] Optimize media streaming (adaptive bitrate, preloading)
- [ ] Memory and battery usage optimization for audio recording
- [ ] Implement proper error states, empty states, and loading states throughout
- [ ] Add onboarding animations and micro-interactions
- [ ] Localize all app chrome (English only for v1, but i18n-ready)

#### 8C: Testing & QA (Week 15–16)
- [ ] Unit tests for SRS scheduler, learner model, and placement algorithm
- [ ] UI tests for critical flows: onboarding, Hangul lesson, media consumption, review session
- [ ] Integration tests for Claude proxy and ASR pipeline
- [ ] Performance testing on iPhone 12 (minimum target device)
- [ ] Accessibility audit with VoiceOver
- [ ] Beta testing via TestFlight (internal → external)

#### 8D: App Store Submission (Week 16)
- [ ] Prepare App Store listing: screenshots, description, keywords, preview video
- [ ] Create App Store review notes (demo account, Claude usage explanation)
- [ ] Submit for App Review
- [ ] Prepare launch monitoring dashboards (crash rates, API latency, user funnel)

**Deliverable:** App approved and ready for App Store launch.

---

## Risk Mitigations Built Into Plan

| Risk | Mitigation in Plan |
|---|---|
| Media licensing delays | Milestone 4 uses placeholder content structure; real content can be swapped in independently |
| ASR accuracy for beginners | Milestone 2B starts with iOS Speech framework; Whisper fine-tuning can be iterated in parallel |
| Claude API costs | Milestone 5A includes response caching and per-user cost tracking from day one |
| Scope creep | Phase 1 explicitly excludes: social features, music module, short-form video, writing practice, iPad |
| Content pipeline bottleneck | Milestone 4A automates difficulty scoring; Claude generates draft exercises for human review |

---

## Out of Scope for Phase 1

- iPad support (Phase 3)
- Music/lyrics module (Phase 2)
- Short-form video (Phase 2)
- Social features (Phase 2)
- Media Shadowing Level 3 (Phase 2)
- Writing practice (Phase 3)
- Heritage learner pathway (Phase 3)
- Android (Phase 4)
- TOPIK alignment (Phase 3)

---

## Team Assumptions

This plan assumes a small team:
- 1–2 iOS engineers (SwiftUI, AVFoundation, Speech)
- 1 backend engineer (Vapor, PostgreSQL, API integrations)
- 1 ML/NLP engineer (Korean morphological analysis, SRS algorithm, Whisper fine-tuning)
- 1 designer (UI/UX, Hangul animations, brand)
- 1 content specialist (Korean language, media curation, exercise authoring)

---

## Summary Timeline

| Weeks | Milestone | Key Output |
|---|---|---|
| 1–2 | M0: Scaffold & Infra | Running project, CI/CD, backend skeleton |
| 2–3 | M1: Auth & Users | Sign in, onboarding survey, profiles |
| 3–6 | M2: Hangul Engine | Complete Hangul curriculum with voice & animation |
| 5–8 | M3: SRS Engine | Adaptive spaced repetition across all item types |
| 7–10 | M4: Media Library | 100 content items with scaffolded consumption |
| 9–12 | M5: Claude AI | 5 pedagogical roles integrated into learning flow |
| 11–13 | M6: Onboarding & Assessment | Zero-knowledge onboarding, placement, progress |
| 12–14 | M7: Monetization | Three-tier subscription with Apple IAP |
| 14–16 | M8: Polish & Launch | Accessibility, testing, App Store submission |

**Total: ~16 weeks (4 months) — aligns with Q2–Q3 2026 target.**
