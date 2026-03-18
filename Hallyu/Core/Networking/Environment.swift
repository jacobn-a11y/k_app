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
        // In production, read from Xcode build configuration / Info.plist
        // NEVER hardcode API keys
        guard let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] else {
            return ""
        }
        return key
    }

    var supabaseAnonKey: String {
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            return ""
        }
        return key
    }
}
