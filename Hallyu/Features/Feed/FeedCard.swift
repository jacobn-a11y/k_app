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
        case .jamoWatch, .mediaClip, .goalReached:
            return false
        case .jamoTrace, .jamoSpeak, .vocab, .pronunciation, .grammarSnap:
            return true
        }
    }

    /// The activity type this card maps to for daily plan tracking
    var planActivityType: PlanActivityType? {
        switch content {
        case .jamoWatch, .jamoTrace, .jamoSpeak:
            return .hangulLesson
        case .mediaClip:
            return .mediaLesson
        case .vocab:
            return .srsReview
        case .pronunciation:
            return .pronunciationPractice
        case .grammarSnap:
            return .grammarReview
        case .goalReached:
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
