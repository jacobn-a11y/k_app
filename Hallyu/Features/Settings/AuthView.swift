import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct AuthView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pendingAppleNonce: String?
    @FocusState private var focusedField: Field?
    let onAuthenticated: (AuthSession) -> Void

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .scaledFont(size: 60)
                        .foregroundStyle(.blue)
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(isSignUp ? "Sign up to sync your progress" : "Sign in to continue learning")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Sign in with Apple
                SignInWithAppleButton(.continue) { request in
                    configureAppleRequest(request)
                } onCompletion: { result in
                    Task { await handleAppleAuthorization(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .disabled(isLoading)
                .padding(.horizontal)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                }
                .padding(.horizontal)

                // Email form
                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($focusedField, equals: .email)
                        .onChange(of: email) { _, _ in errorMessage = nil }

                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .submitLabel(.done)
                        .onSubmit {
                            if !email.isEmpty && !password.isEmpty {
                                Task { await submitEmailAuth() }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($focusedField, equals: .password)
                        .onChange(of: password) { _, _ in errorMessage = nil }
                }
                .padding(.horizontal)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Submit button
                Button {
                    Task { await submitEmailAuth() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)

                // Toggle sign in / sign up
                Button {
                    isSignUp.toggle()
                    errorMessage = nil
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                }

                // Skip / anonymous
                Button("Continue without account") {
                    dismiss()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil
        let nonce = Self.randomNonce()
        pendingAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        focusedField = nil
        defer {
            isLoading = false
            pendingAppleNonce = nil
        }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = AuthError.appleSignInFailed.localizedDescription
                return
            }

            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  !idToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = AuthError.appleIdentityTokenMissing.localizedDescription
                return
            }

            do {
                let session = try await services.auth.signInWithApple(
                    idToken: idToken,
                    nonce: pendingAppleNonce
                )
                onAuthenticated(session)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            guard !isCancelledAppleAuthorization(error) else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func submitEmailAuth() async {
        isLoading = true
        errorMessage = nil
        focusedField = nil
        defer { isLoading = false }

        do {
            let session: AuthSession
            if isSignUp {
                session = try await services.auth.signUp(email: email, password: password)
            } else {
                session = try await services.auth.signInWithEmail(email: email, password: password)
            }
            onAuthenticated(session)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isCancelledAppleAuthorization(_ error: Error) -> Bool {
        guard let authError = error as? ASAuthorizationError else { return false }
        return authError.code == .canceled
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        var remainingLength = length

        while remainingLength > 0 {
            var randomByte: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            if status != errSecSuccess {
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }

            if randomByte < charset.count {
                result.append(charset[Int(randomByte)])
                remainingLength -= 1
            }
        }

        return result
    }
}
