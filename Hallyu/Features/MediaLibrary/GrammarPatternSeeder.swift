import Foundation
import SwiftData

/// Seeds GrammarPattern records matching the patterns defined in KoreanTextAnalyzer.
/// These records are cross-referenced by MediaMetadataService to populate grammarPatternIds
/// on MediaContent.
enum GrammarPatternSeeder {

    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<GrammarPattern>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for pattern in allPatterns {
            modelContext.insert(pattern)
        }
        try? modelContext.save()
    }

    static let allPatterns: [GrammarPattern] = entries.map { entry in
        GrammarPattern(
            patternName: entry.name,
            patternTemplate: entry.template,
            explanation: entry.explanation,
            cefrLevel: entry.cefrLevel,
            formalityLevel: entry.formality,
            exampleSentences: entry.examples,
            commonMistakes: entry.mistakes
        )
    }

    // MARK: - Data

    private struct Entry {
        let name: String
        let template: String
        let explanation: String
        let cefrLevel: String
        let formality: String
        let examples: [GrammarPattern.ExampleSentence]
        let mistakes: [String]
    }

    /// Sourced from KoreanTextAnalyzer.grammarPatterns — same pattern names for cross-referencing.
    private static let entries: [Entry] = [
        Entry(
            name: "copula -이에요/예요",
            template: "N + 이에요/예요",
            explanation: "Informal polite copula ('is/am/are'). Use 이에요 after consonant, 예요 after vowel.",
            cefrLevel: "A1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "학생이에요", en: "I am a student", context: "self-introduction"),
                GrammarPattern.ExampleSentence(kr: "의사예요", en: "I am a doctor", context: "occupation"),
            ],
            mistakes: ["Using 이에요 after vowels"]
        ),
        Entry(
            name: "formal copula -입니다",
            template: "N + 입니다",
            explanation: "Formal polite copula used in formal settings, presentations, and news.",
            cefrLevel: "A1", formality: "formal",
            examples: [
                GrammarPattern.ExampleSentence(kr: "저는 학생입니다", en: "I am a student", context: "formal introduction"),
            ],
            mistakes: ["Using in casual conversation"]
        ),
        Entry(
            name: "formal ending -습니다/ㅂ니다",
            template: "V + 습니다/ㅂ니다",
            explanation: "Formal declarative verb ending. Use 습니다 after consonant stem, ㅂ니다 after vowel stem.",
            cefrLevel: "A1", formality: "formal",
            examples: [
                GrammarPattern.ExampleSentence(kr: "감사합니다", en: "Thank you", context: "expressing gratitude"),
            ],
            mistakes: ["Confusing consonant/vowel stem rules"]
        ),
        Entry(
            name: "polite ending -아/어요",
            template: "V + 아/어요",
            explanation: "Standard polite verb ending for everyday conversation.",
            cefrLevel: "A1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "먹어요", en: "I eat", context: "daily routine"),
                GrammarPattern.ExampleSentence(kr: "가요", en: "I go", context: "movement"),
            ],
            mistakes: ["Wrong vowel harmony (아 vs 어)"]
        ),
        Entry(
            name: "honorific -세요",
            template: "V + (으)세요",
            explanation: "Honorific form used to show respect to the subject of the sentence.",
            cefrLevel: "A1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "안녕하세요", en: "Hello", context: "greeting"),
            ],
            mistakes: ["Using for oneself"]
        ),
        Entry(
            name: "desire -고 싶다",
            template: "V + 고 싶다",
            explanation: "Expresses desire or wish to do something ('want to').",
            cefrLevel: "A1", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "먹고 싶어요", en: "I want to eat", context: "expressing desire"),
            ],
            mistakes: ["Using with adjectives instead of verbs"]
        ),
        Entry(
            name: "ability -을/ㄹ 수 있다",
            template: "V + (을/ㄹ) 수 있다",
            explanation: "Expresses ability or possibility ('can do').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "한국어를 할 수 있어요", en: "I can speak Korean", context: "discussing abilities"),
            ],
            mistakes: ["Forgetting 수 in the middle"]
        ),
        Entry(
            name: "cause/sequence -아/어서",
            template: "V + 아/어서",
            explanation: "Connects clauses with cause-effect or sequential relationship ('because/so/and then').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "배가 고파서 밥을 먹었어요", en: "I was hungry so I ate", context: "explaining reason"),
            ],
            mistakes: ["Using with imperative or suggestion endings"]
        ),
        Entry(
            name: "contrast -지만",
            template: "V/A + 지만",
            explanation: "Connects contrasting clauses ('but/however').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "비싸지만 맛있어요", en: "It's expensive but delicious", context: "comparing"),
            ],
            mistakes: ["Confusing with -는데"]
        ),
        Entry(
            name: "conditional -으면/면",
            template: "V/A + (으)면",
            explanation: "Expresses condition ('if/when').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "시간이 있으면 만나요", en: "If you have time, let's meet", context: "making plans"),
            ],
            mistakes: ["Confusing with -다면 (hypothetical)"]
        ),
        Entry(
            name: "progressive -고 있다",
            template: "V + 고 있다",
            explanation: "Expresses ongoing action ('is doing').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "공부하고 있어요", en: "I am studying", context: "current activity"),
            ],
            mistakes: ["Using with stative verbs"]
        ),
        Entry(
            name: "background -는데",
            template: "V + 는데 / A + (으)ㄴ데",
            explanation: "Provides background context or sets up contrast/surprise.",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "비가 오는데 우산이 없어요", en: "It's raining but I don't have an umbrella", context: "explaining situation"),
            ],
            mistakes: ["Wrong conjugation for adjectives vs verbs"]
        ),
        Entry(
            name: "suggestion -을까요/ㄹ까요",
            template: "V + (을/ㄹ)까요?",
            explanation: "Makes a suggestion or asks for opinion ('shall we?').",
            cefrLevel: "A2", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "같이 갈까요?", en: "Shall we go together?", context: "suggesting"),
            ],
            mistakes: ["Using for statements instead of questions"]
        ),
        Entry(
            name: "obligation -아/어야 하다",
            template: "V + 아/어야 하다",
            explanation: "Expresses obligation or necessity ('must/have to').",
            cefrLevel: "A2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "공부해야 해요", en: "I have to study", context: "expressing obligation"),
            ],
            mistakes: ["Confusing with -고 싶다 (want to)"]
        ),
        Entry(
            name: "conjecture -는 것 같다",
            template: "V + 는 것 같다",
            explanation: "Expresses conjecture or guess ('it seems like').",
            cefrLevel: "B1", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "비가 올 것 같아요", en: "It seems like it will rain", context: "weather guess"),
            ],
            mistakes: ["Wrong tense marker before 것"]
        ),
        Entry(
            name: "reason -기 때문에",
            template: "V/A + 기 때문에",
            explanation: "Formal way to express reason ('because').",
            cefrLevel: "B1", formality: "formal",
            examples: [
                GrammarPattern.ExampleSentence(kr: "바쁘기 때문에 못 가요", en: "I can't go because I'm busy", context: "giving reason"),
            ],
            mistakes: ["Using in very casual speech"]
        ),
        Entry(
            name: "purpose/extent -도록",
            template: "V + 도록",
            explanation: "Expresses purpose or extent ('so that/to the extent').",
            cefrLevel: "B1", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "늦지 않도록 일찍 출발하세요", en: "Leave early so you won't be late", context: "advice"),
            ],
            mistakes: ["Confusing with -기 위해서"]
        ),
        Entry(
            name: "intention -으려고/려고",
            template: "V + (으)려고",
            explanation: "Expresses intention or plan ('in order to').",
            cefrLevel: "B1", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "한국어를 배우려고 한국에 왔어요", en: "I came to Korea to learn Korean", context: "explaining purpose"),
            ],
            mistakes: ["Using with past tense"]
        ),
        Entry(
            name: "retrospective -더라고요",
            template: "V/A + 더라고요",
            explanation: "Reports a past personal observation or experience.",
            cefrLevel: "B1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "음식이 맛있더라고요", en: "The food was delicious (I noticed)", context: "sharing experience"),
            ],
            mistakes: ["Using for things not personally witnessed"]
        ),
        Entry(
            name: "shared knowledge -잖아요",
            template: "V/A + 잖아요",
            explanation: "References shared knowledge ('you know/as you know').",
            cefrLevel: "B1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "내일 시험이잖아요", en: "We have a test tomorrow, you know", context: "reminding"),
            ],
            mistakes: ["Using with strangers about unknown facts"]
        ),
        Entry(
            name: "reason-giving -거든요",
            template: "V/A + 거든요",
            explanation: "Provides background reason or justification.",
            cefrLevel: "B1", formality: "polite",
            examples: [
                GrammarPattern.ExampleSentence(kr: "못 가요. 바쁘거든요", en: "I can't go. I'm busy, you see.", context: "justifying"),
            ],
            mistakes: ["Using as a simple 'because'"]
        ),
        Entry(
            name: "hypothetical -다면",
            template: "V/A + 다면",
            explanation: "Expresses hypothetical condition ('if it were the case that').",
            cefrLevel: "B2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "시간이 있다면 여행을 하고 싶어요", en: "If I had time, I would want to travel", context: "hypothetical"),
            ],
            mistakes: ["Confusing with -면 (general conditional)"]
        ),
        Entry(
            name: "observation -더니",
            template: "V/A + 더니",
            explanation: "Connects a past observation with its result or consequence.",
            cefrLevel: "B2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "열심히 공부하더니 시험을 잘 봤어요", en: "They studied hard and then did well on the exam", context: "observation"),
            ],
            mistakes: ["Using for first-person observations"]
        ),
        Entry(
            name: "unintended cause -는 바람에",
            template: "V + 는 바람에",
            explanation: "Expresses an unintended cause leading to a negative result.",
            cefrLevel: "B2", formality: "neutral",
            examples: [
                GrammarPattern.ExampleSentence(kr: "비가 오는 바람에 소풍을 못 갔어요", en: "Because of the rain, we couldn't go on the picnic", context: "unexpected cause"),
            ],
            mistakes: ["Using for positive outcomes"]
        ),
    ]
}
