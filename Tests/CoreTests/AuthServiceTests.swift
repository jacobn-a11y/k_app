import Testing
import Foundation
@testable import HallyuCore

@Suite("AuthService Tests")
struct AuthServiceTests {

    // MARK: - Auth Error Display

    @Test("Auth errors have descriptions")
    func authErrorDescriptions() {
        let errors: [AuthError] = [
            .invalidCredentials,
            .emailAlreadyInUse,
            .weakPassword,
            .networkError,
            .sessionExpired,
            .notAuthenticated,
            .appleSignInFailed,
            .appleIdentityTokenMissing,
            .unknown("test error"),
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("Unknown error includes custom message")
    func unknownErrorMessage() {
        let error = AuthError.unknown("custom message")
        #expect(error.errorDescription == "custom message")
    }

    // MARK: - AuthSession

    @Test("AuthSession encodes and decodes")
    func sessionCodable() throws {
        let session = AuthSession(
            userId: UUID(),
            accessToken: "test_token",
            refreshToken: "test_refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(AuthSession.self, from: data)

        #expect(decoded.userId == session.userId)
        #expect(decoded.accessToken == session.accessToken)
        #expect(decoded.refreshToken == session.refreshToken)
    }

    // MARK: - Mock Auth Service

    @Test("Mock auth service signs in successfully")
    func mockSignIn() async throws {
        let mock = MockAuthService()
        #expect(mock.isAuthenticated == false)

        let session = try await mock.signInWithApple()
        #expect(mock.isAuthenticated == true)
        #expect(session.accessToken == "mock")
        #expect(mock.currentSession != nil)
    }

    @Test("Mock auth service signs out")
    func mockSignOut() async throws {
        let mock = MockAuthService()
        _ = try await mock.signInWithApple()
        #expect(mock.isAuthenticated == true)

        try await mock.signOut()
        #expect(mock.isAuthenticated == false)
        #expect(mock.currentSession == nil)
    }

    @Test("Mock email sign in works")
    func mockEmailSignIn() async throws {
        let mock = MockAuthService()
        let session = try await mock.signInWithEmail(email: "test@test.com", password: "password")
        #expect(mock.isAuthenticated == true)
        #expect(session.userId != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("Mock sign up works")
    func mockSignUp() async throws {
        let mock = MockAuthService()
        let session = try await mock.signUp(email: "new@test.com", password: "password")
        #expect(mock.isAuthenticated == true)
        #expect(session.accessToken == "mock")
    }

    @Test("Mock refresh returns new session")
    func mockRefresh() async throws {
        let mock = MockAuthService()
        let session = try await mock.refreshSession()
        #expect(session.accessToken == "mock")
    }

    // MARK: - AuthSessionResponse

    @Test("AuthSessionResponse converts to AuthSession")
    func sessionResponseConversion() {
        let response = AuthSessionResponse(
            access_token: "access123",
            refresh_token: "refresh123",
            expires_in: 3600,
            user: AuthUserResponse(id: UUID(), email: "test@test.com")
        )
        let session = response.toAuthSession()
        #expect(session.accessToken == "access123")
        #expect(session.refreshToken == "refresh123")
        #expect(session.expiresAt > Date())
    }

    // MARK: - Email Validation

    @Test("EmailAuthRequest encodes correctly")
    func emailRequestEncoding() throws {
        let request = EmailAuthRequest(email: "test@test.com", password: "password123")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(EmailAuthRequest.self, from: data)
        #expect(decoded.email == "test@test.com")
        #expect(decoded.password == "password123")
    }

    @Test("AuthService requires Apple token for environment fallback sign in")
    func appleSignInWithoutEnvironmentTokenFails() async {
        let service = AuthService(apiClient: APIClient(baseURL: URL(string: "https://example.com")!))

        do {
            _ = try await service.signInWithApple()
            Issue.record("Expected signInWithApple to fail without an Apple token")
        } catch let error as AuthError {
            if case .appleIdentityTokenMissing = error {
                #expect(true)
            } else {
                Issue.record("Expected appleIdentityTokenMissing, got \(error)")
            }
        } catch {
            Issue.record("Expected AuthError.appleIdentityTokenMissing, got \(error)")
        }
    }

    @Test("AuthService rejects empty Apple ID token exchange")
    func appleTokenExchangeRejectsEmptyToken() async {
        let service = AuthService(apiClient: APIClient(baseURL: URL(string: "https://example.com")!))

        do {
            _ = try await service.signInWithApple(idToken: "   ", nonce: "nonce")
            Issue.record("Expected signInWithApple(idToken:nonce:) to reject blank token")
        } catch let error as AuthError {
            if case .appleIdentityTokenMissing = error {
                #expect(true)
            } else {
                Issue.record("Expected appleIdentityTokenMissing, got \(error)")
            }
        } catch {
            Issue.record("Expected AuthError.appleIdentityTokenMissing, got \(error)")
        }
    }
}
