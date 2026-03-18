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

    // MARK: - User Prompts

    static func comprehensionPrompt(context: ComprehensionContext, query: String) -> String {
        """
        Media: "\(context.mediaTitle)"
        Transcript context: "\(context.transcript)"
        Target word/phrase: "\(context.targetWord)"
        Learner question: "\(query)"
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

    static func pronunciationPrompt(transcript: String, target: String) -> String {
        """
        The learner tried to say: "\(target)"
        Speech recognition heard: "\(transcript)"

        Provide a JSON response with these fields:
        {
            "isCorrect": true/false,
            "feedback": "overall assessment",
            "articulatoryTip": "specific tip for improvement, or null if correct",
            "similarSounds": ["list", "of", "similar", "sounds", "to", "practice"]
        }
        """
    }

    static func grammarPrompt(pattern: String, context: String) -> String {
        """
        Grammar pattern: "\(pattern)"
        Media context: "\(context)"

        Provide a JSON response with these fields:
        {
            "ruleStatement": "clear statement of the grammar rule",
            "explanation": "detailed explanation with the media context",
            "contrastiveExample": "example showing what changes with a different pattern",
            "retrievalQuestion": "question to check learner's understanding"
        }
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
        """
        Confusing cultural moment: "\(moment)"
        Media context: "\(mediaContext)"

        Provide a JSON response with these fields:
        {
            "explanation": "clear explanation of the cultural context",
            "socialDynamics": "relevant social dynamics, or null",
            "historicalContext": "historical background if relevant, or null",
            "relatedMedia": ["titles of related media that illustrate this concept"]
        }
        """
    }
}
