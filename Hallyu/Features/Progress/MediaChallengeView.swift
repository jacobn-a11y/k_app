import SwiftUI

// MARK: - Media Challenge (Monthly Assessment)

@MainActor
@Observable
final class MediaChallengeViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case intro
        case mediaPlayback
        case questions
        case results
    }

    private(set) var phase: Phase = .intro
    private(set) var challengeContent: MediaContent?
    private(set) var questions: [ChallengeQuestion] = []
    private(set) var currentQuestionIndex: Int = 0
    private(set) var answers: [ChallengeAnswer] = []
    private(set) var report: ChallengeReport?
    private(set) var isLoading: Bool = false
    private var questionStartedAt: Date = Date()

    let claudeService: ClaudeServiceProtocol
    let learnerModel: LearnerModelServiceProtocol
    let userId: UUID
    let learnerLevel: String

    // MARK: - Types

    struct ChallengeQuestion: Identifiable, Equatable {
        let id: UUID
        let prompt: String
        let options: [String]
        let correctAnswer: String
        let skillTested: String
        let cefrLevel: String
    }

    struct ChallengeAnswer: Equatable {
        let questionId: UUID
        let selectedAnswer: String
        let wasCorrect: Bool
        let responseTime: TimeInterval
    }

    struct ChallengeReport: Equatable {
        let overallScore: Double
        let cefrEstimate: String
        let skillBreakdown: [SkillScore]
        let strengths: [String]
        let areasForImprovement: [String]
        let recommendedFocus: String

        struct SkillScore: Equatable, Identifiable {
            let id: String
            let skillType: String
            let score: Double
            let label: String
        }
    }

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        learnerModel: LearnerModelServiceProtocol,
        userId: UUID,
        learnerLevel: String
    ) {
        self.claudeService = claudeService
        self.learnerModel = learnerModel
        self.userId = userId
        self.learnerLevel = learnerLevel
    }

    // MARK: - Actions

    func loadChallenge(availableContent: [MediaContent]) {
        // Select unseen content matching learner's level
        let candidates = availableContent.filter { content in
            content.cefrLevel == learnerLevel || content.cefrLevel == nextLevel(from: learnerLevel)
        }
        challengeContent = candidates.randomElement() ?? availableContent.first

        // Generate assessment questions
        generateQuestions()
    }

    func startChallenge() {
        phase = .mediaPlayback
    }

    func completeMediaPlayback() {
        questionStartedAt = Date()
        phase = .questions
    }

    var currentQuestion: ChallengeQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var questionProgress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        let isCorrect = answer == question.correctAnswer
        let responseTime = Date().timeIntervalSince(questionStartedAt)

        let result = ChallengeAnswer(
            questionId: question.id,
            selectedAnswer: answer,
            wasCorrect: isCorrect,
            responseTime: responseTime
        )
        answers.append(result)
        currentQuestionIndex += 1
        questionStartedAt = Date()

        if currentQuestionIndex >= questions.count {
            buildReport()
            phase = .results
        }
    }

    // MARK: - Private

    private func generateQuestions() {
        guard let content = challengeContent else { return }

        let analysis = KoreanTextAnalyzer.analyzeText(content.transcriptKr)
        let primaryTag = content.tags.first?.capitalized ?? "Daily Life"
        let topicOptions = makeOptions(
            correct: primaryTag,
            distractors: ["Relationships", "Work", "Travel", "Food", "School"]
        )

        let grammarPattern = analysis.detectedGrammarPatterns.first ?? "polite ending -아/어요"
        let grammarOptions = makeOptions(
            correct: grammarPattern,
            distractors: [
                "contrast -지만",
                "conditional -으면/면",
                "honorific -세요",
                "reason -기 때문에"
            ]
        )

        let salientWord = analysis.tokens
            .sorted {
                (KoreanTextAnalyzer.frequencyRank(for: $0) ?? Int.max) <
                (KoreanTextAnalyzer.frequencyRank(for: $1) ?? Int.max)
            }
            .first ?? "한국어"

        let vocabOptions = makeOptions(
            correct: salientWord,
            distractors: ["시간", "사람", "마음", "여행", "음식"]
        )

        let formality = estimateFormality(from: content.transcriptKr)
        let formalityOptions = makeOptions(
            correct: formality,
            distractors: ["Very formal", "Casual", "Mixed", "Narrative"]
        )

        let tone = estimateTone(from: content.transcriptKr)
        let toneOptions = makeOptions(
            correct: tone,
            distractors: ["Happy", "Neutral", "Worried", "Excited", "Serious"]
        )

        questions = [
            ChallengeQuestion(
                id: UUID(),
                prompt: "What is the main topic of this content?",
                options: topicOptions,
                correctAnswer: primaryTag,
                skillTested: content.durationSeconds > 0 ? "listening" : "reading",
                cefrLevel: learnerLevel
            ),
            ChallengeQuestion(
                id: UUID(),
                prompt: "Which grammar pattern is used most frequently?",
                options: grammarOptions,
                correctAnswer: grammarPattern,
                skillTested: "grammar",
                cefrLevel: learnerLevel
            ),
            ChallengeQuestion(
                id: UUID(),
                prompt: "Which keyword appears as a core idea in this content?",
                options: vocabOptions,
                correctAnswer: salientWord,
                skillTested: "vocab_recognition",
                cefrLevel: learnerLevel
            ),
            ChallengeQuestion(
                id: UUID(),
                prompt: "What is the formality level of the dialogue?",
                options: formalityOptions,
                correctAnswer: formality,
                skillTested: "grammar",
                cefrLevel: learnerLevel
            ),
            ChallengeQuestion(
                id: UUID(),
                prompt: "Which word best summarizes the speaker's tone?",
                options: toneOptions,
                correctAnswer: tone,
                skillTested: content.durationSeconds > 0 ? "listening" : "reading",
                cefrLevel: learnerLevel
            ),
        ]
    }

    private func makeOptions(correct: String, distractors: [String]) -> [String] {
        var options = Array(distractors.prefix(3))
        if !options.contains(correct) {
            options.append(correct)
        }
        return options.shuffled()
    }

    private func estimateFormality(from transcript: String) -> String {
        if transcript.contains("습니다") || transcript.contains("하십시오") {
            return "Very formal"
        }
        if transcript.contains("요") {
            return "Polite"
        }
        if transcript.contains("야") || transcript.contains("해?") {
            return "Casual"
        }
        return "Mixed"
    }

    private func estimateTone(from transcript: String) -> String {
        if transcript.contains("!") {
            return "Excited"
        }
        if transcript.contains("미안") || transcript.contains("걱정") {
            return "Worried"
        }
        if transcript.contains("좋") || transcript.contains("행복") {
            return "Happy"
        }
        return "Neutral"
    }

    private func buildReport() {
        let overallScore = answers.isEmpty ? 0 : Double(answers.filter { $0.wasCorrect }.count) / Double(answers.count)

        // Compute per-skill scores
        var skillScores: [String: (correct: Int, total: Int)] = [:]
        for (index, answer) in answers.enumerated() {
            guard index < questions.count else { break }
            let skill = questions[index].skillTested
            var current = skillScores[skill] ?? (correct: 0, total: 0)
            current.total += 1
            if answer.wasCorrect { current.correct += 1 }
            skillScores[skill] = current
        }

        let breakdown = skillScores.map { skill, counts in
            ChallengeReport.SkillScore(
                id: skill,
                skillType: skill,
                score: counts.total > 0 ? Double(counts.correct) / Double(counts.total) : 0,
                label: skillLabel(skill)
            )
        }.sorted { $0.score > $1.score }

        let strengths = breakdown.filter { $0.score >= 0.7 }.map { $0.label }
        let weaknesses = breakdown.filter { $0.score < 0.5 }.map { $0.label }

        let estimatedLevel: String
        if overallScore >= 0.85 { estimatedLevel = nextLevel(from: learnerLevel) }
        else if overallScore >= 0.5 { estimatedLevel = learnerLevel }
        else { estimatedLevel = previousLevel(from: learnerLevel) }

        report = ChallengeReport(
            overallScore: overallScore,
            cefrEstimate: estimatedLevel,
            skillBreakdown: breakdown,
            strengths: strengths.isEmpty ? ["Keep practicing!"] : strengths,
            areasForImprovement: weaknesses.isEmpty ? ["Well-rounded skills"] : weaknesses,
            recommendedFocus: weaknesses.first ?? "Continue with current plan"
        )

        // Update learner model with challenge results
        Task {
            for (index, answer) in answers.enumerated() {
                guard index < questions.count else { break }
                let question = questions[index]
                try? await learnerModel.updateMastery(
                    userId: userId,
                    skillType: question.skillTested,
                    skillId: "challenge_\(question.id)",
                    wasCorrect: answer.wasCorrect,
                    responseTime: answer.responseTime
                )
            }
        }
    }

    private func skillLabel(_ skillType: String) -> String {
        switch skillType {
        case "listening": return "Listening"
        case "reading": return "Reading"
        case "grammar": return "Grammar"
        case "vocab_recognition": return "Vocabulary"
        case "pronunciation": return "Pronunciation"
        default: return skillType.capitalized
        }
    }

    private func nextLevel(from level: String) -> String {
        switch level {
        case "pre-A1": return "A1"
        case "A1": return "A2"
        case "A2": return "B1"
        case "B1": return "B2"
        default: return "B2"
        }
    }

    private func previousLevel(from level: String) -> String {
        switch level {
        case "B2": return "B1"
        case "B1": return "A2"
        case "A2": return "A1"
        case "A1": return "pre-A1"
        default: return "pre-A1"
        }
    }
}

// MARK: - Media Challenge View

struct MediaChallengeView: View {
    @State var viewModel: MediaChallengeViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .intro:
                    introView
                case .mediaPlayback:
                    mediaPlaybackView
                case .questions:
                    questionView
                case .results:
                    resultsView
                }
            }
            .navigationTitle("Monthly Challenge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .scaledFont(size: 60)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Monthly Proficiency Challenge")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Test your Korean skills with unseen media content. No scaffolding — just you and the Korean language.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Label("Watch/read without help", systemImage: "eye.fill")
                Label("Answer comprehension questions", systemImage: "questionmark.circle.fill")
                Label("Get a detailed skill report", systemImage: "chart.bar.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                viewModel.startChallenge()
            } label: {
                Text("Begin Challenge")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .accessibilityLabel("Begin monthly challenge")
        }
        .padding()
    }

    // MARK: - Media Playback

    private var mediaPlaybackView: some View {
        VStack(spacing: 16) {
            if let content = viewModel.challengeContent {
                Text(content.title)
                    .font(.headline)

                Text("Watch or read this content without subtitles or help.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                MediaPlayerView(content: content)
                    .environment(\.subtitleModeOverride, .none)
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Challenge media content: \(content.title)")

                Spacer()

                Button {
                    viewModel.completeMediaPlayback()
                } label: {
                    Text("I'm Done Watching")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - Questions

    private var questionView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.questionProgress)
                .tint(.blue)
                .accessibilityLabel("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")

            if let question = viewModel.currentQuestion {
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(question.prompt)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()

                VStack(spacing: 10) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            viewModel.submitAnswer(option)
                        } label: {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Answer: \(option)")
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            if let report = viewModel.report {
                VStack(spacing: 24) {
                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        Circle()
                            .trim(from: 0, to: report.overallScore)
                            .stroke(scoreColor(report.overallScore), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(Int(report.overallScore * 100))%")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(report.cefrEstimate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Score: \(Int(report.overallScore * 100)) percent. Estimated level: \(report.cefrEstimate)")

                    // Skill breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skill Breakdown")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(report.skillBreakdown) { skill in
                            HStack {
                                Text(skill.label)
                                    .font(.subheadline)
                                    .frame(width: 100, alignment: .leading)
                                ProgressView(value: skill.score)
                                    .tint(scoreColor(skill.score))
                                Text("\(Int(skill.score * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(skill.label): \(Int(skill.score * 100)) percent")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Strengths
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Strengths", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        ForEach(report.strengths, id: \.self) { strength in
                            Text("• \(strength)")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Areas for improvement
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Focus Areas", systemImage: "target")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        ForEach(report.areasForImprovement, id: \.self) { area in
                            Text("• \(area)")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Recommendation
                    Text("Recommended focus: \(report.recommendedFocus)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .padding()
            }
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.7 { return .green }
        if score >= 0.5 { return .orange }
        return .red
    }
}
