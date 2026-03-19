import Testing
import Foundation
@testable import HallyuCore

@Suite("SupabaseClient Tests")
struct SupabaseClientTests {

    @Test("SupabaseConfig reads values from environment")
    func configFromEnvironment() throws {
        let config = try SupabaseConfig.resolved(
            from: [
                "SUPABASE_URL": "https://project.supabase.co",
                "SUPABASE_ANON_KEY": "anon-key",
                "SUPABASE_SERVICE_ROLE_KEY": "service-role-key"
            ]
        )

        #expect(config.projectURL.absoluteString == "https://project.supabase.co")
        #expect(config.anonKey == "anon-key")
        #expect(config.serviceRoleKey == "service-role-key")
    }

    @Test("SupabaseConfig throws for missing required values")
    func missingConfigThrows() {
        #expect(throws: SupabaseConfig.SupabaseConfigError.self) {
            try SupabaseConfig.resolved(from: [:])
        }

        let placeholder = SupabaseConfig.placeholder
        #expect(placeholder.projectURL.absoluteString == "https://placeholder.supabase.co")
        #expect(placeholder.anonKey == "placeholder-anon-key")
        #expect(placeholder.serviceRoleKey == nil)
    }

    @Test("AuthCredentials encodes correctly")
    func authCredentialsEncoding() throws {
        let creds = AuthCredentials(email: "test@example.com", password: "secret")
        let data = try JSONEncoder().encode(creds)
        let json = try JSONDecoder().decode([String: String].self, from: data)
        #expect(json["email"] == "test@example.com")
        #expect(json["password"] == "secret")
    }

    @Test("AuthResponse decodes from JSON")
    func authResponseDecoding() throws {
        let json = """
        {
            "access_token": "token123",
            "refresh_token": "refresh456",
            "user": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "test@example.com"
            },
            "expires_in": 3600
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(AuthResponse.self, from: json)
        #expect(response.accessToken == "token123")
        #expect(response.refreshToken == "refresh456")
        #expect(response.user?.email == "test@example.com")
        #expect(response.expiresIn == 3600)
    }
}
