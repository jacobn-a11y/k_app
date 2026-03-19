import Foundation
import CommonCrypto

actor ClaudeService: ClaudeServiceProtocol {
    private let apiClient: APIClient
    private let cache: ResponseCache
    private let interactionTracker: InteractionTracker
    private let tierProvider: @Sendable () -> AppState.SubscriptionTier

    init(
        apiKey: String = AppEnvironment.current.claudeAPIKey,
        tierProvider: @escaping @Sendable () -> AppState.SubscriptionTier = { .free }
    ) {
        self.apiClient = APIClient(
            baseURL: AppEnvironment.current.claudeAPIBaseURL,
            defaultHeaders: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            ]
        )
        self.cache = ResponseCache()
        self.interactionTracker = InteractionTracker()
        self.tierProvider = tierProvider
    }

    // MARK: - Tier Enforcement

    func checkTierAllowed(tier: AppState.SubscriptionTier) async throws {
        let limits = ClaudeTierLimits.limits(for: tier)
        let todayCount = await interactionTracker.todayCount
        guard limits.isAllowed(currentCount: todayCount) else {
            throw ClaudeServiceError.tierLimitReached
        }
    }

    // MARK: - Rate Limiting

    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0

    private func enforceRateLimit() throws {
        if let lastTime = lastRequestTime,
           Date().timeIntervalSince(lastTime) < minRequestInterval {
            throw ClaudeServiceError.rateLimitExceeded
        }
    }

    func getDailyInteractionCount() -> Int {
        interactionTracker.todayCount
    }

    func getDailyInteractionLimit(for tier: AppState.SubscriptionTier) -> Int? {
        ClaudeTierLimits.limits(for: tier).dailyLimit
    }

    // MARK: - Role 1: Comprehension Coach

    nonisolated func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
        let prompt = ClaudePrompts.comprehensionPrompt(context: context, query: query)
        let cacheKey = ResponseCache.key(for: "comprehension", context: "\(context.targetWord)_\(context.learnerLevel)")

        if let cached: ComprehensionResponse = await cache.get(for: cacheKey) {
            return cached
        }

        let response: ComprehensionResponse = try await sendMessage(
            systemPrompt: ClaudePrompts.systemPrompt(learnerLevel: context.learnerLevel),
            userMessage: prompt,
            role: .comprehension
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    // MARK: - Role 2: Pronunciation Tutor

    nonisolated func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
        let prompt = ClaudePrompts.pronunciationPrompt(transcript: transcript, target: target)
        return try await sendMessage(
            systemPrompt: ClaudePrompts.pronunciationSystemPrompt,
            userMessage: prompt,
            role: .pronunciation
        )
    }

    // MARK: - Role 3: Grammar Explainer

    nonisolated func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
        let prompt = ClaudePrompts.grammarPrompt(pattern: pattern, context: context)
        let cacheKey = ResponseCache.key(for: "grammar", context: pattern)

        if let cached: GrammarExplanation = await cache.get(for: cacheKey) {
            return cached
        }

        let response: GrammarExplanation = try await sendMessage(
            systemPrompt: ClaudePrompts.grammarSystemPrompt,
            userMessage: prompt,
            role: .grammar
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    // MARK: - Role 4: Content Adapter

    nonisolated func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
        let prompt = ClaudePrompts.practiceGenerationPrompt(mediaContentId: mediaContentId, learnerLevel: learnerLevel)
        return try await sendMessage(
            systemPrompt: ClaudePrompts.contentAdapterSystemPrompt,
            userMessage: prompt,
            role: .contentAdapter
        )
    }

    nonisolated func generateEnhancedPracticeItems(
        mediaTranscript: String,
        vocabularyWords: [String],
        grammarPatterns: [String],
        learnerLevel: String
    ) async throws -> [EnhancedPracticeItem] {
        let prompt = ClaudePrompts.practiceGenerationPrompt(
            mediaTranscript: mediaTranscript,
            vocabularyWords: vocabularyWords,
            grammarPatterns: grammarPatterns,
            learnerLevel: learnerLevel
        )
        return try await sendMessage(
            systemPrompt: ClaudePrompts.contentAdapterSystemPrompt,
            userMessage: prompt,
            role: .contentAdapter
        )
    }

    // MARK: - Role 5: Cultural Context

    nonisolated func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
        let prompt = ClaudePrompts.culturalContextPrompt(moment: moment, mediaContext: mediaContext)
        let cacheKey = ResponseCache.key(for: "cultural", context: moment)

        if let cached: CulturalContextResponse = await cache.get(for: cacheKey) {
            return cached
        }

        let response: CulturalContextResponse = try await sendMessage(
            systemPrompt: ClaudePrompts.culturalContextSystemPrompt,
            userMessage: prompt,
            role: .cultural
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    // MARK: - Private

    private func sendMessage<T: Decodable>(systemPrompt: String, userMessage: String, role: ClaudeRole) async throws -> T {
        let tier = tierProvider()
        try await checkTierAllowed(tier: tier)
        try enforceRateLimit()
        lastRequestTime = Date()

        let requestBody = ClaudeAPIRequest(
            model: "claude-sonnet-4-20250514",
            maxTokens: 1024,
            system: systemPrompt,
            messages: [
                ClaudeMessage(role: "user", content: userMessage)
            ]
        )

        let request = try APIRequest(
            path: "/v1/messages",
            method: .post,
            body: requestBody
        )

        let apiResponse: ClaudeAPIResponse = try await apiClient.send(request)

        // Track interaction
        await interactionTracker.recordInteraction(
            role: role,
            promptTokens: apiResponse.usage.inputTokens,
            completionTokens: apiResponse.usage.outputTokens
        )

        guard let textContent = apiResponse.content.first?.text else {
            throw ClaudeServiceError.emptyResponse
        }

        let decoder = JSONDecoder()
        guard let data = textContent.data(using: .utf8) else {
            throw ClaudeServiceError.invalidResponseFormat
        }

        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - API Types

struct ClaudeAPIRequest: Codable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeAPIResponse: Codable {
    let id: String
    let content: [ClaudeContentBlock]
    let usage: ClaudeUsage

    struct ClaudeContentBlock: Codable {
        let type: String
        let text: String?
    }

    struct ClaudeUsage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
}

enum ClaudeServiceError: Error, LocalizedError {
    case emptyResponse
    case invalidResponseFormat
    case rateLimitExceeded
    case tierLimitReached

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Empty response from Claude"
        case .invalidResponseFormat: return "Invalid response format"
        case .rateLimitExceeded: return "Rate limit exceeded"
        case .tierLimitReached: return "Daily interaction limit reached for your subscription tier"
        }
    }
}

// MARK: - Response Cache

actor ResponseCache {
    private var cache: [String: (data: Data, timestamp: Date)] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 3600) {
        self.ttl = ttl
    }

    static func key(for role: String, context: String) -> String {
        let input = "\(role)_\(context)"
        // SHA-256 hash for cache key to avoid collisions
        let data = input.data(using: .utf8) ?? Data()
        var hash = [UInt8](repeating: 0, count: 32)
        _ = data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func get<T: Decodable>(for key: String) -> T? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < ttl else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: entry.data)
    }

    func set<T: Encodable>(_ value: T, for key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        cache[key] = (data: data, timestamp: Date())
    }

    func clear() {
        cache.removeAll()
    }

    var count: Int {
        cache.count
    }

    var isEmpty: Bool {
        cache.isEmpty
    }

    func purgeExpired() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) < ttl }
    }
}

// MARK: - Interaction Tracker

actor InteractionTracker {
    struct DailyRecord {
        var date: Date
        var interactions: [InteractionEntry] = []

        var count: Int { interactions.count }

        var totalPromptTokens: Int {
            interactions.reduce(0) { $0 + $1.promptTokens }
        }

        var totalCompletionTokens: Int {
            interactions.reduce(0) { $0 + $1.completionTokens }
        }

        func count(for role: ClaudeRole) -> Int {
            interactions.filter { $0.role == role }.count
        }
    }

    struct InteractionEntry {
        let role: ClaudeRole
        let promptTokens: Int
        let completionTokens: Int
        let timestamp: Date
    }

    private var dailyRecord: DailyRecord

    init() {
        self.dailyRecord = DailyRecord(date: Date())
    }

    var todayCount: Int {
        ensureCurrentDay()
        return dailyRecord.count
    }

    var totalTokensToday: Int {
        ensureCurrentDay()
        return dailyRecord.totalPromptTokens + dailyRecord.totalCompletionTokens
    }

    func count(for role: ClaudeRole) -> Int {
        ensureCurrentDay()
        return dailyRecord.count(for: role)
    }

    func recordInteraction(role: ClaudeRole, promptTokens: Int, completionTokens: Int) {
        ensureCurrentDay()
        let entry = InteractionEntry(
            role: role,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            timestamp: Date()
        )
        dailyRecord.interactions.append(entry)
    }

    private func ensureCurrentDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(dailyRecord.date) {
            dailyRecord = DailyRecord(date: Date())
        }
    }
}
