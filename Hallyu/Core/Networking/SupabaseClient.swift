import Foundation

struct SupabaseConfig {
    let projectURL: URL
    let anonKey: String
    let serviceRoleKey: String?

    static var debug: SupabaseConfig {
        SupabaseConfig(
            projectURL: URL(string: "https://placeholder.supabase.co")!,
            anonKey: "placeholder-anon-key",
            serviceRoleKey: nil
        )
    }

    static var release: SupabaseConfig {
        SupabaseConfig(
            projectURL: URL(string: "https://placeholder.supabase.co")!,
            anonKey: "placeholder-anon-key",
            serviceRoleKey: nil
        )
    }

    static var current: SupabaseConfig {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
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

    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }

    // MARK: - CRUD Operations

    func fetch<T: Decodable>(
        from table: String,
        query: [URLQueryItem] = [],
        single: Bool = false
    ) async throws -> T {
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
