import Foundation

struct SupabaseConfig {
    let projectURL: URL
    let anonKey: String
    let serviceRoleKey: String?
    let isConfigured: Bool

    private static let placeholderProjectURL = URL(string: "https://placeholder.supabase.co")!
    private static let placeholderAnonKey = "placeholder-anon-key"
    private static let supabaseURLKey = "SUPABASE_URL"
    private static let supabaseAnonKey = "SUPABASE_ANON_KEY"
    private static let supabaseServiceRoleKey = "SUPABASE_SERVICE_ROLE_KEY"
    private static let pushRegistrationFunctionKey = "SUPABASE_PUSH_REGISTRATION_FUNCTION"

    enum SupabaseConfigError: Error, LocalizedError {
        case missingValue(String)
        case invalidURL(String)
        case insecureScheme(String)

        var errorDescription: String? {
            switch self {
            case .missingValue(let key):
                return "Missing Supabase configuration value for \(key)."
            case .invalidURL(let value):
                return "Invalid Supabase URL: \(value)."
            case .insecureScheme(let value):
                return "Supabase URL must use HTTPS: \(value)."
            }
        }
    }

    static var placeholder: SupabaseConfig {
        SupabaseConfig(
            projectURL: placeholderProjectURL,
            anonKey: placeholderAnonKey,
            serviceRoleKey: nil,
            isConfigured: false
        )
    }

    static var debug: SupabaseConfig {
        placeholder
    }

    static var release: SupabaseConfig {
        current
    }

    static var current: SupabaseConfig {
        (try? resolved(from: ProcessInfo.processInfo.environment)) ?? placeholder
    }

    static func resolved(from environment: [String: String]) throws -> SupabaseConfig {
        if let config = try config(from: environment) {
            return config
        }

        throw SupabaseConfigError.missingValue("SUPABASE_URL or SUPABASE_ANON_KEY")
    }

    static var pushRegistrationFunctionName: String {
        let name = ProcessInfo.processInfo.environment[pushRegistrationFunctionKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false ? name! : "register-device-token")
    }

    private static func config(from environment: [String: String]) throws -> SupabaseConfig? {
        guard let rawURL = environment[supabaseURLKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawURL.isEmpty else {
            return nil
        }
        guard let projectURL = URL(string: rawURL) else {
            throw SupabaseConfigError.invalidURL(rawURL)
        }
        guard projectURL.scheme?.lowercased() == "https" else {
            throw SupabaseConfigError.insecureScheme(rawURL)
        }
        guard let anonKey = environment[supabaseAnonKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !anonKey.isEmpty else {
            return nil
        }

        let serviceRoleKey = environment[supabaseServiceRoleKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return SupabaseConfig(
            projectURL: projectURL,
            anonKey: anonKey,
            serviceRoleKey: serviceRoleKey?.isEmpty == true ? nil : serviceRoleKey,
            isConfigured: true
        )
    }

}

actor SupabaseClient {
    private let config: SupabaseConfig
    private let apiClient: APIClient
    private var accessToken: String?

    init(config: SupabaseConfig = .current) {
        self.config = config
        self.apiClient = APIClient(
            baseURL: config.projectURL.appendingPathComponent("rest/v1"),
            defaultHeaders: [
                "apikey": config.anonKey,
                "Content-Type": "application/json",
                "Prefer": "return=representation"
            ]
        )
    }

    private func ensureConfigured() throws {
        guard config.isConfigured else {
            throw APIError.invalidURL
        }
    }

    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }

    // MARK: - Edge Functions

    func registerPushToken(
        deviceToken: String,
        userId: UUID?,
        notificationsEnabled: Bool,
        reminderHour: Int,
        reminderMinute: Int
    ) async throws {
        guard !deviceToken.isEmpty else { return }
        try ensureConfigured()

        var headers: [String: String] = [:]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = try APIRequest(
            path: SupabaseConfig.pushRegistrationFunctionName,
            method: .post,
            headers: headers,
            body: PushTokenRegistrationRequest(
                userId: userId,
                deviceToken: deviceToken,
                platform: "ios",
                notificationsEnabled: notificationsEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute
            )
        )

        let client = APIClient(
            baseURL: config.projectURL.appendingPathComponent("functions/v1"),
            defaultHeaders: [
                "apikey": config.anonKey,
                "Content-Type": "application/json"
            ]
        )

        _ = try await client.sendRaw(request)
    }

    // MARK: - CRUD Operations

    func fetch<T: Decodable>(
        from table: String,
        query: [URLQueryItem] = [],
        single: Bool = false
    ) async throws -> T {
        try ensureConfigured()
        var headers: [String: String] = [:]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        if single {
            headers["Accept"] = "application/vnd.pgrst.object+json"
        }

        let request = APIRequest(
            path: table,
            method: .get,
            headers: headers,
            queryItems: query
        )

        return try await apiClient.send(request)
    }

    func insert<T: Encodable & Decodable>(
        into table: String,
        values: T
    ) async throws -> T {
        try ensureConfigured()
        var headers: [String: String] = [:]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = try APIRequest(
            path: table,
            method: .post,
            headers: headers,
            body: values
        )

        return try await apiClient.send(request)
    }

    func update<T: Encodable & Decodable>(
        table: String,
        query: [URLQueryItem],
        values: T
    ) async throws -> T {
        try ensureConfigured()
        var headers: [String: String] = [:]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = try APIRequest(
            path: table,
            method: .patch,
            headers: headers,
            queryItems: query,
            body: values
        )

        return try await apiClient.send(request)
    }

    func delete(
        from table: String,
        query: [URLQueryItem]
    ) async throws {
        try ensureConfigured()
        var headers: [String: String] = [:]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = APIRequest(
            path: table,
            method: .delete,
            headers: headers,
            queryItems: query
        )

        _ = try await apiClient.sendRaw(request)
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws -> AuthResponse {
        try ensureConfigured()
        let authClient = APIClient(
            baseURL: config.projectURL.appendingPathComponent("auth/v1"),
            defaultHeaders: [
                "apikey": config.anonKey,
                "Content-Type": "application/json"
            ]
        )

        let body = AuthCredentials(email: email, password: password)
        let request = try APIRequest(path: "signup", method: .post, body: body)
        return try await authClient.send(request)
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        try ensureConfigured()
        let authClient = APIClient(
            baseURL: config.projectURL.appendingPathComponent("auth/v1"),
            defaultHeaders: [
                "apikey": config.anonKey,
                "Content-Type": "application/json"
            ]
        )

        let body = AuthCredentials(email: email, password: password)
        let request = try APIRequest(
            path: "token",
            method: .post,
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: body
        )
        return try await authClient.send(request)
    }
}

// MARK: - Auth Types

struct AuthCredentials: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: AuthUser?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
        case expiresIn = "expires_in"
    }
}

struct AuthUser: Codable {
    let id: UUID
    let email: String?
}

private struct PushTokenRegistrationRequest: Codable {
    let userId: UUID?
    let deviceToken: String
    let platform: String
    let notificationsEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceToken = "device_token"
        case platform
        case notificationsEnabled = "notifications_enabled"
        case reminderHour = "reminder_hour"
        case reminderMinute = "reminder_minute"
    }
}
