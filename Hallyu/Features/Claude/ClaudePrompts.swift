import Foundation

enum ClaudePrompts {
    // MARK: - System Prompts

    static func systemPrompt(learnerLevel: String) -> String {
        """
        You are a Korean language learning coach integrated into a media-based learning app. \
        The learner's current CEFR level is \(learnerLevel).

        Your role is to help learners understand Korean through authentic media content \
        (K-dramas, webtoons, news, music). Always:
        - Use retrieval-first teaching: ask the learner what they think before explaining
        - Keep explanations concise (under 150 words for vocabulary, 300 for grammar)
        - Adapt complexity to the learner's level
        - Reference the media context when explaining
        - Respond in valid JSON matching the requested format

        Never break character or discuss topics outside Korean language learning.
        """
    }

    static let pronunciationSystemPrompt = """
        You are a Korean pronunciation coach. Your role is to help learners improve \
        their Korean pronunciation by providing specific, actionable articulatory feedback.

        When comparing a learner's spoken transcript to the target:
        - Identify specific phonemes that differ
        - Provide articulatory tips (tongue position, lip shape, airflow)
        - Reference minimal pairs to highlight the distinction
        - Be encouraging while being precise about errors
        - Suggest a focused drill sequence for recurring errors

        Respond in valid JSON matching the requested format.
        """

    static let grammarSystemPrompt = """
        You are a Korean grammar coach specializing in explaining grammar patterns \
        found in authentic Korean media. Your approach:
        - State the rule clearly and concisely
        - Show the pattern in the original media context
        - Provide a contrastive example showing what changes with a different pattern
        - End with a retrieval question to check understanding
        - Keep total response under 300 words

        Respond in valid JSON matching the requested format.
        """

    static let contentAdapterSystemPrompt = """
        You are a Korean language exercise generator. Given a media content segment \
        and a learner's level, generate practice items that:
        - Test vocabulary and grammar from the specific media segment
        - Include fill-in-the-blank, comprehension, and production exercises
        - Match the learner's current level
        - Use context from the media content
        - Generate 2-3 fill-in-the-blank, 1 comprehension, and 1 production item

        Respond in valid JSON as an array of practice items.
        """

    static let culturalContextSystemPrompt = """
        You are a Korean cultural interpreter helping language learners understand \
        cultural context in Korean media. Explain:
        - Social dynamics (hierarchy, age-based relationships)
        - Honorific usage and register choices
        - Historical or cultural references
        - Slang and colloquialisms
        - Non-verbal cultural cues

        Keep explanations accessible and under 200 words. \
        Respond in valid JSON matching the requested format.
        """

    // MARK: - Input Sanitization

    /// Sanitize user-provided input to prevent prompt injection
    private static func sanitize(_ input: String) -> String {
        input
            .replacingOccurrences(of: "[SYSTEM]", with: "")
            .replacingOccurrences(of: "[INSTRUCTION]", with: "")
            .replacingOccurrences(of: "\\n\\nHuman:", with: "")
            .replacingOccurrences(of: "\\n\\nAssistant:", with: "")
            .prefix(2000)
            .description
    }

    // MARK: - User Prompts

    static func comprehensionPrompt(context: ComprehensionContext, query: String) -> String {
        let safeTranscript = sanitize(context.transcript)
        let safeQuery = sanitize(query)
        let safeWord = sanitize(context.targetWord)
        let safeTitle = sanitize(context.mediaTitle)
        return """
        Media: "\(safeTitle)"
        Transcript context: "\(safeTranscript)"
        Target word/phrase: "\(safeWord)"
        Learner question: "\(safeQuery)"
        Learner level: \(context.learnerLevel)
        Known vocabulary: \(context.knownVocabulary.prefix(20).joined(separator: ", "))

        Provide a JSON response with these fields:
        {
            "literalMeaning": "direct translation",
            "contextualMeaning": "meaning in this specific scene",
            "grammarPattern": "grammar pattern if applicable, or null",
            "simplerExample": "a simpler sentence using the same word/pattern",
            "registerNote": "formality note if relevant, or null"
        }
        """
    }

    static func comprehensionRetrievalPrompt(targetWord: String, learnerLevel: String) -> String {
        """
        The learner has tapped on the word/phrase: "\(targetWord)"
        Learner level: \(learnerLevel)

        Before explaining, ask the learner what they think this word means. \
        Generate a brief, encouraging retrieval prompt.

        Provide a JSON response:
        {
            "retrievalPrompt": "What do you think ... means? (encouraging hint)",
            "hintLevel": "none|mild|strong"
        }
        """
    }

    static func pronunciationPrompt(transcript: String, target: String) -> String {
        let safeTranscript = sanitize(transcript)
        let safeTarget = sanitize(target)
        return """
        The learner tried to say: "\(safeTarget)"
        Speech recognition heard: "\(safeTranscript)"

        Provide a JSON response with these fields:
        {
            "isCorrect": true/false,
            "feedback": "overall assessment",
            "articulatoryTip": "specific tip for improvement, or null if correct",
            "similarSounds": ["list", "of", "similar", "sounds", "to", "practice"],
            "drillSequence": ["word1", "word2", "word3"]
        }
        """
    }

    static func pronunciationDrillPrompt(errorPatterns: [String], learnerLevel: String) -> String {
        """
        The learner has recurring pronunciation errors with these patterns:
        \(errorPatterns.joined(separator: ", "))
        Learner level: \(learnerLevel)

        Generate a focused drill sequence of 5 words that target these error patterns, \
        progressing from easier to harder.

        Provide a JSON response:
        {
            "drillWords": [
                {"korean": "word", "romanization": "rom", "targetPhoneme": "phoneme"}
            ],
            "explanation": "why these words help with the specific errors"
        }
        """
    }

    static func grammarPrompt(pattern: String, context: String) -> String {
        let safePattern = sanitize(pattern)
        let safeContext = sanitize(context)
        return """
        Grammar pattern: "\(safePattern)"
        Media context: "\(safeContext)"

        Provide a JSON response with these fields:
        {
            "ruleStatement": "clear statement of the grammar rule",
            "explanation": "detailed explanation with the media context",
            "contrastiveExample": "example showing what changes with a different pattern",
            "retrievalQuestion": "question to check learner's understanding"
        }
        """
    }

    static func grammarRetrievalPrompt(pattern: String, context: String, learnerLevel: String) -> String {
        """
        Grammar pattern found in media: "\(pattern)"
        Context: "\(context)"
        Learner level: \(learnerLevel)

        Before explaining the grammar, ask the learner to identify the rule. \
        Generate a retrieval-first question.

        Provide a JSON response:
        {
            "retrievalQuestion": "Can you identify what grammar rule is at work here?",
            "hint": "a subtle hint about the pattern"
        }
        """
    }

    static func practiceGenerationPrompt(
        mediaTranscript: String,
        vocabularyWords: [String],
        grammarPatterns: [String],
        learnerLevel: String
    ) -> String {
        """
        Media segment transcript: "\(mediaTranscript)"
        Key vocabulary: \(vocabularyWords.joined(separator: ", "))
        Grammar patterns present: \(grammarPatterns.joined(separator: ", "))
        Learner level: \(learnerLevel)

        Generate practice items based on this media segment:
        - 2-3 fill-in-the-blank exercises using vocabulary from the segment
        - 1 comprehension question testing inference
        - 1 production prompt (speaking practice using patterns from the segment)

        Provide a JSON array of practice items:
        [
            {
                "type": "fill_in_blank" | "comprehension" | "production",
                "prompt": "the exercise prompt",
                "correctAnswer": "the correct answer",
                "alternatives": ["wrong1", "wrong2", "wrong3"],
                "sourceContext": "relevant part of the transcript"
            }
        ]
        """
    }

    static func practiceGenerationPrompt(mediaContentId: UUID, learnerLevel: String) -> String {
        """
        Generate practice items for media content ID: \(mediaContentId)
        Learner level: \(learnerLevel)

        Provide a JSON array of 3-5 practice items:
        [
            {
                "type": "fill_in_blank" | "comprehension" | "production",
                "prompt": "the exercise prompt",
                "correctAnswer": "the correct answer",
                "alternatives": ["wrong1", "wrong2", "wrong3"]
            }
        ]
        """
    }

    static func culturalContextPrompt(moment: String, mediaContext: String) -> String {
        let safeMoment = sanitize(moment)
        let safeContext = sanitize(mediaContext)
        return """
        Confusing cultural moment: "\(safeMoment)"
        Media context: "\(safeContext)"

        Provide a JSON response with these fields:
        {
            "explanation": "clear explanation of the cultural context",
            "socialDynamics": "relevant social dynamics, or null",
            "honorificNote": "honorific usage explanation, or null",
            "historicalContext": "historical background if relevant, or null",
            "relatedMedia": ["titles of related media that illustrate this concept"]
        }
        """
    }
}

// MARK: - Retrieval-First Response Types

struct RetrievalPromptResponse: Codable, Sendable {
    let retrievalPrompt: String
    let hintLevel: String // "none", "mild", "strong"
}

struct GrammarRetrievalResponse: Codable, Sendable {
    let retrievalQuestion: String
    let hint: String
}

struct PronunciationDrillResponse: Codable, Sendable {
    let drillWords: [DrillWord]
    let explanation: String

    struct DrillWord: Codable, Sendable {
        let korean: String
        let romanization: String
        let targetPhoneme: String
    }
}
