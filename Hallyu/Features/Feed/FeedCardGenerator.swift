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
        let jamoPerCycle = 1 // cards per jamo: watch + trace + speak
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

            // Grammar card every 8th position
            if position % Self.grammarInterval == 0 {
                let grammarInfo = makeGrammarSnap(profile: profile)
                cards.append(FeedCard(content: .grammarSnap(quiz: grammarInfo)))
                continue
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
        // Flatten all lesson groups into a sequence of jamo entries
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
