# Hallyu Curriculum Content Audit

**Date:** 2026-03-20
**Scope:** Vocabulary, grammar, media content, placement test, SRS content, lesson flow
**App:** Hallyu (iOS Korean language learning app)

## Executive Summary

Hallyu has **strong pedagogical infrastructure** but **thin production content**. The Hangul teaching system is production-ready with complete jamo coverage. Everything else — vocabulary, grammar, media transcripts, placement testing — ranges from skeletal to empty. The app currently functions as an alpha demo, not a shippable course.

| Component | Grade | Production Readiness |
|-----------|-------|---------------------|
| Hangul (Jamo) | **A** | Ready |
| Vocabulary | **D-** | 370-word frequency list exists but 0 learnable items |
| Grammar | **D** | 4 quiz items + 30 detection-only patterns |
| Media Content | **B-** | Placeholder data |
| Placement Test | **C+** | Thin item pool |
| SRS Engine | **B** (engine) / **F** (content) | Engine ready, no cards |
| Lesson Flow | **C** | Structure only |

---

## 1. Hangul System — Grade: A

**File:** `Hallyu/Features/Hangul/HangulData.swift` (699 lines)

### Coverage: 40/40 jamo

| Category | Count | Characters |
|----------|-------|------------|
| Basic Consonants | 14 | ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ |
| Basic Vowels | 10 | ㅏ ㅓ ㅗ ㅜ ㅡ ㅣ ㅑ ㅕ ㅛ ㅠ |
| Double Consonants | 5 | ㄲ ㄸ ㅃ ㅆ ㅉ |
| Compound Vowels | 11 | ㅐ ㅔ ㅒ ㅖ ㅘ ㅙ ㅚ ㅝ ㅞ ㅟ ㅢ |

### Per-jamo data quality

Each entry includes:
- Romanization and IPA transcription
- Stroke-order paths (2-8 `CGPoint` paths in normalized 0-1 coordinate space)
- English mnemonic (e.g., "Gun — looks like a gun pointing right" for ㄱ)
- Position rules (initial/medial/final)
- Audio file reference (e.g., `jamo_giyeok`)

### Lesson progression: 8 groups

| Group | Name | Jamo | Count |
|-------|------|------|-------|
| 0 | First Sounds | ㄱ ㄴ ㄷ ㅏ ㅓ | 5 |
| 1 | Building Blocks | ㄹ ㅁ ㅂ ㅗ ㅜ | 5 |
| 2 | Sibilants & Essentials | ㅅ ㅇ ㅈ ㅡ ㅣ | 5 |
| 3 | Aspirated Sounds | ㅊ ㅋ ㅌ ㅑ ㅕ | 5 |
| 4 | Final Basics | ㅍ ㅎ ㅛ ㅠ | 4 |
| 5 | Double Consonants | ㄲ ㄸ ㅃ ㅆ ㅉ | 5 |
| 6 | Compound Vowels I | ㅐ ㅔ ㅒ ㅖ | 4 |
| 7 | Compound Vowels II | ㅘ ㅙ ㅚ ㅝ ㅞ ㅟ ㅢ | 7 |

Syllable assembly rules: CV and CVC patterns defined.

### Gaps

- **Audio files missing**: All 40 `audioFileRef` values reference files (e.g., `jamo_giyeok`) but the asset directory contains only `.gitkeep`
- **No batchim (받침) rules**: Final consonant sound-change rules (e.g., ㄱ as [k] in final position) are not explicitly taught
- **No syllable combination exercises**: Only 2 assembly rules (CV, CVC) are defined; no practice content for building real syllables

---

## 2. Vocabulary — Grade: D-

**Files:**
- `Hallyu/Core/Models/VocabularyItem.swift` (95 lines) — model definition
- `Hallyu/Core/Utilities/KoreanTextAnalyzer.swift` (lines 26-113) — frequency list for analysis

### Content: 0 learnable vocabulary items, but ~370 words in a frequency list

The `VocabularyItem` model is well-designed (Korean, romanization, English, part of speech, CEFR level, frequency rank, media domains, example sentences, audio URL). **No `VocabularyItem` instances are seeded** — no vocabulary seeder, no JSON data file, no learnable word cards.

However, `KoreanTextAnalyzer` contains a **~370-word frequency list** used for text difficulty analysis. This list covers ranks 1-403 (with some gaps) and includes:
- Ranks 1-50: Particles, pronouns, question words (나, 는, 이, 가, 하다, 있다, 왜, 어디...)
- Ranks 51-100: Common verbs, family, daily life (먹다, 마시다, 친구, 가족, 학교...)
- Ranks 101-200: Nouns, colors, days, numbers (빨간, 파란, 월요일, 하나, 둘...)
- Ranks 201-403: Intermediate vocabulary, body parts, occupations, abstract nouns

**This list is not exposed as learnable content** — it's only used internally by the text analyzer to estimate difficulty scores. The words lack English translations, romanization, example sentences, and part-of-speech tags needed for the `VocabularyItem` model.

### What's missing vs. curriculum expectations

| Category | Expected A1 Words | In Frequency List | As Learnable Items |
|----------|-------------------|-------------------|-------------------|
| Numbers (1-100, ordinals) | ~30 | ~13 (1-10, 100, 1000, 10000) | 0 |
| Colors | ~10 | 5 (빨간, 파란, 하얀, 검은, 노란) | 0 |
| Time (days, months, clock) | ~30 | ~14 (days of week, 아침/점심/저녁) | 0 |
| Family members | ~15 | ~12 (엄마, 아빠, 형, 누나, etc.) | 0 |
| Body parts | ~20 | ~8 (머리, 얼굴, 코, 귀, 손, 발, 다리, 몸) | 0 |
| Food & drink | ~40 | ~3 (밥, 물, 음식) | 0 |
| Greetings & phrases | ~20 | 3 (안녕하세요, 감사합니다, 죄송합니다) | 0 |
| Common verbs | ~50 | ~45 | 0 |
| Common adjectives | ~30 | ~15 | 0 |
| **Total A1 minimum** | **~260** | **~118** | **0** |

For reference, TOPIK I (levels 1-2) expects ~1,500-2,000 words. TOPIK II (levels 3-6) expects ~5,000+.

### Opportunity

The 370-word frequency list is a good starting point but needs to be transformed into `VocabularyItem` instances with translations, romanization, example sentences, and CEFR tagging.

### Risk

Without offline vocabulary items, the app is entirely API-dependent for vocabulary teaching. If Claude is unavailable, users have zero learnable vocabulary content.

---

## 3. Grammar — Grade: D

**Files:**
- `Hallyu/Core/Models/GrammarPattern.swift` (93 lines) — model definition
- `Hallyu/Features/Feed/FeedCardGenerator.swift` lines 244-248 — quiz card data
- `Hallyu/Core/Utilities/KoreanTextAnalyzer.swift` lines 116-147 — detection patterns

### Teachable content: 4 hardcoded grammar quiz items

| Pattern | Example | Translation | CEFR | Has Explanation? | Has Common Mistakes? |
|---------|---------|-------------|------|-----------------|---------------------|
| -아/어요 | 맛있어요 | It's delicious | A1 | No | No |
| -고 싶다 | 가고 싶어요 | I want to go | A2 | No | No |
| -(으)ㄴ데 | 비가 오는데 | It's raining, but... | B1 | No | No |
| -았/었- | 먹었어요 | I ate | B1 | No | No |

These exist only as quiz card data in `FeedCardGenerator.makeGrammarSnap()`. No `GrammarPattern` model instances are ever created or persisted.

### Detection patterns: 30 patterns in KoreanTextAnalyzer

The text analyzer has 30 grammar pattern strings used for **difficulty detection only** (not teaching):

| CEFR | Patterns | Count |
|------|----------|-------|
| A1 | -이에요/예요, -입니다, -습니다/ㅂ니다, -아/어요, -세요, -고 싶 | 8 |
| A2 | -을 수 있, -아/어서, -지만, -으면, -고 있, -는데, -을까요, -아/어야 하 | 12 |
| B1 | -는 것 같, -기 때문에, -도록, -으려고, -더라고요, -잖아요, -거든요 | 7 |
| B2 | -다면, -더니, -는 바람에 | 3 |

These contain only pattern strings and names — no explanations, examples, or common mistakes. They would need significant enrichment to become teachable grammar content.

### What's missing vs. CEFR/TOPIK expectations

**A1 (TOPIK I Level 1)** — need ~15-20 teachable patterns, have 1 quiz item:
- Subject/topic markers (은/는, 이/가) — in analyzer, not teachable
- Object marker (을/를)
- Location particles (에, 에서)
- Possessive (의)
- Copula (이에요/예요) — in analyzer, not teachable
- Negation (안, -지 않다)
- Want to (-고 싶다) ✓ quiz item
- Can/cannot (-을 수 있다/없다)
- Present tense (-아/어요) ✓ quiz item

**A2 (TOPIK I Level 2)** — need ~15-20 more patterns, have 0 quiz items:
- Past tense (-았/었-) — exists in B1 quiz slot, should be A2
- Future (-을 거예요) — missing entirely
- Progressive (-고 있다) — in analyzer, not teachable
- Honorifics (-세요) — in analyzer, not teachable
- Connectives (-고, -지만, -어서) — in analyzer, not teachable

**B1-B2 (TOPIK II)** — need ~30+ patterns, have 2 quiz items:
- Conditional (-으면) — in analyzer, not teachable
- Reason (-기 때문에) — in analyzer, not teachable
- Contrast (-(으)ㄴ데) ✓ quiz item
- Reported speech (-다고 하다) — missing entirely
- Passive voice (-되다, -아/어지다) — missing entirely

### Opportunity

The 30 analyzer patterns are a skeleton that could be enriched into `GrammarPattern` instances with explanations, examples, and common mistakes.

### Risk

Grammar explanations are generated entirely by Claude API at runtime. There is no fallback, no quality control over what gets generated, and no way to ensure consistent pedagogical sequencing.

---

## 4. Media Content — Grade: B-

**File:** `Hallyu/Features/MediaLibrary/MediaContentSeeder.swift` (323 lines)

### Inventory

| Type | Count | CEFR Levels | Transcript Quality |
|------|-------|-------------|-------------------|
| K-Drama clips | 50 | A1(4), A2(3), B1(3) × 5 variations | Full segmentation with timestamps |
| Webtoon excerpts | 30 | A1(3), A2(4), B1(3) × 3 chapters | Single Korean line, no segmentation |
| News articles | 20 | A1(2), A2(3), B1(3), B2(1) + follow-ups | Paragraph text, no timestamps |
| Short videos | 10 | A1(5), A2(4), B1(1) | Single segment stub |
| Music clips | 10 | A1(3), A2(4), B1(3) | Lyrics line only |
| **Total** | **120** | | |

### CEFR distribution (base scenarios, before variations)

| Level | Drama | Webtoon | News | Video | Music | Total | % |
|-------|-------|---------|------|-------|-------|-------|---|
| A1 | 4 | 3 | 2 | 5 | 3 | 17 | 34% |
| A2 | 3 | 4 | 3 | 4 | 4 | 18 | 36% |
| B1 | 3 | 3 | 3 | 1 | 3 | 13 | 26% |
| B2 | 0 | 0 | 1 | 0 | 0 | 1 | 2% |
| **Total** | 10 | 10 | 9 | 10 | 10 | **49** | |

### Strengths

- Drama clips have proper transcript segmentation with start/end millisecond timestamps and bilingual text
- Cultural notes on every drama clip (e.g., "Bargaining is common in traditional Korean markets")
- Good scenario variety: greetings, shopping, cafe, family, workplace, school, confession, hospital, farewell, food
- Real K-drama and webtoon titles used (Goblin, Reply 1988, Crash Landing on You, Solo Leveling, etc.)

### Gaps

- **B2 content nearly absent**: Only 1 news article at B2 (Korean economy). A learner progressing past B1 hits a wall
- **50 drama clips are 10 base scenarios × 5 mechanical variations** (Part 1-5) with same transcript — not genuinely different content
- **Webtoon transcripts are single sentences**: "별을 보고 싶어. 하늘이 보고 싶어." — not enough for a lesson
- **Short video segments are stubs**: Each has exactly 1 segment with empty English translation (`textEn: ""`)
- **Music clips have no segmentation**: Single lyrics line, no word-level timestamps for karaoke/shadowing
- **All video URLs are placeholder** (BigBuckBunny.mp4, ElephantsDream.mp4, etc.) — not actual Korean content
- **No vocabulary extraction**: Media content doesn't pre-tag which vocabulary items appear in each transcript

---

## 5. Placement Test — Grade: C+

**File:** `Hallyu/Features/Onboarding/PlacementTestViewModel.swift` (305 lines)

### Item pool: 18 items (max 12 per session)

| Type | A1 | A2 | B1 | B2 | Total |
|------|----|----|----|----|-------|
| Hangul Reading | 3 | 0 | 0 | 0 | 3 |
| Vocabulary Recognition | 2 | 2 | 2 | 2 | 8 |
| Grammar MC | 1 | 2 | 1 | 1 | 5 |
| Listening Comprehension | 1 | 1 | 0 | 0 | 2 |
| **Total** | **7** | **5** | **3** | **3** | **18** |

### Strengths

- Adaptive IRT-inspired algorithm adjusts difficulty based on correctness and response time
- Speed thresholds: <4.5s = fast bonus, >12s = penalty
- Rebalances remaining items after each answer
- Clean level estimation with weighted readiness scoring

### Gaps

- **Too few items for statistical validity**: 18-item pool with 12-item sessions means most items always appear
- **Only 2 listening items**: Cannot reliably assess listening comprehension
- **No pre-A1 items**: Complete beginners (can't read Hangul) start with A1 Hangul reading questions
- **No production items**: All items are recognition/multiple-choice. No typing, speaking, or writing
- **Audio clips referenced but likely missing**: `greeting_a1` and `request_a2` audio files not verified in assets
- **Hangul reading only at A1**: No progressive Hangul assessment (individual jamo → syllables → words)

### Recommendation

A robust placement test needs 30-50 items minimum, with at least 5 per level per skill type, to achieve reliable classification.

---

## 6. SRS Engine — Grade: B (engine) / F (content)

**File:** `Hallyu/Core/Services/SRSEngine.swift` (85 lines)

### Engine quality: Solid

- Exponential decay model: `P(recall) = 2^(-elapsed / halfLife)`
- Half-life grows 2× on correct, shrinks 0.5× on incorrect
- Speed bonus (1.1×) for responses under 3 seconds
- Minimum interval: 6 hours after incorrect, ~1 hour for re-presentation
- Priority sorting by recall probability (most overdue first)
- Session retry for incorrect items

### Content gaps

- **Zero flashcard templates**: No predefined card formats (front/back layouts, cloze deletions, audio cards)
- **Zero review exercises**: No fill-in-the-blank, matching, or sentence construction exercises
- **No card generation rules**: No definition of how vocabulary/grammar items become review cards
- The engine is a pure scheduling algorithm with no content to schedule

---

## 7. Lesson Flow — Grade: C

**Files:** `FeedCardGenerator.swift`, various ViewModel files

### Card types defined: 7

1. **Jamo Watch/Trace/Speak** — uses HangulData (content exists)
2. **Media Clip** — uses MediaContentSeeder (placeholder content)
3. **Vocabulary** — pulls from ReviewItems (no seeded items)
4. **Grammar Snap** — 4 hardcoded quiz items
5. **Pronunciation** — extracted from media segments (depends on transcripts)
6. **Listen-and-Choose** — generated from media segments with distractors
7. **Cultural Moment** — 6 hardcoded facts + media cultural notes

### Cultural facts (all 6 in the app)

1. Age Matters — age determines speech formality
2. Honorific Speech — 7 speech levels
3. Kimchi Varieties — 200+ types
4. Soju Culture — drinking etiquette
5. Korean Names — surname distribution (Kim/Lee/Park = 45%)
6. Fan Death — cultural superstition

### Gaps

- **No lesson sequencing**: Post-Hangul lessons are entirely generated by card scheduling intervals, not a pedagogical sequence
- **No explicit skill progression**: No definition of "after learning X, teach Y"
- **No offline lesson content**: If Claude API is down, users can only do Hangul and media playback
- **Listen-and-choose distractors are weak**: Falls back to generic English phrases ("Thank you", "Hello, how are you?") when insufficient media segments exist

---

## 8. CEFR Coverage Matrix

Content availability by level (items that actually exist in the codebase):

| Component | Pre-A1 | A1 | A2 | B1 | B2 |
|-----------|--------|----|----|----|----|
| Hangul | N/A | N/A | N/A | N/A | N/A |
| Vocabulary (learnable items) | 0 | 0 | 0 | 0 | 0 |
| Vocabulary (frequency list, analysis only) | 0 | ~120 | ~80 | ~170 | 0 |
| Grammar (quiz items) | 0 | 1 | 1 | 2 | 0 |
| Grammar (detection patterns, not teachable) | 0 | 8 | 12 | 7 | 3 |
| Media content (base) | 0 | 17 | 18 | 13 | 1 |
| Placement items | 0 | 7 | 5 | 3 | 3 |
| Cultural facts | 0 | 6 | 6 | 6 | 6 |
| SRS cards | 0 | 0 | 0 | 0 | 0 |

---

## 9. Prioritized Recommendations

### P0 — Critical (app is non-functional without these)

1. **Convert the 370-word frequency list into learnable `VocabularyItem` instances** with English translations, romanization, example sentences, and CEFR tags. Then expand to 500+ items covering gaps (food, directions, more numbers, months).

2. **Enrich the 30 analyzer grammar patterns into teachable `GrammarPattern` instances** with explanation text, 2-3 example sentences with translations, common mistakes, and formality level. Then expand to 40+ patterns covering gaps (reported speech, passive voice, future tense).

3. **Add offline fallback content** for grammar and vocabulary so the app functions without Claude API.

### P1 — Important (app is shallow without these)

4. **Add B1-B2 media content**: Currently 70% of content is A1-A2. Need at least 20 base scenarios at B1 and 10 at B2.

5. **Improve transcript quality**: Webtoons need multi-sentence narratives with segmentation. Short videos need English translations. Music needs word-level or line-level timestamps.

6. **Expand placement test to 30+ items** with at least 5 listening items and items at every level including pre-A1.

### P2 — Nice to Have

7. **Add audio assets** for all 40 jamo pronunciation files.

8. **Create flashcard templates** and review exercise types (cloze deletion, sentence reordering, matching).

9. **Add batchim (final consonant) sound-change rules** to the Hangul curriculum.

10. **Tag media content with vocabulary items** so pre-teaching can pull from a known word list rather than relying on runtime extraction.

---

## 10. Conclusion

Hallyu's architecture is well-thought-out — the data models, SRS engine, adaptive placement test, and media-first lesson flow demonstrate strong pedagogical design. The gap is purely **content**. The app has the engine but almost no fuel:

- **0 learnable vocabulary items** — a 370-word frequency list exists in the analyzer but isn't exposed as teachable content (need 500+ `VocabularyItem` instances)
- **4 grammar quiz items** — 30 detection patterns exist in the analyzer but lack explanations/examples (need 40+ teachable `GrammarPattern` instances)
- **1 B2 media item** (need 10+ for level progression)
- **18 placement items** (need 30+ for reliable assessment)

Filling these gaps is a data problem, not an architecture problem. The models and infrastructure are ready to handle thousands of items.
