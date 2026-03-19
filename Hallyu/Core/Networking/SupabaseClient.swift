import Foundation

struct SupabaseConfig {
    let projectURL: URL
    let anonKey: String
    let serviceRoleKey: String?
    let isConfigured: Bool

    static var debug: SupabaseConfig {
        fromRuntimeConfiguration()
    }

    static var release: SupabaseConfig {
        fromRuntimeConfiguration()
    }

    static var current: SupabaseConfig {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    private static func fromRuntimeConfiguration() -> SupabaseConfig {
        let urlString = value(for: "SUPABASE_PROJECT_URL")
        let anonKey = value(for: "SUPABASE_ANON_KEY")
        let serviceRoleKey = value(for: "SUPABASE_SERVICE_ROLE_KEY")

        if let urlString,
           let projectURL = URL(string: urlString),
           let anonKey,
           !anonKey.isEmpty {
            return SupabaseConfig(
                projectURL: projectURL,
                anonKey: anonKey,
                serviceRoleKey: serviceRoleKey,
                isConfigured: true
            )
        }

        return SupabaseConfig(
            projectURL: URL(string: "https://invalid.supabase.local")!,
            anonKey: "",
            serviceRoleKey: nil,
            isConfigured: false
        )
    }

    private static func value(for key: String) -> String? {
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !plistValue.isEmpty {
            return plistValue
        }

        return nil
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
