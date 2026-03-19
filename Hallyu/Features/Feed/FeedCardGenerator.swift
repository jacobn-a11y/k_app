import Foundation

/// Generates a queue of feed cards based on learner state.
/// Builds on PlanGeneratorService priority logic at micro-card granularity.
struct FeedCardGenerator {

    // MARK: - Configuration

    /// Number of cards to pre-generate ahead
    static let batchSize = 10
    /// Insert a media clip teaser every N jamo cards for beginners
    static let beginnerMediaInterval = 3
    /// Insert a vocab card every N cards when SRS items are due
    static let vocabInterval = 3
    /// Insert pronunciation card every N cards when mastery is low
    static let pronunciationInterval = 5
    /// Insert grammar card every N cards
    static let grammarInterval = 8
    /// Insert listen-and-choose card every N cards
    static let listenAndChooseInterval = 7
    /// Insert cultural moment every N cards
    static let culturalMomentInterval = 12
    /// Pronunciation mastery threshold for adding pronunciation cards
    static let pronunciationThreshold: Double = 0.4

    // MARK: - Generation

    func generateCards(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        existingCardCount: Int
    ) -> [FeedCard] {
        if !profile.hangulCompleted {
            return generateBeginnerCards(
                profile: profile,
                dueReviewItems: dueReviewItems,
                availableMedia: availableMedia,
                existingCardCount: existingCardCount
            )
        } else {
            return generateRegularCards(
                profile: profile,
                dueReviewItems: dueReviewItems,
                availableMedia: availableMedia,
                skillMasteries: skillMasteries,
                existingCardCount: existingCardCount
            )
        }
    }

    // MARK: - Beginner Flow (Jamo-heavy with media teasers)

    private func generateBeginnerCards(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        existingCardCount: Int
    ) -> [FeedCard] {
        var cards: [FeedCard] = []
        let allJamo = beginnerJamoSequence()

        // Determine which jamo to start from based on existing cards
        let cardsPerCycle = 3 + 1 // 3 jamo cards + 1 media teaser
        let startCycle = existingCardCount / cardsPerCycle
        let startJamoIndex = startCycle

        var vocabInsertCounter = 0

        for jamoOffset in 0..<Self.batchSize {
            let jamoIndex = (startJamoIndex + jamoOffset) % allJamo.count
            let jamo = allJamo[jamoIndex]

            // Watch -> Trace -> Speak for this jamo
            cards.append(FeedCard(content: .jamoWatch(jamo: jamo)))
            cards.append(FeedCard(content: .jamoTrace(jamo: jamo)))
            cards.append(FeedCard(content: .jamoSpeak(jamo: jamo)))

            // Media teaser after each jamo character
            if let clip = randomMediaClip(from: availableMedia, profile: profile) {
                cards.append(FeedCard(content: .mediaClip(content: clip)))
            }

            // Insert vocab card every 2 jamo characters
            vocabInsertCounter += 1
            if vocabInsertCounter >= 2 && !dueReviewItems.isEmpty {
                let itemIndex = (vocabInsertCounter / 2 - 1) % dueReviewItems.count
                let item = dueReviewItems[itemIndex]
                cards.append(FeedCard(content: .vocab(item: vocabCardInfo(from: item))))
                vocabInsertCounter = 0
            }

            // Insert cultural moment every 4 jamo characters
            if jamoOffset > 0 && jamoOffset % 4 == 0 {
                if let cultural = culturalMomentFromMedia(availableMedia, profile: profile) {
                    cards.append(FeedCard(content: .culturalMoment(info: cultural)))
                }
            }
        }

        return cards
    }

    // MARK: - Regular Flow (Post-beginner)

    private func generateRegularCards(
        profile: LearnerProfile,
        dueReviewItems: [ReviewItem],
        availableMedia: [MediaContent],
        skillMasteries: [SkillMastery],
        existingCardCount: Int
    ) -> [FeedCard] {
        var cards: [FeedCard] = []
        var vocabIndex = 0
        let pronunciationMastery = averageMastery(for: "pronunciation", in: skillMasteries)

        let mediaSegments = mediaClips(from: availableMedia, profile: profile, count: Self.batchSize)
        var mediaIndex = 0

        for i in 0..<Self.batchSize {
            let position = existingCardCount + i

            // Vocab card every 3rd position (highest priority for retention)
            if position % Self.vocabInterval == 0 && vocabIndex < dueReviewItems.count {
                let item = dueReviewItems[vocabIndex]
                cards.append(FeedCard(content: .vocab(item: vocabCardInfo(from: item))))
                vocabIndex += 1
                continue
            }

            // Pronunciation card every 5th position if mastery is low
            if position % Self.pronunciationInterval == 0 && pronunciationMastery < Self.pronunciationThreshold {
                if let clip = mediaSegments[safe: mediaIndex] {
                    cards.append(FeedCard(content: .pronunciation(phrase: pronunciationInfo(from: clip))))
                    mediaIndex += 1
                    continue
                }
            }

            // Listen-and-choose card every 7th position
            if position % Self.listenAndChooseInterval == 0 {
                if let clip = mediaSegments[safe: mediaIndex] {
                    let quiz = makeListenAndChoose(from: clip, allMedia: availableMedia, profile: profile)
                    cards.append(FeedCard(content: .listenAndChoose(quiz: quiz)))
                    mediaIndex += 1
                    continue
                }
            }

            // Grammar card every 8th position
            if position % Self.grammarInterval == 0 {
                let grammarInfo = makeGrammarSnap(profile: profile)
                cards.append(FeedCard(content: .grammarSnap(quiz: grammarInfo)))
                continue
            }

            // Cultural moment every 12th position
            if position % Self.culturalMomentInterval == 0 {
                if let cultural = culturalMomentFromMedia(availableMedia, profile: profile) {
                    cards.append(FeedCard(content: .culturalMoment(info: cultural)))
                    continue
                }
            }

            // Default: media clip
            if mediaIndex < mediaSegments.count {
                cards.append(FeedCard(content: .mediaClip(content: mediaSegments[mediaIndex])))
                mediaIndex += 1
            } else if vocabIndex < dueReviewItems.count {
                let item = dueReviewItems[vocabIndex]
                cards.append(FeedCard(content: .vocab(item: vocabCardInfo(from: item))))
                vocabIndex += 1
            }
        }

        return cards
    }

    // MARK: - Helpers

    private func beginnerJamoSequence() -> [JamoEntry] {
        HangulData.lessonGroups.flatMap { group in
            group.jamoIds.compactMap { HangulData.jamo(for: $0) }
        }
    }

    private func randomMediaClip(from media: [MediaContent], profile: LearnerProfile) -> MediaClipInfo? {
        let matching = media.filter { $0.cefrLevel == profile.cefrLevel || $0.cefrLevel == "pre-A1" || $0.cefrLevel == "A1" }
        guard let content = matching.randomElement() ?? media.first else { return nil }
        let segments = content.transcriptSegments
        guard let segment = segments.randomElement() else { return nil }
        let segmentIndex = segments.firstIndex(of: segment) ?? 0
        return MediaClipInfo(
            mediaContentId: content.id,
            title: content.title,
            contentType: content.contentType,
            segment: segment,
            mediaUrl: content.mediaUrl,
            segmentIndex: segmentIndex
        )
    }

    private func mediaClips(from media: [MediaContent], profile: LearnerProfile, count: Int) -> [MediaClipInfo] {
        let matching = media.filter { $0.cefrLevel == profile.cefrLevel }
        let pool = matching.isEmpty ? media : matching

        var clips: [MediaClipInfo] = []
        for content in pool {
            for (index, segment) in content.transcriptSegments.enumerated() {
                clips.append(MediaClipInfo(
                    mediaContentId: content.id,
                    title: content.title,
                    contentType: content.contentType,
                    segment: segment,
                    mediaUrl: content.mediaUrl,
                    segmentIndex: index
                ))
                if clips.count >= count { return clips }
            }
        }
        return clips
    }

    private func vocabCardInfo(from item: ReviewItem) -> VocabCardInfo {
        VocabCardInfo(
            reviewItemId: item.id,
            promptText: item.promptText,
            answerText: item.answerText,
            sourceContext: item.sourceContext
        )
    }

    private func pronunciationInfo(from clip: MediaClipInfo) -> PronunciationCardInfo {
        PronunciationCardInfo(
            phrase: clip.segment.textKr,
            romanization: "",
            translation: clip.segment.textEn,
            sourceTitle: clip.title
        )
    }

    private func makeGrammarSnap(profile: LearnerProfile) -> GrammarSnapInfo {
        let patterns: [(pattern: String, example: String, translation: String, options: [String], correct: Int)] = [
            ("-아/어요", "맛있어요", "It's delicious", ["Polite ending", "Past tense", "Question", "Negation"], 0),
            ("-고 싶다", "가고 싶어요", "I want to go", ["Want to", "Must", "Can", "Should"], 0),
            ("-(으)ㄴ데", "비가 오는데", "It's raining, but...", ["Background/contrast", "Because", "If", "When"], 0),
            ("-았/었-", "먹었어요", "I ate", ["Past tense", "Future tense", "Present", "Polite"], 0),
        ]

        let selected: (pattern: String, example: String, translation: String, options: [String], correct: Int)
        switch profile.cefrLevel {
        case "pre-A1", "A1": selected = patterns[0]
        case "A2": selected = patterns[1]
        case "B1": selected = patterns[2]
        default: selected = patterns[3]
        }

        return GrammarSnapInfo(
            pattern: selected.pattern,
            exampleSentence: selected.example,
            translation: selected.translation,
            options: selected.options,
            correctOptionIndex: selected.correct
        )
    }

    private func makeListenAndChoose(from clip: MediaClipInfo, allMedia: [MediaContent], profile: LearnerProfile) -> ListenAndChooseInfo {
        // Generate distractors from other segments
        let correctAnswer = clip.segment.textEn
        var distractors: [String] = []

        for content in allMedia {
            for segment in content.transcriptSegments where segment.textEn != correctAnswer {
                distractors.append(segment.textEn)
                if distractors.count >= 3 { break }
            }
            if distractors.count >= 3 { break }
        }

        // Pad with generic distractors if not enough
        let genericDistractors = ["Thank you", "Hello, how are you?", "I don't understand", "See you later", "Where is the station?", "It's very good"]
        while distractors.count < 3 {
            let generic = genericDistractors[distractors.count % genericDistractors.count]
            if generic != correctAnswer {
                distractors.append(generic)
            }
        }

        // Build options with correct answer at random position
        var options = Array(distractors.prefix(3))
        let correctIndex = Int.random(in: 0...3)
        options.insert(correctAnswer, at: correctIndex)

        return ListenAndChooseInfo(
            audioSegmentKr: clip.segment.textKr,
            audioSegmentEn: clip.segment.textEn,
            mediaUrl: clip.mediaUrl,
            startMs: clip.segment.startMs,
            endMs: clip.segment.endMs,
            options: options,
            correctOptionIndex: correctIndex,
            sourceTitle: clip.title
        )
    }

    private func culturalMomentFromMedia(_ media: [MediaContent], profile: LearnerProfile) -> CulturalMomentInfo? {
        // Find media with cultural notes
        let withNotes = media.filter { !$0.culturalNotes.isEmpty }
        guard let content = withNotes.randomElement() else {
            // Fallback built-in cultural facts
            return builtInCulturalMoment()
        }

        return CulturalMomentInfo(
            title: "Korean Culture",
            body: content.culturalNotes,
            mediaSource: content.title,
            mediaContentType: content.contentType
        )
    }

    private func builtInCulturalMoment() -> CulturalMomentInfo {
        let facts: [(title: String, body: String)] = [
            ("Age Matters", "In Korean culture, the first thing people often ask is your age. This determines the level of formality you should use when speaking — it's not rude, it's practical!"),
            ("Honorific Speech", "Korean has 7 speech levels! The most common in daily life are 존댓말 (formal polite) and 반말 (casual). Using the wrong one can cause real social awkwardness."),
            ("Kimchi Varieties", "There are over 200 types of kimchi in Korea! The most famous is baechu-kimchi (napa cabbage), but Koreans also make kimchi from radish, cucumber, and even perilla leaves."),
            ("Soju Culture", "When someone older pours you a drink in Korea, you should hold your glass with both hands and turn slightly away when drinking. It's a sign of respect!"),
            ("Korean Names", "In Korea, the family name comes first. About 45% of Koreans have one of just three surnames: Kim (김), Lee (이), or Park (박)."),
            ("Fan Death", "Some Koreans believe sleeping with an electric fan on in a closed room can be fatal. Most modern Koreans laugh about it, but many still won't do it!"),
        ]
        let fact = facts.randomElement() ?? facts[0]
        return CulturalMomentInfo(
            title: fact.title,
            body: fact.body,
            mediaSource: "",
            mediaContentType: ""
        )
    }

    private func averageMastery(for skillType: String, in masteries: [SkillMastery]) -> Double {
        let matching = masteries.filter { $0.skillType == skillType }
        guard !matching.isEmpty else { return 0.0 }
        return matching.reduce(0.0) { $0 + $1.accuracy } / Double(matching.count)
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
