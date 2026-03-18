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

    @Test("Pronunciation prompt includes transcript and target")
    func pronunciationPromptFields() {
        let prompt = ClaudePrompts.pronunciationPrompt(transcript: "안영", target: "안녕")
        #expect(prompt.contains("안영"))
        #expect(prompt.contains("안녕"))
        #expect(prompt.contains("isCorrect"))
    }

    @Test("Grammar prompt includes pattern and context")
    func grammarPromptFields() {
        let prompt = ClaudePrompts.grammarPrompt(pattern: "-이/가", context: "나는 학생이에요")
        #expect(prompt.contains("-이/가"))
        #expect(prompt.contains("나는 학생이에요"))
        #expect(prompt.contains("ruleStatement"))
    }

    @Test("Practice generation prompt includes level")
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
}
