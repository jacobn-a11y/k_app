import SwiftUI

struct AuthView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    let onAuthenticated: (AuthSession) -> Void

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
                Button {
                    Task { await signInWithApple() }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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

    private func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await services.auth.signInWithApple()
            onAuthenticated(session)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitEmailAuth() async {
        isLoading = true
        errorMessage = nil
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
}
