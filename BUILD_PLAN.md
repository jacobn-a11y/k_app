# Hallyu — V1 Build Plan

**Objective:** Build a fully testable iOS app that delivers the complete Hangul-to-media learning pipeline described in the PRD, with minimal surface area, maximum maintainability, and an architecture optimized for AI-assisted iteration.

---

## Architecture Principles

### Minimize Surface Area
- **One target:** iOS 17+ iPhone only. No iPad, no Android, no web.
- **One language:** Swift + SwiftUI exclusively. No bridging, no React Native, no hybrid.
- **One backend pattern:** All server logic runs through a thin REST API layer backed by a single PostgreSQL database. No microservices.
- **One AI provider:** Claude API only. No local ML models in v1 (defer Whisper fine-tuning; use Apple Speech Framework for ASR and Claude for qualitative pronunciation feedback).
- **One state management pattern:** SwiftData for local persistence, `@Observable` for in-memory state. No Redux-style abstractions.

### Maximize AI-Assisted Development
- **Flat module structure:** Each feature is a self-contained Swift package with clear boundaries. AI tools can read/modify one module without understanding the whole app.
- **Protocol-driven design:** Every service dependency is behind a protocol. AI can swap implementations, write mocks, and generate tests without touching other modules.
- **Conventional file naming:** `{Feature}/{Feature}View.swift`, `{Feature}/{Feature}ViewModel.swift`, `{Feature}/{Feature}Service.swift`. AI tools can predict file locations.
- **No clever abstractions:** Prefer explicit, repetitive code over DRY abstractions that require cross-file context to understand. Three similar view models are better than one generic one.
- **Comprehensive test targets:** Every module has a parallel test target. AI can run tests after any change.

---

## Tech Stack (Final)

| Layer | Choice | Rationale |
|---|---|---|
| UI | SwiftUI | Declarative, testable via ViewInspector, less code than UIKit |
| Local DB | SwiftData | Native Apple, no ORM mapping layer, works with iCloud sync later |
| Networking | URLSession + async/await | No third-party dependency needed |
| Audio recording | AVFoundation | Native, reliable, no dependency |
| Speech recognition | Apple Speech Framework | On-device Korean ASR, no API cost, good enough for v1 |
| AI | Claude API (direct HTTP) | Single dependency, thin client, no SDK wrapper needed |
| Media playback | AVPlayer | Native, supports streaming, subtitles |
| Backend | Supabase (hosted PostgreSQL + Auth + Storage) | Eliminates need to build/deploy custom backend; row-level security; built-in auth; file storage for media assets; REST API auto-generated from schema |
| Push notifications | APNs via Supabase Edge Functions | SRS reminder notifications |
| Payments | StoreKit 2 | Native Apple IAP, required for App Store |

---

## Project Structure

```
Hallyu/
├── App/
│   ├── HallyuApp.swift                 # Entry point, dependency injection
│   ├── AppState.swift                   # Global observable state
│   └── ContentView.swift                # Root navigation (tab bar)
├── Core/
│   ├── Models/                          # Shared data models (SwiftData)
│   │   ├── User.swift
│   │   ├── LearnerProfile.swift
│   │   ├── VocabularyItem.swift
│   │   ├── GrammarPattern.swift
│   │   ├── MediaContent.swift
│   │   ├── ReviewItem.swift
│   │   ├── SkillMastery.swift
│   │   └── StudySession.swift
│   ├── Services/                        # Shared service protocols + implementations
│   │   ├── ClaudeService.swift          # Claude API client
│   │   ├── AudioService.swift           # Recording + playback
│   │   ├── SpeechRecognitionService.swift
│   │   ├── SRSEngine.swift              # Spaced repetition scheduler
│   │   ├── LearnerModelService.swift    # Mastery tracking
│   │   ├── MediaPlayerService.swift
│   │   ├── AuthService.swift
│   │   └── SubscriptionService.swift
│   ├── Networking/
│   │   ├── APIClient.swift              # Generic HTTP client
│   │   └── SupabaseClient.swift         # Supabase-specific calls
│   └── Utilities/
│       ├── HangulUtilities.swift        # Jamo decomposition, block assembly
│       └── KoreanTextAnalyzer.swift     # Frequency scoring, difficulty estimation
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   └── PlacementTestView.swift
│   ├── Hangul/
│   │   ├── HangulLessonView.swift
│   │   ├── HangulLessonViewModel.swift
│   │   ├── JamoDetailView.swift
│   │   ├── StrokeOrderView.swift        # Animated stroke order
│   │   ├── SyllableBlockBuilderView.swift
│   │   ├── SpotInTheWildView.swift      # Media micro-task
│   │   └── HangulData.swift             # Static jamo/syllable data
│   ├── MediaLibrary/
│   │   ├── MediaLibraryView.swift
│   │   ├── MediaLibraryViewModel.swift
│   │   ├── MediaDetailView.swift
│   │   ├── MediaPlayerView.swift
│   │   └── MediaFilters.swift
│   ├── MediaLesson/
│   │   ├── MediaLessonView.swift        # Scaffolded media consumption
│   │   ├── MediaLessonViewModel.swift
│   │   ├── ComprehensionTaskView.swift
│   │   ├── VocabularyExtractorView.swift
│   │   └── ShadowingView.swift
│   ├── Claude/
│   │   ├── ClaudeCoachView.swift        # Contextual AI overlay
│   │   ├── ClaudeCoachViewModel.swift
│   │   ├── ComprehensionCoachView.swift
│   │   ├── GrammarExplainerView.swift
│   │   ├── CulturalContextView.swift
│   │   └── ClaudePrompts.swift          # All prompt templates
│   ├── Pronunciation/
│   │   ├── PronunciationView.swift
│   │   ├── PronunciationViewModel.swift
│   │   ├── WaveformComparisonView.swift
│   │   └── MinimalPairDrillView.swift
│   ├── Review/
│   │   ├── ReviewSessionView.swift
│   │   ├── ReviewSessionViewModel.swift
│   │   ├── FlashcardView.swift
│   │   └── ReviewStatsView.swift
│   ├── Progress/
│   │   ├── ProgressDashboardView.swift
│   │   ├── ProgressViewModel.swift
│   │   ├── CEFRMilestoneView.swift
│   │   └── MediaChallengeView.swift
│   ├── DailyPlan/
│   │   ├── DailyPlanView.swift          # Today's learning plan
│   │   ├── DailyPlanViewModel.swift
│   │   └── PlanGeneratorService.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── SubscriptionView.swift
│       └── ProfileView.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Fonts/
│   ├── Audio/                           # Bundled native speaker recordings
│   └── HangulStrokeData/               # Stroke order animation data
└── Tests/
    ├── CoreTests/
    │   ├── SRSEngineTests.swift
    │   ├── LearnerModelTests.swift
    │   ├── HangulUtilitiesTests.swift
    │   └── KoreanTextAnalyzerTests.swift
    ├── FeatureTests/
    │   ├── HangulLessonViewModelTests.swift
    │   ├── MediaLessonViewModelTests.swift
    │   ├── ClaudeCoachViewModelTests.swift
    │   ├── PronunciationViewModelTests.swift
    │   ├── ReviewSessionViewModelTests.swift
    │   └── DailyPlanViewModelTests.swift
    └── IntegrationTests/
        ├── ClaudeServiceIntegrationTests.swift
        ├── SRSFlowTests.swift
        └── OnboardingFlowTests.swift
```

---

## Database Schema (Supabase / PostgreSQL)

```sql
-- Users & Auth (Supabase Auth handles the auth table)

CREATE TABLE learner_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    native_language TEXT DEFAULT 'en',
    cefr_level TEXT DEFAULT 'pre-A1',  -- pre-A1, A1, A2, B1, B2
    onboarding_completed BOOLEAN DEFAULT FALSE,
    hangul_completed BOOLEAN DEFAULT FALSE,
    daily_goal_minutes INT DEFAULT 15,
    subscription_tier TEXT DEFAULT 'free',  -- free, core, pro
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vocabulary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    korean TEXT NOT NULL,
    romanization TEXT,
    english TEXT NOT NULL,
    part_of_speech TEXT,
    cefr_level TEXT,
    frequency_rank INT,           -- media frequency rank
    media_domains TEXT[],         -- ['drama', 'news', 'webtoon']
    example_sentence_kr TEXT,
    example_sentence_en TEXT,
    audio_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE grammar_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_name TEXT NOT NULL,          -- e.g., "Subject marker -이/가"
    pattern_template TEXT NOT NULL,      -- e.g., "[noun]-이/가"
    explanation TEXT NOT NULL,
    cefr_level TEXT,
    formality_level TEXT,               -- formal, informal, neutral
    example_sentences JSONB,            -- [{kr: "...", en: "...", context: "..."}]
    common_mistakes TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE media_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content_type TEXT NOT NULL,          -- drama, news, webtoon, short_video, music
    source TEXT,                         -- show name, publication, etc.
    difficulty_score FLOAT,             -- 0.0 to 1.0
    cefr_level TEXT,
    duration_seconds INT,               -- for audio/video
    transcript_kr TEXT,                 -- full Korean text/transcript
    transcript_segments JSONB,          -- [{start_ms, end_ms, text_kr, text_en}]
    vocabulary_ids UUID[],              -- vocabulary items present in this content
    grammar_pattern_ids UUID[],
    media_url TEXT,                     -- Supabase Storage URL
    thumbnail_url TEXT,
    cultural_notes TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE review_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL,             -- vocabulary, grammar, hangul, pronunciation
    item_id UUID NOT NULL,              -- references vocab/grammar/etc.
    ease_factor FLOAT DEFAULT 2.5,
    interval_days FLOAT DEFAULT 0,
    half_life_days FLOAT DEFAULT 1.0,
    repetitions INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    incorrect_count INT DEFAULT 0,
    last_reviewed_at TIMESTAMPTZ,
    next_review_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE skill_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_type TEXT NOT NULL,            -- hangul_recognition, hangul_production,
                                        -- vocab_recognition, vocab_production,
                                        -- grammar, listening, reading, pronunciation
    skill_id TEXT NOT NULL,             -- specific skill identifier
    accuracy FLOAT DEFAULT 0.0,         -- 0.0 to 1.0
    speed_ms FLOAT,                     -- response time
    retention FLOAT DEFAULT 0.0,        -- 0.0 to 1.0
    attempts INT DEFAULT 0,
    last_assessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, skill_type, skill_id)
);

CREATE TABLE study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_type TEXT NOT NULL,          -- hangul, media, review, pronunciation, challenge
    duration_seconds INT,
    items_studied INT DEFAULT 0,
    items_correct INT DEFAULT 0,
    media_content_id UUID REFERENCES media_content(id),
    session_data JSONB,                 -- flexible per-session metadata
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE claude_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL,                  -- comprehension, pronunciation, grammar, adapter, cultural
    context_media_id UUID REFERENCES media_content(id),
    user_query TEXT,
    claude_response TEXT,
    prompt_tokens INT,
    completion_tokens INT,
    cached BOOLEAN DEFAULT FALSE,       -- was this served from cache?
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_review_items_next ON review_items(user_id, next_review_at);
CREATE INDEX idx_skill_mastery_user ON skill_mastery(user_id, skill_type);
CREATE INDEX idx_study_sessions_user ON study_sessions(user_id, started_at DESC);
CREATE INDEX idx_media_content_type ON media_content(content_type, cefr_level);
CREATE INDEX idx_vocabulary_freq ON vocabulary_items(frequency_rank);
```

---

## Build Phases — Step by Step

Every phase ends with a testable milestone. Each step within a phase lists the exact files to create/modify, what to test, and the acceptance criteria.

---

### Phase 0: Project Scaffold & Core Infrastructure
**Goal:** Xcode project builds, runs on simulator, has dependency injection wired, and core services are stubbed with tests passing.

#### Step 0.1 — Create Xcode Project
- Create new Xcode project: "Hallyu", iOS App, SwiftUI lifecycle, Swift, SwiftData
- Set deployment target: iOS 17.0
- Set bundle ID: `com.hallyu.app`
- Create folder structure matching the project structure above
- Add `.gitignore` for Xcode/Swift

**Test:** Project builds and shows blank screen on simulator.

#### Step 0.2 — Define Core Data Models
- Create all SwiftData `@Model` classes in `Core/Models/`
- `User.swift`, `LearnerProfile.swift`, `VocabularyItem.swift`, `GrammarPattern.swift`, `MediaContent.swift`, `ReviewItem.swift`, `SkillMastery.swift`, `StudySession.swift`
- Each model mirrors the database schema but is the local SwiftData representation
- Add `Codable` conformance for Supabase sync

**Test:** Unit tests that create, save, fetch, and delete each model in an in-memory SwiftData container.

#### Step 0.3 — Service Protocols & Dependency Injection
- Define protocols: `ClaudeServiceProtocol`, `AudioServiceProtocol`, `SpeechRecognitionServiceProtocol`, `SRSEngineProtocol`, `LearnerModelServiceProtocol`, `MediaPlayerServiceProtocol`, `AuthServiceProtocol`, `SubscriptionServiceProtocol`
- Create `ServiceContainer` (simple DI container using `@Observable`)
- Register mock implementations for all protocols
- Inject `ServiceContainer` via SwiftUI environment

**Test:** App launches with mock services. Unit tests verify DI resolution.

#### Step 0.4 — API Client & Supabase Client
- `APIClient.swift`: Generic async HTTP client with retry logic, error handling
- `SupabaseClient.swift`: Wraps APIClient with Supabase-specific auth headers, URL construction, RLS support
- Environment configuration: `.debug` / `.release` with different API keys (stored in Xcode config, never in code)

**Test:** Unit tests with mocked URLProtocol verifying request construction, retry behavior, error mapping.

#### Step 0.5 — Claude Service
- `ClaudeService.swift`: Implements `ClaudeServiceProtocol`
- Methods: `getComprehensionHelp(context:query:)`, `getPronunciationFeedback(transcript:target:)`, `getGrammarExplanation(pattern:context:)`, `generatePracticeItems(mediaContent:learnerLevel:)`, `getCulturalContext(moment:mediaContent:)`
- `ClaudePrompts.swift`: All system prompts and prompt templates stored as static strings
- Response parsing with `Codable` structs
- Token counting and rate limiting
- Caching layer: hash prompt → check local cache → return cached or call API

**Test:** Unit tests with mocked HTTP responses for each Claude role. Verify prompt construction, response parsing, caching.

#### Step 0.6 — Audio & Speech Recognition Services
- `AudioService.swift`: Record audio (AVAudioRecorder), play audio (AVAudioPlayer), manage audio sessions
- `SpeechRecognitionService.swift`: Apple Speech Framework wrapper for Korean (`ko-KR` locale), returns transcript + confidence scores per segment

**Test:** Unit tests for service state management (recording states, session configuration). Integration test that records and plays back on device.

**Phase 0 Acceptance:** App launches on simulator. All core services are injectable and mockable. 30+ unit tests pass.

---

### Phase 1: Hangul Acquisition Engine
**Goal:** Complete Hangul learning experience from zero to full syllable-block decoding. This is the free tier's core value.

#### Step 1.1 — Hangul Static Data
- `HangulData.swift`: Define all 14 basic consonants, 10 basic vowels, 5 double consonants, 11 compound vowels
- Each jamo entry: character, romanization, IPA, audio file reference, stroke order data (array of bezier paths with draw order), mnemonic, position rules (initial/medial/final)
- Define syllable block assembly rules (C+V, C+V+C patterns)
- Lesson sequence: 5 groups of ~5 jamo each, ordered by frequency and visual/phonetic distinctiveness

**Test:** Unit tests verifying jamo data completeness, valid stroke paths, correct assembly rules.

#### Step 1.2 — Stroke Order Animation View
- `StrokeOrderView.swift`: SwiftUI Canvas-based animated stroke rendering
- Input: Array of bezier paths with draw order
- Animation: Draws each stroke sequentially with a "pen" indicator
- User mode: User traces on screen, system scores accuracy (distance from target path)
- Replay button, speed control (slow/normal)

**Test:** Preview renders all 24 basic jamo correctly. Snapshot tests for each jamo.

#### Step 1.3 — Jamo Lesson Flow
- `JamoDetailView.swift`: Single jamo lesson screen
  1. See the jamo with stroke animation (auto-plays)
  2. Hear native pronunciation (multiple speakers — bundle 3 recordings per jamo minimum)
  3. See romanization hint + mnemonic
  4. User traces the jamo (stroke order practice)
  5. User speaks the jamo (record → ASR → feedback)
  6. Claude pronunciation coaching if ASR confidence < threshold
- `HangulLessonView.swift`: Sequences 3–5 jamo per lesson
- `HangulLessonViewModel.swift`: Manages lesson state, progress, scoring

**Test:** ViewModel tests: lesson progression, scoring logic, completion detection. Mock ASR and Claude service.

#### Step 1.4 — Syllable Block Builder
- `SyllableBlockBuilderView.swift`: Interactive drag-and-drop
  - Three position slots shown (initial, medial, final)
  - Available jamo tiles (from learned set)
  - User drags jamo to correct position
  - Assembled block renders in real-time as composed Hangul character
  - User pronounces the assembled syllable
  - Scoring: construction accuracy + pronunciation accuracy
- `HangulUtilities.swift`: Programmatic Hangul composition/decomposition using Unicode arithmetic (가 = 0xAC00 + initial*588 + medial*28 + final)

**Test:** Unit tests for Hangul composition: every valid combination produces correct Unicode character. ViewModel tests for drag-drop state management.

#### Step 1.5 — "Spot It in the Wild" Micro-Task
- `SpotInTheWildView.swift`: Media micro-task at the end of each jamo group
  - Shows a K-drama screenshot or webtoon panel containing the target jamo
  - User taps all instances of the target jamo in the image
  - Tap targets are pre-annotated in the media content metadata (bounding boxes)
  - Celebratory feedback on success

**Test:** ViewModel tests for tap detection, scoring. Content validation tests ensuring every jamo group has at least 1 media micro-task.

#### Step 1.6 — Hangul Review Integration with SRS
- Wire completed jamo and syllable blocks into `ReviewItem` creation
- Review modes: see block → say sound (recognition), hear sound → construct block (production)
- Reviews interleaved in daily plan

**Test:** SRS scheduling tests: new items enter review, intervals expand on success, contract on failure.

**Phase 1 Acceptance:** User can complete full Hangul curriculum (24 basic jamo + syllable blocks) with stroke practice, pronunciation recording, and media micro-tasks. All learned items enter SRS. ~50 additional tests pass.

---

### Phase 2: SRS Engine & Learner Model
**Goal:** Adaptive spaced repetition and skill tracking power all future features.

#### Step 2.1 — Half-Life Regression SRS Engine
- `SRSEngine.swift`: Implements half-life regression model
  - `predictRecallProbability(item: ReviewItem, at: Date) -> Double`
  - `scheduleNextReview(item: ReviewItem, wasCorrect: Bool, responseTime: TimeInterval) -> Date`
  - `getDueItems(for userId: UUID, limit: Int) -> [ReviewItem]`
  - Within-session fast loop: re-present errors within same session
  - Across-session slow loop: schedule future reviews
- Parameters: initial half-life = 1 day, growth factor on success = 2.0, decay factor on failure = 0.5, response-time modifier

**Test:** Extensive unit tests:
- Correct answers increase interval
- Incorrect answers decrease interval
- Fast correct answers get slight interval bonus
- Items due are returned in priority order
- Session loop re-presents failed items

#### Step 2.2 — Learner Model (Bayesian Knowledge Tracing)
- `LearnerModelService.swift`:
  - Per-skill mastery tracking across dimensions: accuracy, speed, retention
  - Skill types: `hangul_recognition`, `hangul_production`, `vocab_recognition`, `vocab_production`, `grammar`, `listening`, `reading`, `pronunciation`
  - `updateMastery(userId:skillType:skillId:wasCorrect:responseTime:)`
  - `getMastery(userId:skillType:skillId:) -> SkillMastery`
  - `getOverallLevel(userId:) -> CEFRLevel`
  - CEFR level estimation based on aggregate skill mastery

**Test:** Mastery converges toward 1.0 with repeated successes. CEFR estimation aligns with expected thresholds.

#### Step 2.3 — Review Session UI
- `ReviewSessionView.swift`: Card-based review interface
  - Shows prompt (word, audio clip, syllable block)
  - User responds (tap answer, speak, construct block)
  - Feedback (correct/incorrect with explanation)
  - Session summary with stats
- `FlashcardView.swift`: Reusable card component with flip animation
- `ReviewStatsView.swift`: Post-session accuracy, streak, items mastered

**Test:** ViewModel tests for session flow, answer validation, stat calculation.

**Phase 2 Acceptance:** SRS reviews work end-to-end. Hangul items flow through review sessions. Learner model tracks mastery. ~30 additional tests.

---

### Phase 3: Media Library & Content Engine
**Goal:** Users can browse, filter, and access scaffolded Korean media content.

#### Step 3.1 — Media Content Data Seeding
- Seed Supabase with initial content:
  - 50 K-drama clips (2–5 min segments) with Korean transcripts, English translations, timestamps, vocabulary tags
  - 30 webtoon excerpts (dialogue panels) with text extraction
  - 20 news articles with paragraph segmentation
- Each piece of content has: difficulty score, CEFR level, vocabulary_ids, grammar_pattern_ids, cultural_notes
- Store media files in Supabase Storage

**Note:** For development/testing, use placeholder content with correct schema. Real licensed content is a business operation, not a code task.

#### Step 3.2 — Korean Text Analyzer
- `KoreanTextAnalyzer.swift`:
  - `analyzeText(korean: String) -> TextAnalysis` — returns vocabulary tokens, grammar patterns detected, difficulty score
  - Uses a bundled frequency list (top 6000 Korean words by media frequency)
  - Estimates vocabulary coverage for a given learner profile
  - Difficulty scoring: lexical frequency coverage * syntactic complexity * text length

**Test:** Analyzer correctly tokenizes Korean text, maps to frequency ranks, computes coverage.

#### Step 3.3 — Media Library UI
- `MediaLibraryView.swift`: Grid/list of available media content
  - Filter by: content type (drama/news/webtoon/video/music), CEFR level, duration
  - Each card shows: thumbnail, title, type badge, difficulty indicator, estimated vocabulary coverage for this learner
  - Color-coded difficulty: green (85%+ coverage), yellow (70-85%), red (<70%)
- `MediaDetailView.swift`: Preview, description, vocabulary preview, "Start Lesson" button
- `MediaLibraryViewModel.swift`: Fetch content from Supabase, apply filters, compute per-user coverage

**Test:** ViewModel tests: filtering logic, coverage calculation, sort order.

#### Step 3.4 — Media Player with Scaffolding
- `MediaPlayerView.swift`: AVPlayer wrapper with learning features
  - For video: play/pause, seek, speed control (0.5x–2.0x)
  - Subtitle modes: none → Korean only → Korean + English
  - Tap any word in Korean subtitles to highlight and invoke Claude
  - For text: scrolling reader with tap-to-highlight any word/phrase
  - For audio: waveform display with playback position
- Segment-by-segment navigation for transcript-aligned content

**Test:** Subtitle mode toggling, word tap detection, playback speed changes.

**Phase 3 Acceptance:** Users can browse media library, filter by type/level, open any content piece, play media with Korean subtitles, and tap words. ~25 additional tests.

---

### Phase 4: Claude AI Integration (5 Roles)
**Goal:** Claude functions as a contextual learning coach within every media interaction.

#### Step 4.1 — Prompt Engineering & Templates
- `ClaudePrompts.swift`: Define all prompt templates
  - System prompt establishing Claude's role as a Korean language coach
  - Per-role prompt templates with placeholders for: learner CEFR level, current media context, user query, learner's known vocabulary/grammar
  - Response format constraints (JSON with specific fields per role)
  - Word count limits enforced in system prompt (150 words for glosses, 300 for grammar)
  - Retrieval-first prompting: Claude asks learner to guess before explaining

**Test:** Prompt templates produce valid prompts when filled. Response format is parseable.

#### Step 4.2 — Comprehension Coach (Role 1)
- `ComprehensionCoachView.swift`: Slide-up panel when user taps a word/phrase in media
  - Flow: word tapped → "What do you think this means?" (retrieval first) → user types/speaks guess → Claude provides explanation
  - Claude response includes: literal meaning, contextual meaning, grammar pattern, simpler example, register note
  - "Add to review" button → creates ReviewItem for this vocabulary/grammar
- Wire into `MediaPlayerView` and text reader

**Test:** ViewModel tests for the full flow. Mock Claude responses. Verify ReviewItem creation.

#### Step 4.3 — Pronunciation Tutor (Role 2)
- Extend `PronunciationView.swift`:
  - User records pronunciation of a word/phrase
  - Apple Speech Framework transcribes
  - If transcription matches target: success feedback
  - If mismatch: send to Claude with target text + transcription + learner level
  - Claude provides articulatory coaching (specific to the error)
  - "Try again" loop

**Test:** ViewModel tests for the correction flow. Mock ASR results and Claude feedback.

#### Step 4.4 — Grammar Explainer (Role 3)
- `GrammarExplainerView.swift`: Triggered from media or review context
  - Shows the grammar pattern in context
  - Retrieval first: "Can you identify what grammar rule is at work here?"
  - Claude explains: rule statement, contrastive example, retrieval question
  - Links to other media examples of same pattern

**Test:** ViewModel tests for explanation flow, retrieval question validation.

#### Step 4.5 — Content Adapter (Role 4)
- Integrated into `MediaLessonViewModel`:
  - After user completes a media segment, Claude generates:
    - 2-3 fill-in-the-blank exercises using vocabulary from the segment
    - 1 comprehension question testing inference
    - 1 production prompt (speaking practice using patterns from the segment)
  - Generated items are presented as a post-media mini-quiz
  - Correct/incorrect responses feed the learner model

**Test:** Generated exercise parsing, answer validation, learner model updates.

#### Step 4.6 — Cultural Context Interpreter (Role 5)
- `CulturalContextView.swift`: Available via a "?" button during media consumption
  - User flags a confusing cultural moment
  - Claude explains: social dynamics, honorific context, historical references, slang
  - Optional: link to related media that illustrates the same concept

**Test:** Response rendering, link handling.

#### Step 4.7 — Claude Interaction Caching & Cost Management
- Local cache: hash(prompt_template + context_key) → cached response
- High-frequency explanations (top 500 vocab, top 50 grammar patterns) are pre-generated and bundled
- Per-user daily interaction counter (free tier: 0 Claude calls, core: 50/day, pro: unlimited)
- Token usage logging to `claude_interactions` table

**Test:** Cache hit/miss logic, tier enforcement, token logging.

**Phase 4 Acceptance:** All 5 Claude roles functional within media consumption flow. Caching reduces redundant API calls. Tier limits enforced. ~40 additional tests.

---

### Phase 5: Scaffolded Media Lesson Flow
**Goal:** End-to-end lesson experience that turns raw media into structured learning.

#### Step 5.1 — Media Lesson Orchestrator
- `MediaLessonView.swift` + `MediaLessonViewModel.swift`: The core lesson flow
  1. **Pre-task:** Vocabulary pre-teaching (5-8 key words from the segment, flashcard-style)
  2. **First listen/read:** Media plays with NO subtitles (or unglossed text). User absorbs.
  3. **Second listen/read:** Korean subtitles/glosses enabled. User can tap words.
  4. **Comprehension check:** 3-5 questions (multiple choice + short answer). Claude-generated or pre-authored.
  5. **Vocabulary extraction:** New words shown, user selects which to add to SRS.
  6. **Shadowing practice:** (for audio/video) User shadows 2-3 key sentences.
  7. **Session summary:** Words learned, accuracy, time spent.
- Each step is a distinct view within a `TabView` or custom pager

**Test:** Full lesson flow in ViewModel tests: state transitions, data persistence at each step, session recording.

#### Step 5.2 — Vocabulary Pre-Teaching Component
- Shows 5-8 words that will appear in the upcoming media
- Flashcard format: Korean → user guesses → reveal English + pronunciation
- Feeds learner model (pre-task accuracy becomes baseline)

**Test:** Word selection logic (picks words user hasn't mastered), card flip state.

#### Step 5.3 — Shadowing Practice Component
- `ShadowingView.swift`:
  - Plays native speaker segment (1-2 sentences)
  - User records their attempt
  - Side-by-side waveform comparison (visual)
  - ASR transcript comparison
  - Claude coaching on specific differences
  - "Try again" option

**Test:** Recording flow, waveform rendering input validation, ASR integration.

**Phase 5 Acceptance:** Complete media lesson flows from pre-task through shadowing for all content types. ~20 additional tests.

---

### Phase 6: Daily Plan & Content Recommendation
**Goal:** App generates a personalized daily learning plan that balances new content, review, and skill building.

#### Step 6.1 — Daily Plan Generator
- `PlanGeneratorService.swift`:
  - Input: learner profile, due review items, available media, time goal (15-30 min)
  - Output: ordered list of activities with estimated durations
  - Algorithm:
    1. Schedule overdue SRS reviews first (high priority)
    2. Select 1 new media lesson matching learner's level (85-95% vocabulary coverage)
    3. Add pronunciation practice if pronunciation mastery is lagging
    4. Fill remaining time with vocabulary building or grammar review
  - Respects daily time goal: doesn't overload

**Test:** Plan generation with various learner states: beginner (Hangul focus), intermediate (media + review), heavy review backlog.

#### Step 6.2 — Daily Plan UI
- `DailyPlanView.swift`: Home screen showing today's plan
  - Card for each activity: icon, title, estimated time, type badge
  - Progress bar showing completion
  - "Start next" button that launches the appropriate feature
  - Streak counter (consecutive days)
  - Quick-access to review if items are overdue (badge count)

**Test:** UI state tests: empty plan, partial completion, full completion, streak logic.

**Phase 6 Acceptance:** App opens to a personalized daily plan. Completing activities updates the plan. Streak tracking works. ~15 additional tests.

---

### Phase 7: Onboarding, Placement & Subscription
**Goal:** New users are smoothly onboarded; returning learners are placed accurately; payment works.

#### Step 7.1 — Zero-Knowledge Onboarding
- `OnboardingView.swift`: 4-screen flow
  1. Welcome: "Learn Korean through the media you love" + media type selection (what do you want to understand?)
  2. Experience: "Have you studied Korean before?" → routes to placement or Hangul start
  3. Goal setting: daily time goal (15/20/30 min)
  4. First jamo lesson: immediately teach ㅏ (아) with voice → "You just spoke Korean!"
- Creates `LearnerProfile`, starts Hangul module

**Test:** Flow completion, profile creation, routing logic.

#### Step 7.2 — Adaptive Placement Test
- `PlacementTestView.swift`: For users who select "I know some Korean"
  - IRT-inspired adaptive test: starts at A1, adjusts based on responses
  - 15-20 items covering: Hangul reading, vocabulary recognition, grammar (multiple choice), listening (short clip + question)
  - Uses media-based items (not textbook items)
  - Result: estimated CEFR level + skill breakdown → populates learner profile + skips completed Hangul lessons

**Test:** Adaptive item selection logic, level estimation accuracy with simulated response patterns.

#### Step 7.3 — Auth Flow
- `AuthService.swift`: Supabase Auth integration
  - Sign in with Apple (required for App Store)
  - Email/password fallback
  - Anonymous mode for Hangul free tier (upgrade to account for progress sync)
  - Token refresh, session management

**Test:** Auth state machine tests, token refresh logic.

#### Step 7.4 — Subscription & Paywall
- `SubscriptionService.swift`: StoreKit 2 integration
  - Three tiers: Free, Core ($12.99/mo), Pro ($19.99/mo)
  - Annual pricing options
  - Restore purchases
  - Entitlement checking throughout the app
- `SubscriptionView.swift`: Paywall screen showing tier comparison
- Feature gating: Claude features locked behind Core+, unlimited Claude behind Pro

**Test:** Entitlement checking logic, tier-based feature access, purchase flow (StoreKit testing environment).

**Phase 7 Acceptance:** New users complete onboarding and start learning. Returning learners are placed accurately. Subscriptions work in sandbox. ~25 additional tests.

---

### Phase 8: Progress Tracking & Media Challenges
**Goal:** Users see meaningful progress and receive periodic proficiency assessments.

#### Step 8.1 — Progress Dashboard
- `ProgressDashboardView.swift`:
  - CEFR level indicator with sub-skill breakdown (reading, listening, vocabulary, grammar, pronunciation)
  - "Can-do" milestone list: completed and upcoming (e.g., "Can read a webtoon panel without help")
  - Charts: vocabulary growth over time, daily study minutes, accuracy trends
  - Streak and total study time

**Test:** Data aggregation from study sessions and skill mastery tables.

#### Step 8.2 — CEFR Milestones
- `CEFRMilestoneView.swift`: Define concrete milestones per level
  - Pre-A1: "Can recognize all Hangul characters"
  - A1: "Can understand basic greetings in dramas"
  - A2: "Can follow a heavily scaffolded K-drama clip"
  - B1: "Can follow main plot of a K-drama episode with Korean subtitles"
  - B2: "Can understand K-drama without subtitles for familiar topics"
- Milestones unlock based on learner model thresholds

**Test:** Milestone unlock logic against skill mastery thresholds.

#### Step 8.3 — Media Challenge (Monthly Assessment)
- `MediaChallengeView.swift`: Summative assessment
  - Present unseen media content (no scaffolding)
  - Comprehension questions scored against CEFR rubrics
  - Results compared to learner model predictions → recalibrate if divergent
  - Detailed report: strengths, weaknesses, recommended focus areas

**Test:** Scoring logic, model recalibration, report generation.

**Phase 8 Acceptance:** Progress dashboard shows real data. Monthly challenges assess proficiency. ~15 additional tests.

---

### Phase 9: Offline Support, Polish & Accessibility
**Goal:** App works offline for core features, meets accessibility standards, and is App Store ready.

#### Step 9.1 — Offline Mode
- SwiftData serves as offline cache for: all SRS review items, previously viewed media transcripts, Hangul lesson data, learner profile
- Media downloads: user can download media clips for offline viewing (Supabase Storage → local file)
- Sync: queue operations while offline, sync when connectivity returns
- Claude features gracefully degrade: show cached explanations or "Connect to internet for AI coaching"

**Test:** Offline/online state transitions, queued sync operations, graceful degradation.

#### Step 9.2 — Accessibility
- Full VoiceOver support: all interactive elements have accessibility labels
- Dynamic Type support for all text
- Adjustable playback speed (0.5x–2.0x) for all audio/video
- High contrast mode toggle
- Haptic feedback for pronunciation exercises
- Reduced motion support for stroke animations

**Test:** Accessibility audit using Xcode Accessibility Inspector. VoiceOver navigation test for critical flows.

#### Step 9.3 — Push Notifications (SRS Reminders)
- APNs registration
- Supabase Edge Function sends daily reminder if user has pending reviews
- Notification tapped → opens directly to review session
- User controls: notification time preference, on/off

**Test:** Notification payload construction, deep link routing.

#### Step 9.4 — App Store Preparation
- App icon, launch screen, screenshots
- Privacy policy and terms of service
- App Store description and metadata
- TestFlight beta distribution setup

**Test:** Full smoke test on physical device. App Review guidelines compliance check.

**Phase 9 Acceptance:** App works offline for review and Hangul. WCAG 2.2 AA compliance. Ready for TestFlight. ~20 additional tests.

---

## Testing Strategy

| Test Type | Count Target | Tool | Runs When |
|---|---|---|---|
| Unit tests (models, services, ViewModels) | ~200 | XCTest | Every commit |
| Snapshot tests (key views) | ~30 | swift-snapshot-testing | Every commit |
| Integration tests (Claude, Supabase, ASR) | ~15 | XCTest + test environment | Pre-merge |
| UI tests (critical flows) | ~10 | XCUITest | Pre-release |
| Accessibility audit | Manual + automated | Xcode Inspector | Pre-release |

### Critical Test Scenarios (End-to-End)
1. **New user → first Hangul lesson:** Onboarding → first jamo → stroke practice → pronunciation → spot in wild → review item created
2. **Review session:** Due items appear → user answers → SRS updates → mastery updates → next review scheduled
3. **Media lesson:** Browse library → select content → pre-teach vocab → watch without subs → watch with subs → tap word → Claude explains → comprehension quiz → shadowing → session saved
4. **Daily plan:** App opens → plan generated → user completes activities → plan updates → streak incremented
5. **Subscription upgrade:** Free user hits Claude feature → paywall → purchase → feature unlocks
6. **Offline flow:** Airplane mode → review session works → media lesson degrades gracefully → reconnect → sync

---

## Content Requirements (Minimum Viable)

These are needed before launch but are data/content tasks, not code tasks:

| Content | Minimum Count | Format |
|---|---|---|
| Native speaker jamo recordings | 3 per jamo × 24 = 72 audio files | .m4a, 1-3 sec each |
| Jamo stroke order data | 24 basic + 16 complex = 40 sets | Bezier path arrays (JSON) |
| K-drama clips | 50 segments, 2-5 min each | .mp4 + .srt (Korean) + .srt (English) + metadata JSON |
| Webtoon excerpts | 30 panels/pages | .png + text extraction JSON with bounding boxes |
| News articles | 20 articles | Korean text + English translation + vocabulary tagging |
| Vocabulary list | 2,000 words (media frequency-ranked) | JSON with all fields from schema |
| Grammar patterns | 80 patterns (A1-B2) | JSON with examples and explanations |
| "Spot in Wild" media | 10 annotated screenshots/panels | .png + bounding box JSON |

---

## V1 Scope Boundary — What's IN vs. OUT

### IN (V1)
- Complete Hangul acquisition (stroke order, pronunciation, syllable blocks, spot-in-wild)
- Media library with 5 content types (drama, news, webtoon, short video, music)
- Scaffolded media lesson flow (pre-teach → listen → subtitles → comprehension → vocabulary → shadowing)
- All 5 Claude AI roles (comprehension, pronunciation, grammar, content adapter, cultural)
- SRS with half-life regression
- Learner model with CEFR alignment
- Daily learning plan
- Pronunciation recording + ASR + Claude coaching
- Progress dashboard with CEFR milestones
- Media Challenges (monthly assessment)
- Onboarding (zero-knowledge + placement test)
- Subscription (3 tiers via StoreKit 2)
- Offline support for review and Hangul
- Accessibility (WCAG 2.2 AA)

### OUT (Deferred)
- iPad support → v1.1
- Social features (shared reactions, challenges) → v2
- Writing practice module → v2
- Community-curated content → v2
- Heritage learner specialized pathway → v2
- Advanced TOPIK alignment → v2
- Android → v3
- Other languages (Japanese, Mandarin) → v3+
- B2B licensing → v3+
- Custom Whisper fine-tuning (use Apple Speech Framework in v1)
- Real-time video streaming integration
- User-generated content

---

## Implementation Order Summary

```
Phase 0: Scaffold & Infrastructure          ~1 week     (buildable, testable project)
Phase 1: Hangul Acquisition Engine          ~2 weeks    (free tier complete)
Phase 2: SRS Engine & Learner Model         ~1 week     (review system works)
Phase 3: Media Library & Content Engine     ~1.5 weeks  (content browsable + playable)
Phase 4: Claude AI Integration              ~2 weeks    (all 5 roles functional)
Phase 5: Scaffolded Media Lessons           ~1.5 weeks  (end-to-end lesson flow)
Phase 6: Daily Plan & Recommendations       ~1 week     (personalized home screen)
Phase 7: Onboarding, Placement, Payments    ~1.5 weeks  (acquisition funnel complete)
Phase 8: Progress & Assessments             ~1 week     (progress visible)
Phase 9: Offline, Polish, Accessibility     ~1.5 weeks  (App Store ready)
                                            ─────────
                                            ~14 weeks to testable V1
```

Each phase is independently testable. No phase depends on content licensing being finalized — placeholder content works throughout development.
