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
        // Prefer transcript-rich content at or just above the learner's level.
        let candidates = availableContent.filter { content in
            hasUsableTranscript(content)
        }
        let filtered = candidates.isEmpty ? availableContent : candidates
        challengeContent = filtered.sorted { lhs, rhs in
            contentPriority(lhs) < contentPriority(rhs)
        }.first ?? availableContent.first

        phase = .intro
        currentQuestionIndex = 0
        answers = []
        report = nil

        // Generate assessment questions
        generateQuestions(for: challengeContent)
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

    private func generateQuestions(for content: MediaContent?) {
        guard let content else { return }

        let transcriptLines = transcriptLines(for: content)
        let profile = analyze(content: content, transcriptLines: transcriptLines)

        questions = [
            structureQuestion(profile: profile),
            contentTypeQuestion(content: content, profile: profile),
            toneQuestion(profile: profile),
            detailQuestion(profile: profile),
            topicQuestion(content: content, profile: profile)
        ]
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

        let estimatedLevel = estimateLevel(
            overallScore: overallScore,
            skillBreakdown: breakdown
        )

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

    private func hasUsableTranscript(_ content: MediaContent) -> Bool {
        !content.transcriptKr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !content.transcriptSegments.isEmpty
    }

    private func contentPriority(_ content: MediaContent) -> Int {
        let levelDistance = abs(levelIndex(content.cefrLevel) - levelIndex(learnerLevel))
        let richnessPenalty = content.transcriptSegments.isEmpty ? 2 : 0
        let lengthPenalty = content.transcriptKr.count > 0 ? max(0, 4 - min(content.transcriptKr.count / 80, 4)) : 4
        let difficultyBias = Int((content.difficultyScore * 10).rounded())
        return levelDistance * 10 + richnessPenalty * 3 + lengthPenalty + difficultyBias
    }

    private func analyze(content: MediaContent, transcriptLines: [String]) -> ContentProfile {
        let cleanedLines = transcriptLines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let normalizedTranscript = content.transcriptKr.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = content.tags.map { $0.lowercased() }
        let keywords = extractKeywords(from: cleanedLines.isEmpty ? [normalizedTranscript] : cleanedLines)

        return ContentProfile(
            contentType: contentTypeLabel(content.contentType),
            segmentCount: max(cleanedLines.count, content.transcriptSegments.count, normalizedTranscript.isEmpty ? 0 : 1),
            tone: inferTone(from: normalizedTranscript, transcriptLines: cleanedLines),
            topic: inferTopic(content: content, keywords: keywords, tags: tags),
            firstLine: cleanedLines.first ?? normalizedTranscript,
            transcriptLines: cleanedLines
        )
    }

    private func structureQuestion(profile: ContentProfile) -> ChallengeQuestion {
        let count = max(profile.segmentCount, 1)
        let options = uniqueOptions([
            count == 1 ? "1 segment" : "\(count) segments",
            count == 2 ? "2 segments" : "2 segments",
            count == 3 ? "3 segments" : "3 segments",
            "4+ segments"
        ], fallback: ["1 segment", "2 segments", "3 segments", "4+ segments"])

        return ChallengeQuestion(
            id: UUID(),
            prompt: "How many spoken segments does this selection contain?",
            options: options,
            correctAnswer: count == 1 ? "1 segment" : count == 2 ? "2 segments" : count == 3 ? "3 segments" : "4+ segments",
            skillTested: "listening",
            cefrLevel: contentLevelForQuestion()
        )
    }

    private func contentTypeQuestion(content: MediaContent, profile: ContentProfile) -> ChallengeQuestion {
        let correct = profile.contentType
        let distractors = ["Drama", "Webtoon", "News", "Music", "Short video"]
            .filter { $0 != correct }
            .prefix(3)
        let options = uniqueOptions(Array([correct] + Array(distractors)), fallback: [correct, "Drama", "Webtoon", "News"])

        return ChallengeQuestion(
            id: UUID(),
            prompt: "What type of media is this?",
            options: options,
            correctAnswer: correct,
            skillTested: "reading",
            cefrLevel: content.cefrLevel
        )
    }

    private func toneQuestion(profile: ContentProfile) -> ChallengeQuestion {
        let correct = profile.tone
        let options = uniqueOptions([
            correct,
            "Formal",
            "Casual",
            "Mixed"
        ], fallback: ["Formal", "Polite", "Casual", "Mixed"])

        return ChallengeQuestion(
            id: UUID(),
            prompt: "What best describes the speaking style?",
            options: options,
            correctAnswer: correct,
            skillTested: "grammar",
            cefrLevel: contentLevelForQuestion()
        )
    }

    private func detailQuestion(profile: ContentProfile) -> ChallengeQuestion {
        let correct = profile.firstLine.isEmpty ? "No clear line" : profile.firstLine
        let distractors = Array(profile.transcriptLines.dropFirst().prefix(3))
        let options = uniqueOptions(Array(([correct] + distractors).prefix(4)), fallback: [correct, "The speaker is greeting someone", "Someone is asking a question", "A response is given"])

        return ChallengeQuestion(
            id: UUID(),
            prompt: "Which line appears first in the transcript?",
            options: options,
            correctAnswer: correct,
            skillTested: "listening",
            cefrLevel: contentLevelForQuestion()
        )
    }

    private func topicQuestion(content: MediaContent, profile: ContentProfile) -> ChallengeQuestion {
        let correct = profile.topic
        let fallbackTopics = [
            "Daily life",
            "Relationships",
            "Workplace",
            "Food",
            "Travel",
            "School",
            "Entertainment",
            "Technology"
        ]
        let distractors = fallbackTopics.filter { $0 != correct }.prefix(3)
        let options = uniqueOptions(Array([correct] + Array(distractors)), fallback: [correct, "Daily life", "Relationships", "Workplace"])

        return ChallengeQuestion(
            id: UUID(),
            prompt: "Which theme best fits this selection?",
            options: options,
            correctAnswer: correct,
            skillTested: "vocab_recognition",
            cefrLevel: content.cefrLevel
        )
    }

    private func estimateLevel(overallScore: Double, skillBreakdown: [ChallengeReport.SkillScore]) -> String {
        let orderedLevels = ["pre-A1", "A1", "A2", "B1", "B2"]
        let currentIndex = levelIndex(learnerLevel)
        let breadth = Double(skillBreakdown.filter { $0.score >= 0.6 }.count) / Double(max(skillBreakdown.count, 1))
        let strongSkills = Double(skillBreakdown.filter { $0.score >= 0.75 }.count)

        let weightedCorrectness = zip(answers, questions).reduce(0.0) { sum, pair in
            let answer = pair.0
            let question = pair.1
            let difficulty = questionDifficultyWeight(question.cefrLevel)
            let speed = responseEfficiency(for: answer.responseTime)
            guard answer.wasCorrect else { return sum }
            return sum + difficulty * speed
        }

        let totalDifficulty = zip(answers, questions).reduce(0.0) { sum, pair in
            sum + questionDifficultyWeight(pair.1.cefrLevel)
        }

        let readiness = totalDifficulty > 0 ? min(weightedCorrectness / totalDifficulty, 1.0) : overallScore
        let composite = readiness * 0.7 + breadth * 0.15 + min(strongSkills / 3.0, 1.0) * 0.15

        let delta: Int
        switch composite {
        case ..<0.25:
            delta = -1
        case ..<0.45:
            delta = 0
        case ..<0.70:
            delta = 1
        default:
            delta = 2
        }

        let targetIndex = min(max(currentIndex + delta, 0), orderedLevels.count - 1)
        return orderedLevels[targetIndex]
    }

    private func levelIndex(_ level: String) -> Int {
        ["pre-A1", "A1", "A2", "B1", "B2"].firstIndex(of: level) ?? 1
    }

    private func contentTypeLabel(_ contentType: String) -> String {
        switch contentType.lowercased() {
        case "drama": return "Drama"
        case "webtoon": return "Webtoon"
        case "news": return "News"
        case "short_video": return "Short video"
        case "music": return "Music"
        default: return contentType.capitalized
        }
    }

    private func inferTone(from transcript: String, transcriptLines: [String]) -> String {
        let joined = ([transcript] + transcriptLines).joined(separator: " ")
        let politeMarkers = ["습니다", "니다", "세요", "시", "주세요", "드립니다", "해요", "예요"]
        let casualMarkers = ["해", "했어", "있어", "가자", "줘", "야", "어"]

        let politeCount = politeMarkers.reduce(0) { $0 + joined.components(separatedBy: $1).count - 1 }
        let casualCount = casualMarkers.reduce(0) { $0 + joined.components(separatedBy: $1).count - 1 }

        if politeCount > 0 && casualCount > 0 { return "Mixed" }
        if politeCount > 0 { return "Polite" }
        if casualCount > 0 { return "Casual" }
        return "Formal"
    }

    private func inferTopic(content: MediaContent, keywords: [String], tags: [String]) -> String {
        let allSignals = Set((keywords + tags + [content.title, content.source]).map { $0.lowercased() })
        let topicMap: [(String, [String])] = [
            ("Food", ["food", "eat", "coffee", "ramyeon", "market", "cafe", "restaurant", "gimbap", "kimchi"]),
            ("Workplace", ["work", "office", "job", "employee", "company"]),
            ("Relationships", ["love", "friend", "confession", "romance", "family", "date"]),
            ("Travel", ["travel", "station", "trip", "train", "subway", "walk"]),
            ("School", ["school", "student", "class", "test", "exam"]),
            ("Entertainment", ["drama", "music", "song", "dance", "k-pop", "video"]),
            ("Health", ["hospital", "doctor", "patient", "health", "surgery"]),
            ("Weather", ["weather", "rain", "sun", "spring"])
        ]

        let bestTopic = topicMap.first { _, cues in
            cues.contains { cue in allSignals.contains(where: { $0.contains(cue) }) }
        }?.0

        return bestTopic ?? tags.first.map { $0.capitalized } ?? contentTypeLabel(content.contentType)
    }

    private func extractKeywords(from lines: [String]) -> [String] {
        let particles = Set(["이", "가", "을", "를", "은", "는", "에", "의", "도", "만", "과", "와", "로", "에서", "하다", "한다"])
        let words = lines
            .joined(separator: " ")
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 1 }

        var seen: Set<String> = []
        var keywords: [String] = []
        for word in words where !particles.contains(word) {
            if seen.insert(word).inserted {
                keywords.append(word)
            }
            if keywords.count == 4 { break }
        }
        return keywords
    }

    private func transcriptLines(for content: MediaContent) -> [String] {
        let segmentLines = content.transcriptSegments.map(\.textKr).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !segmentLines.isEmpty {
            return segmentLines
        }

        return content.transcriptKr
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func questionDifficultyWeight(_ level: String) -> Double {
        switch level {
        case "B2": return 1.4
        case "B1": return 1.2
        case "A2": return 1.0
        case "A1": return 0.8
        default: return 0.6
        }
    }

    private func responseEfficiency(for responseTime: TimeInterval) -> Double {
        switch responseTime {
        case ..<4:
            return 1.1
        case ..<8:
            return 1.0
        case ..<14:
            return 0.9
        default:
            return 0.8
        }
    }

    private func uniqueOptions<S: Sequence>(_ options: S, fallback: [String]) -> [String] where S.Element == String {
        var seen: Set<String> = []
        let unique = options.filter { seen.insert($0).inserted }
        if unique.count >= 4 {
            return Array(unique.prefix(4))
        }

        var merged = unique
        for item in fallback where merged.count < 4 && !seen.contains(item) {
            merged.append(item)
            seen.insert(item)
        }
        return Array(merged.prefix(4))
    }

    private func contentLevelForQuestion() -> String {
        if let content = challengeContent {
            return content.cefrLevel
        }
        return learnerLevel
    }

    private struct ContentProfile {
        let contentType: String
        let segmentCount: Int
        let tone: String
        let topic: String
        let firstLine: String
        let transcriptLines: [String]
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
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
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
                                .background(Color.gray.opacity(0.15))
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
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
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
                    .background(Color.gray.opacity(0.12))
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
