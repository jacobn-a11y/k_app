import Testing
import Foundation
@testable import HallyuCore

@Suite("ClaudePrompts Tests")
struct ClaudePromptsTests {

    @Test("System prompt includes learner level")
    func systemPromptIncludesLevel() {
        let prompt = ClaudePrompts.systemPrompt(learnerLevel: "A1")
        #expect(prompt.contains("A1"))
        #expect(prompt.contains("Korean"))
        #expect(prompt.contains("JSON"))
    }

    @Test("Comprehension prompt includes all context fields")
    func comprehensionPromptFields() {
        let context = ComprehensionContext(
            mediaTitle: "My Drama",
            transcript: "안녕하세요",
            targetWord: "안녕",
            learnerLevel: "A1",
            knownVocabulary: ["네", "아니요"]
        )
        let prompt = ClaudePrompts.comprehensionPrompt(context: context, query: "What does this mean?")
        #expect(prompt.contains("My Drama"))
        #expect(prompt.contains("안녕하세요"))
        #expect(prompt.contains("안녕"))
        #expect(prompt.contains("A1"))
        #expect(prompt.contains("What does this mean?"))
        #expect(prompt.contains("literalMeaning"))
    }

    @Test("Comprehension retrieval prompt includes target word")
    func comprehensionRetrievalPrompt() {
        let prompt = ClaudePrompts.comprehensionRetrievalPrompt(targetWord: "사랑", learnerLevel: "A2")
        #expect(prompt.contains("사랑"))
        #expect(prompt.contains("A2"))
        #expect(prompt.contains("retrievalPrompt"))
    }

    @Test("Pronunciation prompt includes transcript and target")
    func pronunciationPromptFields() {
        let prompt = ClaudePrompts.pronunciationPrompt(transcript: "안영", target: "안녕")
        #expect(prompt.contains("안영"))
        #expect(prompt.contains("안녕"))
        #expect(prompt.contains("isCorrect"))
        #expect(prompt.contains("drillSequence"))
    }

    @Test("Pronunciation drill prompt includes error patterns")
    func pronunciationDrillPrompt() {
        let prompt = ClaudePrompts.pronunciationDrillPrompt(
            errorPatterns: ["ㄹ/ㄴ confusion", "ㅂ aspiration"],
            learnerLevel: "A1"
        )
        #expect(prompt.contains("ㄹ/ㄴ confusion"))
        #expect(prompt.contains("ㅂ aspiration"))
        #expect(prompt.contains("drillWords"))
    }

    @Test("Grammar prompt includes pattern and context")
    func grammarPromptFields() {
        let prompt = ClaudePrompts.grammarPrompt(pattern: "-이/가", context: "나는 학생이에요")
        #expect(prompt.contains("-이/가"))
        #expect(prompt.contains("나는 학생이에요"))
        #expect(prompt.contains("ruleStatement"))
    }

    @Test("Grammar retrieval prompt includes pattern")
    func grammarRetrievalPrompt() {
        let prompt = ClaudePrompts.grammarRetrievalPrompt(
            pattern: "-고 싶다",
            context: "나는 한국어를 배우고 싶어요",
            learnerLevel: "A1"
        )
        #expect(prompt.contains("-고 싶다"))
        #expect(prompt.contains("retrievalQuestion"))
    }

    @Test("Enhanced practice generation prompt includes media context")
    func enhancedPracticePrompt() {
        let prompt = ClaudePrompts.practiceGenerationPrompt(
            mediaTranscript: "오늘 날씨가 좋아요",
            vocabularyWords: ["날씨", "좋다"],
            grammarPatterns: ["-이/가"],
            learnerLevel: "A1"
        )
        #expect(prompt.contains("오늘 날씨가 좋아요"))
        #expect(prompt.contains("날씨"))
        #expect(prompt.contains("-이/가"))
        #expect(prompt.contains("fill_in_blank"))
        #expect(prompt.contains("comprehension"))
        #expect(prompt.contains("production"))
    }

    @Test("Legacy practice generation prompt includes level")
    func practicePromptFields() {
        let id = UUID()
        let prompt = ClaudePrompts.practiceGenerationPrompt(mediaContentId: id, learnerLevel: "A2")
        #expect(prompt.contains(id.uuidString))
        #expect(prompt.contains("A2"))
    }

    @Test("Cultural context prompt includes moment and context")
    func culturalPromptFields() {
        let prompt = ClaudePrompts.culturalContextPrompt(moment: "bowing scene", mediaContext: "office drama")
        #expect(prompt.contains("bowing scene"))
        #expect(prompt.contains("office drama"))
        #expect(prompt.contains("explanation"))
        #expect(prompt.contains("honorificNote"))
    }

    @Test("All system prompts request JSON responses")
    func systemPromptsRequestJSON() {
        let prompts = [
            ClaudePrompts.pronunciationSystemPrompt,
            ClaudePrompts.grammarSystemPrompt,
            ClaudePrompts.contentAdapterSystemPrompt,
            ClaudePrompts.culturalContextSystemPrompt
        ]
        for prompt in prompts {
            #expect(prompt.contains("JSON"))
        }
    }

    @Test("System prompt mentions retrieval-first teaching")
    func systemPromptRetrievalFirst() {
        let prompt = ClaudePrompts.systemPrompt(learnerLevel: "A1")
        #expect(prompt.contains("retrieval-first"))
    }

    @Test("Pronunciation system prompt mentions minimal pairs")
    func pronunciationSystemPromptMinimalPairs() {
        #expect(ClaudePrompts.pronunciationSystemPrompt.contains("minimal pairs"))
    }

    @Test("Content adapter system prompt mentions exercise types")
    func contentAdapterExerciseTypes() {
        let prompt = ClaudePrompts.contentAdapterSystemPrompt
        #expect(prompt.contains("fill-in-the-blank"))
        #expect(prompt.contains("comprehension"))
        #expect(prompt.contains("production"))
    }
}
