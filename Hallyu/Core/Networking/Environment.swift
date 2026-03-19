import Foundation

enum AppEnvironment {
    case debug
    case release

    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    var claudeAPIBaseURL: URL {
        URL(string: "https://api.anthropic.com")!
    }

    var supabaseConfig: SupabaseConfig {
        switch self {
        case .debug: return .debug
        case .release: return .release
        }
    }

    var claudeAPIKey: String {
        // Read from environment variable or Xcode build configuration.
        // NEVER hardcode API keys in source code.
        // Set CLAUDE_API_KEY in your Xcode scheme environment variables
        // or in a .xcconfig file (excluded from version control).
        guard let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
              !key.isEmpty else {
            return ""
        }
        return key
    }

    var supabaseAnonKey: String {
        // Read from environment variable or Xcode build configuration.
        // Set SUPABASE_ANON_KEY in your Xcode scheme environment variables.
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
              !key.isEmpty else {
            return ""
        }
        return key
    }
}
