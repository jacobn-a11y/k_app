import Foundation

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case sessionExpired
    case notAuthenticated
    case appleSignInFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .emailAlreadyInUse: return "An account with this email already exists."
        case .weakPassword: return "Password must be at least 8 characters."
        case .networkError: return "Network error. Please check your connection."
        case .sessionExpired: return "Your session has expired. Please sign in again."
        case .notAuthenticated: return "You are not signed in."
        case .appleSignInFailed: return "Sign in with Apple failed."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - Auth Service Implementation

final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private let apiClient: APIClient
    private var _currentSession: AuthSession?
    private let sessionKey = "com.hallyu.authSession"

    var currentSession: AuthSession? { _currentSession }
    var isAuthenticated: Bool { _currentSession != nil && !isSessionExpired }

    private var isSessionExpired: Bool {
        guard let session = _currentSession else { return true }
        return session.expiresAt < Date()
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self._currentSession = loadPersistedSession()
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws -> AuthSession {
        // In a real implementation, this would coordinate with ASAuthorizationController
        // to get an Apple ID credential, then exchange it with Supabase.
        let body: [String: String] = ["provider": "apple"]
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let request = APIRequest(
            path: "/auth/v1/token",
            method: .post,
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: bodyData
        )

        let response: AuthSessionResponse = try await apiClient.send(request)
        let authSession = response.toAuthSession()
        _currentSession = authSession
        persistSession(authSession)
        return authSession
    }

    // MARK: - Email/Password

    func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        let request = try APIRequest(
            path: "/auth/v1/token",
            method: .post,
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: EmailAuthRequest(email: email, password: password)
        )

        let response: AuthSessionResponse = try await apiClient.send(request)
        let authSession = response.toAuthSession()
        _currentSession = authSession
        persistSession(authSession)
        return authSession
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        guard !email.isEmpty else {
            throw AuthError.invalidCredentials
        }
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }

        let request = try APIRequest(
            path: "/auth/v1/signup",
            method: .post,
            body: EmailAuthRequest(email: email, password: password)
        )

        let response: AuthSessionResponse = try await apiClient.send(request)
        let authSession = response.toAuthSession()
        _currentSession = authSession
        persistSession(authSession)
        return authSession
    }

    // MARK: - Sign Out

    func signOut() async throws {
        if let token = _currentSession?.accessToken {
            let request = APIRequest(
                path: "/auth/v1/logout",
                method: .post,
                headers: ["Authorization": "Bearer \(token)"],
                body: Data()
            )
            _ = try? await apiClient.sendRaw(request)
        }
        _currentSession = nil
        clearPersistedSession()
    }

    // MARK: - Refresh

    func refreshSession() async throws -> AuthSession {
        guard let session = _currentSession else {
            throw AuthError.notAuthenticated
        }

        let request = try APIRequest(
            path: "/auth/v1/token",
            method: .post,
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: ["refresh_token": session.refreshToken]
        )

        let response: AuthSessionResponse = try await apiClient.send(request)
        let authSession = response.toAuthSession()
        _currentSession = authSession
        persistSession(authSession)
        return authSession
    }

    // MARK: - Session Persistence

    private func persistSession(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func loadPersistedSession() -> AuthSession? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
}

// MARK: - API Response Types

struct AuthSessionResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let user: AuthUserResponse

    func toAuthSession() -> AuthSession {
        AuthSession(
            userId: user.id,
            accessToken: access_token,
            refreshToken: refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(expires_in))
        )
    }
}

struct AuthUserResponse: Codable {
    let id: UUID
    let email: String?
}

struct EmailAuthRequest: Codable {
    let email: String
    let password: String
}
