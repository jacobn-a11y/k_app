import Foundation
import Security

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case sessionExpired
    case notAuthenticated
    case appleSignInFailed
    case appleIdentityTokenMissing
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
        case .appleIdentityTokenMissing: return "Apple ID token unavailable. Complete native Apple sign-in before exchanging session."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Auth Service Implementation

final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private let apiClient: APIClient
    private var _currentSession: AuthSession?
    private let sessionKey = "com.hallyu.authSession"
    private var refreshTask: Task<Void, Never>?

    var currentSession: AuthSession? { _currentSession }
    var isAuthenticated: Bool { _currentSession != nil && !isSessionExpired }

    private var isSessionExpired: Bool {
        guard let session = _currentSession else { return true }
        return session.expiresAt < Date()
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self._currentSession = loadPersistedSession()
        startProactiveRefresh()
    }

    deinit {
        refreshTask?.cancel()
    }

    /// Proactively refresh token before expiry (5-minute buffer)
    private func startProactiveRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, let session = self._currentSession else {
                    try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                    continue
                }
                let timeUntilExpiry = session.expiresAt.timeIntervalSinceNow
                if timeUntilExpiry < 300 && timeUntilExpiry > 0 {
                    _ = try? await self.refreshSession()
                }
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws -> AuthSession {
        guard let idToken = configuredAppleIdentityToken() else {
            throw AuthError.appleIdentityTokenMissing
        }
        let nonce = ProcessInfo.processInfo.environment["APPLE_NONCE"]?.trimmedNonEmpty
        return try await signInWithApple(idToken: idToken, nonce: nonce)
    }

    func signInWithApple(idToken: String, nonce: String?) async throws -> AuthSession {
        guard let normalizedToken = idToken.trimmedNonEmpty else {
            throw AuthError.appleIdentityTokenMissing
        }

        let body = AppleSignInRequest(provider: "apple", idToken: normalizedToken, nonce: nonce?.trimmedNonEmpty)
        let request = try APIRequest(
            path: "/auth/v1/token",
            method: .post,
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: body
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
        // Validate input lengths and email format
        guard email.count <= 254, password.count <= 128 else {
            throw AuthError.invalidCredentials
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) else {
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
            let request = try APIRequest(
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

    // MARK: - Session Persistence (Keychain-backed)

    private func persistSession(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            KeychainHelper.save(data, forKey: sessionKey)
        }
    }

    private func loadPersistedSession() -> AuthSession? {
        guard let data = KeychainHelper.load(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    private func clearPersistedSession() {
        KeychainHelper.delete(forKey: sessionKey)
    }

    private func configuredAppleIdentityToken() -> String? {
        ProcessInfo.processInfo.environment["APPLE_ID_TOKEN"]?.trimmedNonEmpty
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

private struct AppleSignInRequest: Codable {
    let provider: String
    let idToken: String
    let nonce: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
