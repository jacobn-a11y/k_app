import Foundation

actor ClaudeService: ClaudeServiceProtocol {
    private let apiClient: APIClient
    private let cache: ResponseCache
    private var dailyTokenCount: Int = 0
    private var dailyTokenDate: Date = Date()

    init(apiKey: String = AppEnvironment.current.claudeAPIKey) {
        self.apiClient = APIClient(
            baseURL: AppEnvironment.current.claudeAPIBaseURL,
            defaultHeaders: [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            ]
        )
        self.cache = ResponseCache()
    }

    nonisolated func getComprehensionHelp(context: ComprehensionContext, query: String) async throws -> ComprehensionResponse {
        let prompt = ClaudePrompts.comprehensionPrompt(context: context, query: query)
        let cacheKey = ResponseCache.key(for: "comprehension", context: "\(context.targetWord)_\(context.learnerLevel)")

        if let cached: ComprehensionResponse = await cache.get(for: cacheKey) {
            return cached
        }

        let response: ComprehensionResponse = try await sendMessage(
            systemPrompt: ClaudePrompts.systemPrompt(learnerLevel: context.learnerLevel),
            userMessage: prompt
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    nonisolated func getPronunciationFeedback(transcript: String, target: String) async throws -> PronunciationFeedback {
        let prompt = ClaudePrompts.pronunciationPrompt(transcript: transcript, target: target)
        return try await sendMessage(
            systemPrompt: ClaudePrompts.pronunciationSystemPrompt,
            userMessage: prompt
        )
    }

    nonisolated func getGrammarExplanation(pattern: String, context: String) async throws -> GrammarExplanation {
        let prompt = ClaudePrompts.grammarPrompt(pattern: pattern, context: context)
        let cacheKey = ResponseCache.key(for: "grammar", context: pattern)

        if let cached: GrammarExplanation = await cache.get(for: cacheKey) {
            return cached
        }

        let response: GrammarExplanation = try await sendMessage(
            systemPrompt: ClaudePrompts.grammarSystemPrompt,
            userMessage: prompt
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    nonisolated func generatePracticeItems(mediaContentId: UUID, learnerLevel: String) async throws -> [PracticeItem] {
        let prompt = ClaudePrompts.practiceGenerationPrompt(mediaContentId: mediaContentId, learnerLevel: learnerLevel)
        return try await sendMessage(
            systemPrompt: ClaudePrompts.contentAdapterSystemPrompt,
            userMessage: prompt
        )
    }

    nonisolated func getCulturalContext(moment: String, mediaContext: String) async throws -> CulturalContextResponse {
        let prompt = ClaudePrompts.culturalContextPrompt(moment: moment, mediaContext: mediaContext)
        let cacheKey = ResponseCache.key(for: "cultural", context: moment)

        if let cached: CulturalContextResponse = await cache.get(for: cacheKey) {
            return cached
        }

        let response: CulturalContextResponse = try await sendMessage(
            systemPrompt: ClaudePrompts.culturalContextSystemPrompt,
            userMessage: prompt
        )
        await cache.set(response, for: cacheKey)
        return response
    }

    // MARK: - Private

    private func sendMessage<T: Decodable>(systemPrompt: String, userMessage: String) async throws -> T {
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
        case .tierLimitReached: return "Daily interaction limit reached"
        }
    }
}

// MARK: - Response Cache

actor ResponseCache {
    private var cache: [String: (data: Data, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 3600 // 1 hour

    static func key(for role: String, context: String) -> String {
        let input = "\(role)_\(context)"
        // Simple hash for cache key
        var hash: UInt64 = 5381
        for byte in input.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash)
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
}
