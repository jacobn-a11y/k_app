# Hallyu App — Comprehensive Scope Audit

**Date:** 2026-03-19 (updated after latest main merge)
**Scope:** Full codebase audit against PRD (README.md), BUILD_PLAN.md, and IMPLEMENTATION_PLAN.md
**Codebase:** 136 Swift files (~27.5K lines), 93 source files + 43 test files

---

## Executive Summary

The Hallyu codebase implements **~92% of the V1 scope** defined across the PRD, BUILD_PLAN, and IMPLEMENTATION_PLAN. All 10 build phases (0–9) have functional code. The most recent main merge closed several previously-identified gaps: StoreKit 2 is now real (not stubbed), learner model persists to Keychain, vocabulary extraction persists to SwiftData, a Progress Dashboard exists in ContentView, snapshot tests and UI tests have been added, and a new PronunciationScorer provides phoneme-level scoring without external ML dependencies.

### Phase Completion Overview

| Phase | Status | Completion |
|-------|--------|------------|
| 0: Scaffold & Infrastructure | **Complete** | 100% |
| 1: Hangul Acquisition Engine | **Complete** | 100% (code; audio assets are content task) |
| 2: SRS Engine & Learner Model | **Complete** | 100% |
| 3: Media Library & Content | **Complete** | 95% |
| 4: Claude AI (5 Roles) | **Complete** | 100% |
| 5: Scaffolded Media Lessons | **Complete** | 100% |
| 6: Daily Plan & Recommendations | **Complete** | 100% |
| 7: Onboarding, Placement, Payments | **Complete** | 100% |
| 8: Progress & Assessments | **Complete** | 90% |
| 9: Offline, Polish, Accessibility | **Mostly Complete** | 75% |

---

## Phase-by-Phase Detailed Audit

### Phase 0: Project Scaffold & Core Infrastructure — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 0.1 Xcode Project | **Built** | `HallyuApp.swift` with SwiftData container, iOS 17+ via `Package.swift` (SPM-based, not `.xcodeproj`) |
| 0.2 Core Data Models | **Built** | 8 SwiftData `@Model` classes: LearnerProfile, VocabularyItem, GrammarPattern, MediaContent, ReviewItem, SkillMastery, StudySession, ClaudeInteraction |
| 0.3 Service Protocols & DI | **Built** | 8 protocols in `ServiceProtocols.swift`, `ServiceContainer` with concrete + mock implementations, injected via SwiftUI environment |
| 0.4 API Client & Supabase | **Built** | `APIClient.swift` (generic HTTP with retry), `SupabaseClient.swift` (auth headers, RLS, storage), `Environment.swift` |
| 0.5 Claude Service | **Built** | Actor-based `ClaudeService.swift` with SHA-256 caching, rate limiting (1s min interval), tier enforcement, token logging |
| 0.6 Audio & Speech | **Built** | `AudioService.swift` (AVFoundation recording/playback), `SpeechRecognitionService.swift` (Apple Speech Framework, ko-KR) |

**New since prior audit:** `MediaPlayerService.swift` (AVPlayer wrapper), `PronunciationScorer.swift` (jamo-level Levenshtein scoring), `PushNotificationAppDelegate.swift`.

---

### Phase 1: Hangul Acquisition Engine — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 1.1 Hangul Static Data | **Built** | 40 jamo entries (14 consonants + 10 vowels + 5 double + 11 compound) with IPA, romanization, stroke paths, mnemonics, position rules. 8 lesson groups. |
| 1.2 Stroke Order Animation | **Built** | `StrokeOrderView.swift` — Canvas-based bezier rendering with sequential animation, replay, speed control. Now includes reduced-motion check. |
| 1.3 Jamo Lesson Flow | **Built** | `JamoDetailView.swift` (display + audio), `HangulLessonView/ViewModel` (lesson progression, scoring, group-based sequencing) |
| 1.4 Syllable Block Builder | **Built** | `SyllableBlockBuilderView.swift` with inline state management, `HangulUtilities.swift` (Unicode arithmetic: 가 = 0xAC00 + initial×588 + medial×28 + final) |
| 1.5 Spot in the Wild | **Built** | `SpotInTheWildView.swift` + `SpotInTheWildData.swift` — expanded task set with per-group media micro-tasks |
| 1.6 SRS Integration | **Built** | `HangulReviewIntegration.swift` — completed jamo/syllables create ReviewItems in SwiftData |

**Content gap (not a code gap):** Audio recordings (72 files per PRD) referenced by `audioFileRef` but not bundled. Stroke data JSON files referenced but served from inline `StrokePath` arrays. Both are content tasks.

---

### Phase 2: SRS Engine & Learner Model — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 2.1 Half-Life Regression SRS | **Built** | `SRSEngine.swift` — `P(recall) = 2^(-t/h)`, growth factor 2.0×, decay 0.5×, speed bonus 1.1× for <3s responses, minimum 6h interval, within-session retry |
| 2.2 Bayesian Knowledge Tracing | **Built** | `LearnerModelService.swift` — BKT with P(init)=0.1, P(learn)=0.15, P(slip)=0.1, P(guess)=0.25. Tracks accuracy, speed, retention per skill. CEFR thresholds: A1=30%, A2=55%, B1=75%, B2=90%. **Now persists to Keychain** (was in-memory only). |
| 2.3 Review Session UI | **Built** | `ReviewSessionView/ViewModel`, `FlashcardView` (flip animation), `ReviewStatsView` (post-session stats) |

**Previously identified gap now closed:** Learner model persistence — `LearnerModelService` now calls `persistMasteryStore()` / `loadPersistedMasteryStore()` via Keychain.

---

### Phase 3: Media Library & Content Engine — COMPLETE (95%)

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 3.1 Content Seeding | **Built** | `MediaContentSeeder.swift` with sample data auto-seeded via `MediaContentSeeder.seedIfNeeded(modelContext:)` |
| 3.2 Korean Text Analyzer | **Built** | `KoreanTextAnalyzer.swift` — tokenization, frequency ranking, difficulty scoring, vocabulary coverage estimation |
| 3.3 Media Library UI | **Built** | `MediaLibraryView/ViewModel` with filtering (type, CEFR, duration), search, per-learner coverage indicators |
| 3.4 Media Player | **Built** | `MediaPlayerView.swift` (733 lines) — AVPlayer with subtitle toggle (none/Korean/Korean+English), word tap-to-lookup, speed control 0.5x–2.0x, segment navigation |

**Remaining gap:** `KoreanTextAnalyzer` uses simplified tokenization (whitespace + character-based), not morphological analysis. The IMPLEMENTATION_PLAN mentions a KoNLPy Python microservice — not built. Adequate for v1 but limits accuracy for compound words and agglutinative forms.

---

### Phase 4: Claude AI Integration (5 Roles) — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 4.1 Prompt Templates | **Built** | `ClaudePrompts.swift` — all 5 roles with JSON response schemas, retrieval-first prompting, regex-based sanitization (blocks injection markers, control chars, caps lengths), `sanitizeList()` for arrays |
| 4.2 Comprehension Coach | **Built** | `ComprehensionCoachView/ViewModel` — word tap → retrieval prompt → Claude explanation (literal + contextual meaning, grammar, register) |
| 4.3 Pronunciation Tutor | **Built** | `PronunciationTutorView/ViewModel` — ASR → PronunciationScorer → Claude coaching pipeline with articulatory tips and drill sequences |
| 4.4 Grammar Explainer | **Built** | `GrammarExplainerView/ViewModel` — rule + contrastive example + retrieval question |
| 4.5 Content Adapter | **Built** | `ContentAdapterView/ViewModel` — generates fill-in-blank, comprehension, production exercises from media context |
| 4.6 Cultural Context | **Built** | `CulturalContextView/ViewModel` — social dynamics, honorifics, slang, historical references |
| 4.7 Caching & Cost Mgmt | **Built** | SHA-256 cache keys, tier enforcement (free: 0, core: 50/day, pro: unlimited), `ClaudeInteraction` logging |

**Previously identified gap:** Pre-bundled explanations for top 500 vocab / 50 grammar patterns still not present. Runtime caching works but there's no pre-seeded cache.

---

### Phase 5: Scaffolded Media Lessons — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 5.1 Media Lesson Orchestrator | **Built** | `MediaLessonViewModel.swift` — 7-step state machine: preTask → firstListen → secondListen → comprehensionCheck → vocabularyExtraction → shadowingPractice → summary. Text content skips shadowing. |
| 5.2 Vocabulary Pre-Teaching | **Built** | `VocabularyPreTeachView.swift` — flashcard format, response time tracking, feeds learner model |
| 5.3 Shadowing Practice | **Built** | `ShadowingView.swift` — native segment playback, recording, transcript comparison, waveform display, Claude coaching |

**Previously identified gap now closed:** `addSelectedWordsToSRS()` now persists to SwiftData via `SwiftDataContextRegistry.shared.modelContext`, with duplicate-checking against existing ReviewItems.

---

### Phase 6: Daily Plan & Recommendations — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 6.1 Plan Generator | **Built** | `PlanGeneratorService.swift` — 5-priority algorithm: (1) overdue SRS reviews, (2) Hangul lessons for beginners, (3) media lesson with vocabulary coverage targeting 85–95%, (4) pronunciation drill if mastery lagging, (5) vocab/grammar filler. Respects daily time goal. |
| 6.2 Daily Plan UI | **Built** | `DailyPlanView.swift` (510 lines) — activity cards, progress tracking, streak counter, "Start next" navigation |

**Enhancement in latest main:** `PlanGeneratorService.makeMediaActivity()` now computes actual vocabulary coverage per candidate using `KoreanTextAnalyzer.estimateCoverage()` and shows "X% known vocab" in the activity subtitle.

---

### Phase 7: Onboarding, Placement & Payments — COMPLETE

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 7.1 Zero-Knowledge Onboarding | **Built** | `OnboardingView.swift` (expanded) + `OnboardingViewModel.swift` (314 lines) — multi-step flow with media preference, experience routing, goal setting, immediate jamo lesson |
| 7.2 Placement Test | **Built** | `PlacementTestViewModel.swift` (305 lines) — IRT-inspired adaptive assessment with capped length, media-based items, CEFR level estimation |
| 7.3 Auth | **Built** | `AuthService.swift` — Sign in with Apple, email/password, Keychain token storage, proactive token refresh |
| 7.4 Subscription | **Built** | `SubscriptionService.swift` — **Real StoreKit 2 integration** with `Product.products()`, `product.purchase()`, `Transaction.currentEntitlements`. Uses `#if canImport(StoreKit)` guards. Feature gating via `SubscriptionFeature` enum. |

**Previously identified gap now closed:** StoreKit 2 is no longer stubbed. `loadProducts()` calls `Product.products(for:)`, `purchase()` calls `product.purchase()` with verification, `restorePurchases()` iterates `Transaction.currentEntitlements`.

---

### Phase 8: Progress & Assessments — COMPLETE (90%)

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 8.1 Progress Dashboard | **Built** | `ProgressTabView` in `ContentView.swift` — CEFR level card, study stats (sessions/minutes/words), skill breakdown with progress bars, entry points to milestones and monthly challenge |
| 8.2 CEFR Milestones | **Built** | `CEFRMilestoneView.swift` — can-do statements per level (pre-A1 through B2), unlock logic tied to skill mastery thresholds |
| 8.3 Media Challenge | **Built** | `MediaChallengeView.swift` (771 lines) — monthly summative assessment with unseen media, comprehension scoring, CEFR-aligned rubrics, learner model recalibration |

**Remaining gap:** No time-series charts (vocabulary growth, daily study minutes, accuracy trends). The BUILD_PLAN specifies these in Step 8.1. Current dashboard shows aggregate stats but not historical trends.

---

### Phase 9: Offline, Polish & Accessibility — MOSTLY COMPLETE (75%)

| Build Plan Step | Status | Implementation |
|-----------------|--------|----------------|
| 9.1 Offline Mode | **Built** | `NetworkMonitor.swift`, `MediaDownloadManager.swift` (expanded), `OfflineSyncManager.swift` (expanded), `OfflineBanner.swift`. Claude features gracefully degrade. |
| 9.2 Accessibility | **Partially Built** | `AccessibilityHelpers.swift`, `AccessibilitySettingsView.swift`. Many improvements in latest main (`.accessibilityLabel`, `.accessibilityAddTraits(.isHeader)` added throughout). Critical gaps remain (see below). |
| 9.3 Push Notifications | **Built** | `NotificationService.swift` (expanded), `PushNotificationAppDelegate.swift` (new), `NotificationSettingsView.swift` |
| 9.4 App Store Prep | **Partially Built** | `AppStoreMetadata.swift`. Missing: app icon, launch screen, screenshots, TestFlight config. |

**Accessibility status — improved but still has gaps:**
- VoiceOver labels added to many views (Progress tab, ContentView tabs, Review tab)
- Some hardcoded font sizes remain (`.font(.system(size: 48))` in ProgressTabView)
- Reduced motion checks added to StrokeOrderView; other views may still need audit
- Haptic feedback integration status unclear — `HapticManager` exists but usage not verified across all touch interactions

---

## Test Coverage

| Type | Count | Target (BUILD_PLAN) | Status |
|------|-------|---------------------|--------|
| Unit test functions | ~600+ | 200+ | **3x target** |
| Test files | 43+ | — | Complete |
| Snapshot tests | 3 | 30 | **Started** (AuthView, SpotInTheWild, MediaPlayer) |
| UI tests (XCUITest) | 3 | 10 | **Started** (onboarding smoke, review deep link, media deep link) |

**New in latest main:**
- `Tests/SnapshotTests/CriticalScreensSnapshotTests.swift` — 3 snapshot tests using swift-snapshot-testing
- `Tests/UITests/CriticalFlowUITests.swift` — 3 XCUITest smoke tests
- Additional unit tests in AuthService, NotificationService, ServiceContainer, DailyPlanViewModel, HangulLesson, MediaLesson, PlacementTest, PronunciationTutor, SpotInTheWild

---

## What's BUILT and SOLID

1. **Complete Hangul curriculum** — 40 jamo with stroke animations, syllable assembly, pronunciation, media micro-tasks, SRS integration
2. **Half-life regression SRS** with Bayesian Knowledge Tracing — persists across sessions
3. **All 5 Claude AI roles** — comprehension, pronunciation, grammar, content adapter, cultural context — with prompt sanitization, caching, and tier enforcement
4. **Full 7-step media lesson flow** — pre-teach → listen → subtitles → comprehension → vocab extraction → shadowing → summary
5. **Real StoreKit 2 subscriptions** — product loading, purchase, verification, restore, feature gating
6. **Daily plan generator** with vocabulary coverage-aware content recommendation
7. **Pronunciation scoring** via jamo-level Levenshtein distance (PronunciationScorer)
8. **Offline infrastructure** — download manager, sync queue, graceful degradation
9. **Progress dashboard** with CEFR milestones and monthly media challenges

---

## Remaining Gaps (NOT YET BUILT)

### Code Gaps

| Gap | Priority | Effort | Notes |
|-----|----------|--------|-------|
| Time-series progress charts (vocab growth, study time, accuracy trends) | Medium | 2-3 days | BUILD_PLAN 8.1 specifies these; current dashboard shows only aggregates |
| Pre-bundled Claude explanations for top 500 vocab / 50 grammar | Low | 1-2 days | Would reduce API costs; runtime cache exists but no pre-seeded content |
| Full WCAG 2.2 AA accessibility pass | High | 3-5 days | Hardcoded fonts remain in some views; haptic integration incomplete; needs systematic audit |
| Snapshot test expansion (3 of 30 target) | Medium | 2-3 days | Framework integrated; needs coverage of remaining critical screens |
| XCUITest expansion (3 of 10 target) | Medium | 2-3 days | Framework integrated; needs full onboarding, review, media lesson flows |
| Morphological text analysis | Low | Deferred | KoreanTextAnalyzer uses simplified tokenization; real morphological analysis (KoNLPy) deferred |

### Content / Ops Gaps (not code tasks)

| Gap | Notes |
|-----|-------|
| Native speaker audio recordings (72 files) | Referenced in HangulData but not bundled |
| Stroke order JSON data files | Served from inline StrokePath arrays; external JSON format available |
| K-drama clips (50), webtoon excerpts (30), news articles (20) | Seeder has sample data; real licensed content is a business task |
| Vocabulary list (2,000 words) | Bundled frequency list exists; full 2K list needs content work |
| Grammar patterns (80) | Schema ready; content authoring needed |
| App icon, launch screen, screenshots | App Store submission assets |

---

## Architecture Quality Assessment

**Strengths:**
- Clean MVVM with protocol-driven services and dependency injection
- Actor-based concurrency for Claude API (thread-safe)
- SwiftData for persistence with Supabase sync path
- Every service has a protocol + mock for testing
- Flat module structure aids AI-assisted development (per BUILD_PLAN principle)

**Technical debt:**
- `@unchecked Sendable` on several service classes — should be replaced with proper actor isolation or verified send safety
- `SwiftDataContextRegistry.shared` singleton for cross-module model context access — works but is a global mutable state pattern
- Some views are very large (MediaChallengeView: 771 lines, MediaPlayerView: 733 lines) — could benefit from extraction

---

## Summary

The codebase is in strong shape for a V1 iOS app. All major features from the PRD are implemented with real (not stubbed) integrations. The primary remaining work is:
1. **Accessibility hardening** (~3-5 days) — the highest priority gap
2. **Progress charts** (~2-3 days) — the main missing feature from the BUILD_PLAN
3. **Test expansion** (~4-6 days) — snapshot and UI test coverage
4. **Content creation** — audio, media, vocabulary (business/content tasks, not code)
5. **App Store assets** — icon, screenshots, TestFlight setup

Estimated effort to close all code gaps: **~2-3 weeks** of focused development.
