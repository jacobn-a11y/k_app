import Foundation

/// A single card in the learning feed. Each card is a self-contained micro-interaction.
enum FeedCardContent: Equatable {
    /// Watch stroke animation for a jamo character
    case jamoWatch(jamo: JamoEntry)
    /// Trace a jamo character
    case jamoTrace(jamo: JamoEntry)
    /// Speak/pronounce a jamo character
    case jamoSpeak(jamo: JamoEntry)
    /// Watch/listen to a single media transcript segment
    case mediaClip(content: MediaClipInfo)
    /// Review a vocabulary flashcard
    case vocab(item: VocabCardInfo)
    /// Shadow a pronunciation phrase
    case pronunciation(phrase: PronunciationCardInfo)
    /// Quick grammar pattern quiz
    case grammarSnap(quiz: GrammarSnapInfo)
    /// Celebration card when daily goal is reached
    case goalReached(xpEarned: Int, cardsCompleted: Int)
    /// Cultural fact from media content
    case culturalMoment(info: CulturalMomentInfo)
    /// Listen to audio and choose the correct meaning
    case listenAndChoose(quiz: ListenAndChooseInfo)
    /// Milestone celebration (variable interval)
    case milestone(info: MilestoneInfo)
    /// Streak celebration at session start or streak thresholds
    case streak(days: Int)
}

struct FeedCard: Identifiable, Equatable {
    let id: UUID
    let content: FeedCardContent
    var isCompleted: Bool
    var xpAwarded: Int

    init(id: UUID = UUID(), content: FeedCardContent, isCompleted: Bool = false, xpAwarded: Int = 0) {
        self.id = id
        self.content = content
        self.isCompleted = isCompleted
        self.xpAwarded = xpAwarded
    }

    /// Whether this card requires user interaction to advance (vs auto-advance)
    var isInteractive: Bool {
        switch content {
        case .jamoWatch, .mediaClip, .goalReached, .culturalMoment, .milestone, .streak:
            return false
        case .jamoTrace, .jamoSpeak, .vocab, .pronunciation, .grammarSnap, .listenAndChoose:
            return true
        }
    }

    /// The activity type this card maps to for daily plan tracking
    var planActivityType: PlanActivityType? {
        switch content {
        case .jamoWatch, .jamoTrace, .jamoSpeak:
            return .hangulLesson
        case .mediaClip, .culturalMoment:
            return .mediaLesson
        case .vocab:
            return .srsReview
        case .pronunciation:
            return .pronunciationPractice
        case .grammarSnap, .listenAndChoose:
            return .grammarReview
        case .goalReached, .milestone, .streak:
            return nil
        }
    }
}

// MARK: - Card Info Types

struct MediaClipInfo: Equatable {
    let mediaContentId: UUID
    let title: String
    let contentType: String
    let segment: MediaContent.TranscriptSegment
    let mediaUrl: String
    let segmentIndex: Int
}

struct VocabCardInfo: Equatable {
    let reviewItemId: UUID
    let promptText: String
    let answerText: String
    let sourceContext: String
}

struct PronunciationCardInfo: Equatable {
    let phrase: String
    let romanization: String
    let translation: String
    let sourceTitle: String
}

struct GrammarSnapInfo: Equatable {
    let pattern: String
    let exampleSentence: String
    let translation: String
    let options: [String]
    let correctOptionIndex: Int
}

struct CulturalMomentInfo: Equatable {
    let title: String
    let body: String
    let mediaSource: String
    let mediaContentType: String
}

struct ListenAndChooseInfo: Equatable {
    let audioSegmentKr: String
    let audioSegmentEn: String
    let mediaUrl: String
    let startMs: Int
    let endMs: Int
    let options: [String]
    let correctOptionIndex: Int
    let sourceTitle: String
}

enum MilestoneType: Equatable {
    case wordsLearned(Int)
    case cardsCompleted(Int)
    case minutesStudied(Int)
    case streakInSession(Int)
}

struct MilestoneInfo: Equatable {
    let type: MilestoneType
    let message: String
}
