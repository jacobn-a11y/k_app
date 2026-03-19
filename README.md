*Learn Korean Through the Media You Love*

**Product Requirements Document**
Version 1.0 · March 2026
Platform: iOS (iPhone)

---

## 1. Executive Summary

Hallyu is a Korean-language learning iPhone app purpose-built for adults who want to consume Korean media in its original language. Unlike general-purpose language apps that teach Korean through abstract grammar drills and decontextualized vocabulary, Hallyu uses authentic Korean media—books, news articles, films, TV dramas, and short-form video—as the primary instructional material. The app assumes zero prior knowledge of Korean, starting with Hangul acquisition, and progressively builds the learner toward independent media consumption at CEFR B2 and beyond.

The product differentiates itself through three pillars: a media-first curriculum spine where every lesson is anchored to real Korean content; a Claude AI integration that serves as an adaptive comprehension coach rather than a generic chatbot; and a voice-driven pronunciation system that builds production skills from the first session. Hallyu is not an LLM wrapper—Claude powers specific, constrained pedagogical functions within a structured learning architecture grounded in second language acquisition research.

---

## 2. Problem Statement

### 2.1 The Gap in the Market

The global language learning market is projected to exceed USD 101.5 billion in 2026, yet Korean learners face a paradox: massive cultural demand driven by K-drama, K-pop, webtoons, and Korean cinema, but no app that directly bridges the gap between wanting to understand Korean media and actually being able to do so. Existing solutions fall into three categories, all of which fail the Korean media learner:

- **General-purpose gamified apps (Duolingo, Babbel):** These teach Korean as a generic foreign language with scripted dialogues and artificial scenarios. They rarely reach beyond CEFR A2–B1 for Korean and do not incorporate authentic media at all. Duolingo's recognition-based methodology and hearts system actively work against the deep, sustained engagement required for a writing system as unfamiliar as Hangul.

- **Content-consumption tools (Lingopie, Language Reactor):** These overlay translation features onto existing streaming platforms. They serve intermediate learners who can already read Korean but offer no Hangul instruction, no structured grammar progression, no pronunciation practice, and no adaptive review. They are supplements, not learning systems.

- **AI conversation apps (Speak, TalkPal, Langua):** These provide open-ended speaking practice powered by LLMs but lack structured curricula, media integration, and writing-system instruction. Their free-form conversation model is poorly suited for absolute beginners who cannot yet decode the Korean alphabet.

### 2.2 The User's Actual Goal

The target user does not want to "learn Korean" in the abstract. They want to understand what their favorite K-drama characters are saying, read webtoon dialogue without fan translations, follow Korean news coverage, and engage with Korean YouTube and TikTok content. Their motivation is identity-driven—aligned with L2 Motivational Self System research showing that a vivid "ideal L2 self" consuming Korean media is a powerful sustained motivator—but no product currently converts that motivation into a structured learning pathway.

---

## 3. Target User

### 3.1 Primary Persona

| Attribute | Detail |
|---|---|
| Age | 22–45 |
| Location | United States, Canada, UK, Australia (English-speaking markets) |
| Korean proficiency | Absolute beginner (cannot read Hangul) through false beginner (knows some words from media exposure but no formal study) |
| Motivation | Consume Korean media without subtitles/translations: K-drama, K-pop lyrics, webtoons, news, YouTube/TikTok |
| Learning context | Self-directed, mobile-first, 15–30 minutes per day on commute or during downtime |
| Tech comfort | High; regularly uses streaming apps, social media, and content platforms |
| Frustration with existing tools | Duolingo feels childish and disconnected from real Korean; pure AI chat is overwhelming without a foundation; subtitle tools require literacy they don't have |

### 3.2 Secondary Personas

- **Heritage learners:** Korean-Americans or diaspora speakers who understand spoken Korean at a basic level but cannot read or write. They need Hangul literacy and formal grammar to bridge conversational knowledge to media literacy.

- **Intermediate learners stalled at B1:** Users who have completed Duolingo's Korean tree or similar courses but cannot understand native-speed media. They need the bridge from textbook Korean to authentic content.

---

## 4. Product Vision and Differentiation

### 4.1 Core Product Philosophy

Hallyu operates on a single organizing principle: every unit of instruction exists to move the learner closer to independently consuming a specific piece of Korean media. This is not a language app that occasionally references Korean culture—it is a media consumption trainer that teaches language as the means to that end. The learning science research is clear: adults learn best when instruction is problem-centered, immediately relevant, and anchored to authentic materials. Hallyu operationalizes this by making real Korean content the curriculum itself.

### 4.2 Competitive Differentiation Matrix

| Dimension | Duolingo | Lingopie / Language Reactor | Speak / TalkPal | Hallyu |
|---|---|---|---|---|
| Hangul instruction | Basic, linear | None | None | Systematic stroke-order with voice-guided production from day one |
| Curriculum anchor | Scripted dialogues | Streaming video catalog | Open-ended conversation | Curated authentic Korean media across five content types |
| Grammar progression | Implicit, slow | None (reference only) | Emergent from conversation | Explicit focus-on-form embedded within media-based tasks |
| Pronunciation | Basic speech recognition | None | ASR with general feedback | Phoneme-level feedback using HVPT principles + Claude coaching |
| AI role | Explain My Answer (reactive) | None | Core conversation engine | Constrained comprehension coach, pronunciation tutor, and content adapter |
| Beginner accessibility | Yes (gamified) | No (requires literacy) | Partial (speaking only) | Yes (Hangul-first onboarding, zero assumed knowledge) |
| Media integration | None | Netflix/YouTube overlay | None | Native media library with scaffolded comprehension tasks |
| Adaptive review | Basic SRS | Manual flashcards | None | ML-driven spacing with half-life regression across all skill types |

---

## 5. Feature Requirements

### 5.1 Hangul Acquisition Engine (Weeks 1–2)

#### 5.1.1 Rationale

Korean uses a unique alphabetic-syllabic writing system (Hangul) with 14 basic consonants, 10 basic vowels, and systematic syllable-block construction. Unlike Chinese or Japanese, Hangul is fully decodable once learned—making it the single highest-leverage early investment. No existing app treats Hangul acquisition with the rigor it deserves for a media-consumption goal: learners need not just letter recognition but rapid syllable-block decoding, because Korean media presents text in blocks, not isolated letters.

#### 5.1.2 Requirements

- **Stroke-order animation:** Each jamo (letter) presented with animated stroke order, spatial positioning within the syllable block, and audio pronunciation by multiple native speakers (high-variability phonetic training principle).

- **Voice-first learning:** From the first screen, the learner speaks each jamo aloud. The app uses ASR to provide real-time phoneme-level feedback, comparing the learner's production against native speaker models. Feedback is visual (waveform overlay and color-coded phoneme accuracy) and corrective ("Your ㅎ sounds closer to an English H—try pushing more air from the throat" via Claude).

- **Syllable-block assembly:** Interactive exercises where learners drag jamo into syllable-block positions (initial, medial, final) and then pronounce the resulting syllable. Immediate feedback on both construction accuracy and pronunciation.

- **Media connection:** Each jamo lesson concludes with a "Spot it in the wild" micro-task: a 5-second clip from a K-drama or a webtoon panel where the target jamo appears in context. The learner taps the jamo they recognize. This establishes the media-first identity from session one.

- **Spaced retrieval:** All learned jamo and syllable blocks enter the adaptive SRS immediately. Review sessions interleave recognition (see block → produce sound) with production (hear sound → construct block).

### 5.2 Media Library and Content Engine

#### 5.2.1 Content Types

| Content Type | Source Examples | Scaffolding Approach | CEFR Range |
|---|---|---|---|
| Books | Webtoon dialogue, graded readers, modern fiction excerpts | Sentence-by-sentence gloss with tap-to-reveal vocabulary; Claude provides contextual grammar explanations on demand | A2–C1 |
| News | Naver News, KBS, Hankyoreh (curated articles) | Paragraph-level comprehension tasks; headline decoding exercises; vocabulary pre-teaching with media-frequency word lists | B1–C1 |
| Movies / TV | Licensed K-drama clips, film scenes (2–5 min segments) | Listen-first with no subtitles → Korean subtitles → comprehension questions → vocabulary extraction into SRS → shadowing practice | A2–B2+ |
| Short-form video | Korean YouTube, TikTok-style content (30–90 sec) | Speed-adjusted playback; slang and colloquial glossary; Claude explains cultural context and register | B1–C1 |
| Music / Lyrics | K-pop songs with official lyrics | Line-by-line lyric breakdown; pronunciation shadowing; grammar pattern identification within song structure | A2–B2 |

#### 5.2.2 Content Progression Logic

Content is not organized by textbook chapter but by media difficulty tier, determined by a composite score of lexical frequency coverage, syntactic complexity, speech rate (for audio/video), and topic familiarity. The learner's model (see Section 5.5) determines which content appears in their daily plan. A K-drama scene with 85% vocabulary coverage for that learner is a comprehensible-input match; one with 60% coverage is flagged as a stretch challenge with heavier scaffolding.

### 5.3 Claude AI Integration

#### 5.3.1 Design Philosophy: Coach, Not Wrapper

Claude is integrated as a pedagogical agent with clearly defined roles, not as an open-ended conversational partner. Every Claude interaction is triggered by a specific learning context and constrained by pedagogical guardrails. The user never sees a blank chat prompt—Claude surfaces when the learner needs it, within the structure of a lesson or media task.

#### 5.3.2 Claude's Five Roles

**Role 1: Comprehension Coach.** When consuming media content, the learner can highlight any word, phrase, or sentence and invoke Claude for an explanation. Claude provides: the literal meaning, the contextual meaning in this specific scene/passage, the grammar pattern at work, a simpler example of the same pattern, and a note on register or formality level. Claude does not provide a generic dictionary entry—it explains this usage in this context, drawing on the surrounding content.

**Role 2: Pronunciation Tutor.** After the learner records a pronunciation attempt, Claude analyzes the ASR output and provides targeted corrective feedback. Rather than a simple accuracy score, Claude identifies the specific articulatory issue ("Your ㅇ in final position is dropping—Korean final ㅇ should nasalize clearly, unlike the silent NG you might expect") and provides a focused drill. This implements the explicit corrective feedback approach that meta-analyses show is more effective than implicit recasts for adult learners.

**Role 3: Grammar Explainer (On-Demand).** When the learner encounters a grammar pattern in media, they can request a Claude explanation. Claude provides a concise rule statement, a contrastive example showing how the pattern differs from a similar one the learner has already studied, and a retrieval question to immediately test understanding. Explanations are brief (cognitive load management) and always reference the media context that triggered the question.

**Role 4: Content Adapter.** Claude generates supplementary practice items anchored to the media the learner just consumed. After watching a K-drama clip about a job interview, Claude might generate: a fill-in-the-blank exercise using the formal speech level from the scene, a role-play prompt where the learner practices the same register, and comprehension questions that test inference rather than literal recall. This is generative AI used for item generation within a structured pedagogical framework—not free-form chat.

**Role 5: Cultural Context Interpreter.** Korean media is dense with cultural references, honorific social dynamics, and context-dependent meaning. When the learner flags a confusing moment ("Why did everyone gasp when she used that word?"), Claude explains the cultural context: speech level violations, age-based honorific expectations, slang connotations, or historical/pop-culture references. This directly supports the sociolinguistic competence that distinguishes real media comprehension from textbook translation.

#### 5.3.3 Claude Integration Constraints

- **No blank chat interface:** Claude is always invoked from within a learning activity with full context about what the learner is studying, their proficiency model, and the specific media content.

- **Response length limits:** Explanations are capped at approximately 150 words for in-context glosses and 300 words for grammar explanations. Brevity is a pedagogical requirement, not a cost-saving measure.

- **Retrieval-first design:** Before providing an explanation, Claude first prompts the learner to attempt their own interpretation ("What do you think this sentence means based on the context?"). This implements retrieval practice before feedback, which research shows strengthens retention.

- **Confidence calibration:** Claude signals its own uncertainty when appropriate ("This slang is very recent and its meaning may vary by context") rather than presenting every explanation with equal confidence. This models metacognitive awareness for the learner.

### 5.4 Voice and Pronunciation System

#### 5.4.1 Architecture

The pronunciation system operates at three levels that correspond to the learner's progression from Hangul acquisition through media shadowing:

**Level 1 – Phoneme Production (Weeks 1–4):** Individual jamo sounds, minimal pairs (e.g., ㄱ vs. ㅋ, ㄷ vs. ㅌ, ㅂ vs. ㅍ), and syllable-block pronunciation. ASR provides phoneme-level accuracy scoring. Claude provides articulatory coaching when accuracy is below threshold. High-variability phonetic training is implemented by presenting each target phoneme spoken by 8–12 different native speakers of varying age, gender, and regional accent.

**Level 2 – Word and Phrase Production (Weeks 3–12):** Multi-syllable words, common phrases, and sentences extracted from media content. The system evaluates not just phoneme accuracy but also prosody (intonation patterns), rhythm, and connected-speech phenomena (liaison, aspiration changes). Shadowing exercises present a native speaker model, the learner records, and the app displays a waveform comparison.

**Level 3 – Media Shadowing (Week 8+):** The learner shadows actual dialogue from K-drama scenes, news broadcasts, or YouTube clips. The system provides segment-by-segment comparison and tracks fluency metrics (speech rate, pause frequency, hesitation markers) over time. Claude provides coaching on natural rhythm and connected speech patterns specific to the media genre.

#### 5.4.2 ASR Fairness and Inclusivity

Research documents significant bias in commercial ASR systems against non-native speakers and speakers of certain accents. Hallyu addresses this through three mechanisms: the pronunciation scoring model is trained on a corpus that includes non-native Korean speakers at various proficiency levels (not just native speakers); scoring targets intelligibility rather than native-likeness; and learners always have access to a "Manual review" option where Claude provides qualitative feedback based on the transcription rather than a binary pass/fail score.

### 5.5 Adaptive Learning Engine

#### 5.5.1 Learner Model

The learner model maintains per-skill mastery estimates across a granular skill map that includes: individual vocabulary items (with frequency and media-domain tags), grammar constructions (mapped to CEFR levels), phoneme contrasts, Hangul recognition and production, reading comprehension by content type, and listening comprehension by speech rate and register. Each skill has three tracked dimensions: accuracy (can the learner get it right?), speed (can they get it right quickly, indicating automaticity?), and retention (can they still get it right after a delay?).

#### 5.5.2 Adaptive Spacing

Review scheduling uses a half-life regression model that predicts memory strength for each item based on the learner's history of correct and incorrect retrievals, time since last review, and item difficulty. The scheduler operates on two loops: a within-session fast loop that re-presents errors and near-threshold items during the current study session, and an across-days slow loop that schedules review sessions across days and weeks with expanding intervals calibrated to each item's predicted half-life.

#### 5.5.3 Content Recommendation

The daily learning plan is generated by combining the learner's model with available media content. The algorithm selects media segments that maximize comprehensible input coverage (targeting 85–95% known-vocabulary coverage per segment) while introducing vocabulary and grammar constructions that are next in the learner's progression. This ensures that every media session is both enjoyable (mostly comprehensible) and instructionally productive (introduces new material at the right dosage).

### 5.6 Onboarding and Placement

#### 5.6.1 Zero-Knowledge Onboarding (Default Path)

The default onboarding assumes the learner cannot read Hangul and has no formal Korean study. The first session immediately teaches the five most common vowels through a voice-first interaction: the learner hears each vowel, sees the jamo with stroke-order animation, and records their own production. Within 15 minutes, the learner has spoken Korean, seen their pronunciation scored, and spotted their first Hangul characters in a K-drama clip. This is designed to deliver an "I can do this" moment that research on competence motivation shows is critical for initial engagement.

#### 5.6.2 Adaptive Placement (Returning Learners)

Learners with prior Korean knowledge take an adaptive placement assessment using IRT-based item selection that efficiently estimates their proficiency across reading, listening, vocabulary, and grammar. The assessment uses media-based items (comprehension questions from K-drama clips, vocabulary from news articles) so that placement accuracy reflects the user's actual ability to process authentic content, not their ability to complete textbook exercises.

### 5.7 Assessment and Progress

#### 5.7.1 Continuous Formative Assessment

Every interaction is a measurement event. Comprehension questions after media segments, vocabulary retrievals during SRS sessions, pronunciation recordings, and grammar exercises all feed the learner model. The learner sees their progress through CEFR-aligned "can-do" milestones rather than arbitrary point totals. For example: "You can now understand the main plot of a K-drama episode with Korean subtitles" (B1 listening) or "You can read a Naver News headline and predict the article's topic" (B1 reading).

#### 5.7.2 Periodic Proficiency Checkpoints

Monthly "Media Challenges" serve as summative assessments: the learner watches a new, unseen K-drama scene or reads a fresh news article and completes a structured comprehension task without scaffolding. Performance is scored against CEFR-aligned rubrics and compared to the learner's model predictions to recalibrate the system.

---

## 6. User Journey: First 30 Days

| Timeframe | Focus | Key Activities | Milestone |
|---|---|---|---|
| Days 1–3 | Hangul vowels + first consonants | Voice-guided jamo learning; stroke-order practice; "Spot it in the wild" K-drama micro-tasks; first SRS entries | Can recognize and pronounce 10 jamo; has spoken Korean aloud |
| Days 4–7 | Complete Hangul + basic syllable blocks | All 24 basic jamo; syllable-block assembly exercises; minimal-pair pronunciation drills; first complete word readings from webtoon panels | Can decode any basic Korean syllable block; reads simple words |
| Days 8–14 | First media immersion + core vocabulary | First K-drama clip (30 sec, heavy scaffolding); 100 most frequent media words via SRS; basic sentence patterns through media examples; daily pronunciation shadowing | Can follow a heavily scaffolded K-drama clip; knows 100 high-frequency words |
| Days 15–21 | Expanding comprehension + grammar foundations | Longer media clips (1–2 min); introduction of speech levels (formal/informal); news headline decoding; Claude grammar explanations on demand | Can identify formal vs. informal speech in dramas; reads simple news headlines |
| Days 22–30 | Independent media sampling + first checkpoint | Self-selected media content from library; first unsupported comprehension attempt; Media Challenge assessment; personalized review plan generated | Completes first Media Challenge; has a calibrated learner model; daily habit established |

---

## 7. Technical Architecture

### 7.1 Platform

- **Target:** iOS 17+ (iPhone). iPad support in v1.1.
- **Language:** Swift / SwiftUI for native performance, particularly for audio recording and playback.
- **Offline capability:** Core SRS reviews, previously downloaded media clips, and Hangul exercises function offline. Claude features and new media content require connectivity.

### 7.2 AI and ML Stack

| Component | Technology | Purpose |
|---|---|---|
| LLM Integration | Claude API (Anthropic) | Comprehension coaching, pronunciation feedback, grammar explanation, content adaptation, cultural context |
| Speech Recognition | Apple Speech Framework (`ko-KR`) | On-device transcription + confidence scoring for pronunciation and shadowing feedback |
| Spacing Algorithm | Custom half-life regression model | Adaptive SRS scheduling based on individual forgetting curves |
| Content Difficulty | Custom NLP pipeline (morphological analysis + frequency scoring) | Media difficulty tiering and learner-content matching |
| Learner Model | Bayesian knowledge tracing | Per-skill mastery estimation with uncertainty quantification |

### 7.3 Content Pipeline

Media content is licensed or sourced through partnerships with Korean content distributors. Each piece of content passes through an ingestion pipeline that segments video/audio into pedagogically useful clips (scene-level for drama, paragraph-level for text), runs morphological analysis to tag vocabulary and grammar constructions, computes a difficulty score, and generates metadata for the recommendation engine. Claude is used in the pipeline to generate supplementary exercises and cultural context annotations that are human-reviewed before publication.

---

## 8. Monetization Strategy

| Tier | Price | Includes |
|---|---|---|
| Free (Hangul Starter) | $0 | Complete Hangul acquisition engine (Weeks 1–2); limited media library (3 curated clips per content type); basic SRS; pronunciation practice without Claude coaching |
| Hallyu Core | $12.99/month or $99.99/year | Full media library access; Claude comprehension coach and grammar explainer; advanced pronunciation with Claude coaching; adaptive learning engine; all content types |
| Hallyu Pro | $19.99/month or $149.99/year | Everything in Core; unlimited Claude interactions; Media Challenges with detailed proficiency reports; priority access to new content; downloadable media for offline study |

The free tier is designed as a complete Hangul learning experience that delivers genuine value and establishes the voice-first, media-anchored identity of the product. Conversion to paid tiers is driven by the learner's desire to continue consuming media content beyond the starter library—a natural, motivation-aligned upgrade trigger rather than an artificial paywall.

---

## 9. Success Metrics

### 9.1 Learning Outcomes (Primary)

- **Hangul literacy rate:** 90%+ of learners who complete the Hangul module can decode novel syllable blocks with >85% accuracy within 14 days.
- **Media comprehension progression:** Median learner achieves "can follow main plot of a scaffolded K-drama episode" (B1 listening) within 90 days of daily use.
- **Vocabulary retention:** 80%+ recall rate at 30-day intervals for items that have passed through the SRS cycle, measured via unannounced retrieval probes.
- **Pronunciation intelligibility:** Median learner achieves "intelligible to native speakers" rating on standardized sentences within 60 days.

### 9.2 Engagement Metrics (Secondary)

- **Day-7 retention:** >50% (benchmark: Duolingo ~45%).
- **Day-30 retention:** >30%.
- **Daily active time:** Median 18+ minutes per session.
- **SRS return rate:** >70% of users with pending reviews return within 24 hours of notification.
- **Free-to-paid conversion:** >8% within 30 days of Hangul module completion.

---

## 10. Accessibility and Inclusivity

Hallyu is designed to WCAG 2.2 AA standards with the following specific commitments: full VoiceOver support for all interactive elements including the Hangul stroke-order animations; adjustable playback speed for all audio and video content (0.5x–2.0x); high-contrast mode and customizable font sizing for all text-based content; haptic feedback as a complement to audio cues for pronunciation exercises; and alternative input methods for learners who cannot use voice recording (text-based pronunciation exercises using romanization with explicit notation that this is a scaffolding step, not a target skill).

---

## 11. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Korean media licensing costs and availability | High | Begin with webtoon dialogue (more accessible licensing), Korean Creative Content Agency partnerships, and user-generated content curation for short-form video. Phase in premium drama/film licensing as revenue scales. |
| ASR accuracy for beginner Korean speakers | High | Use Apple Speech confidence thresholds to gate feedback quality; when confidence is low, fall back to Claude qualitative coaching and "hear the model" replay prompts. |
| Claude API costs at scale | Medium | Cache common explanations for high-frequency vocabulary and grammar patterns; use Claude for novel contexts only; implement response-length constraints; monitor cost-per-active-user monthly. |
| Content pipeline bottleneck | Medium | Automate morphological analysis and difficulty scoring; use Claude for first-draft exercise generation with human review; build internal tools for rapid content annotation. |
| Learner drop-off after Hangul module | Medium | Ensure the transition from Hangul to media consumption is seamless (first drama clip appears in Week 2); use the free tier as a complete Hangul experience that naturally leads to paid media access. |

---

## 12. Phased Roadmap

| Phase | Timeline | Scope |
|---|---|---|
| Phase 1: Foundation | Q2–Q3 2026 | Hangul engine, core SRS, Claude comprehension coach, initial media library (50 curated K-drama clips, 30 webtoon excerpts, 20 news articles), pronunciation system Levels 1–2, iOS app launch |
| Phase 2: Expansion | Q4 2026–Q1 2027 | Full media library expansion (200+ clips per content type), short-form video integration, music/lyrics module, Media Challenges, social features (shared media reactions, pronunciation challenges), pronunciation Level 3 (media shadowing) |
| Phase 3: Maturation | Q2–Q3 2027 | iPad app, advanced proficiency tracking with TOPIK alignment, community-curated content, writing practice module (webtoon dialogue creation, news summary writing), heritage learner specialized pathway |
| Phase 4: Platform | Q4 2027+ | Android launch, additional Asian languages (Japanese, Mandarin) using the same media-first architecture, API for third-party Korean content creators, B2B licensing for Korean language programs |

---

## 13. Appendix: Research Foundations

This PRD is grounded in the following evidence base, synthesized from three source analyses:

- **Spaced retrieval and practice testing:** Meta-analytic evidence consistently shows spacing and retrieval practice among the highest-utility learning techniques. Hallyu implements these as system-wide policies via the adaptive SRS, not as an optional flashcard mode.

- **Task-based language teaching (TBLT):** Media consumption tasks serve as the organizing unit of instruction, with pre-task input, in-task comprehension, and post-task retrieval and reflection. This aligns with CEFR's action-oriented approach.

- **Explicit instruction for adults:** Meta-analyses show explicit grammar instruction yields larger gains than implicit instruction for adult learners. Claude's grammar explanations operationalize this within meaning-focused contexts.

- **High-variability phonetic training (HVPT):** Meta-analytic support for medium-to-large effects on L2 speech perception. Hallyu implements this through multi-speaker presentation of every phoneme target.

- **Corrective feedback:** SLA meta-analyses show corrective feedback has meaningful effects on L2 development. Claude's pronunciation and grammar feedback is explicit and corrective, not just evaluative.

- **Comprehensible input with progressive scaffold removal:** Captioned video shows meta-analytic support for vocabulary and listening gains. Hallyu's listen-first → Korean subtitles → comprehension check progression implements progressive scaffold fading.

- **ASR fairness:** Research documents significant bias in commercial ASR against non-native speakers. Hallyu addresses this through L2-speaker-trained models, intelligibility-focused scoring, and Claude-based qualitative fallbacks.
