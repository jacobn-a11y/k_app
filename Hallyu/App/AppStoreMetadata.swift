import Foundation

enum AppStoreMetadata {
    static let appName = "Hallyu"
    static let bundleId = "com.hallyu.app"
    static let version = "1.0.0"
    static let buildNumber = "1"
    static let minimumOSVersion = "17.0"

    static let subtitle = "Learn Korean Through Media"

    static let description = """
    Hallyu turns K-dramas, webtoons, and K-pop into your Korean classroom. \
    Learn Hangul from scratch, build vocabulary from real media, and get AI-powered \
    coaching that adapts to your level.

    KEY FEATURES:

    - Complete Hangul Course: Master all Korean characters with animated stroke order, \
    pronunciation practice, and "Spot in the Wild" media exercises.

    - Media-Powered Learning: Study Korean through K-drama clips, webtoon panels, \
    news articles, and music — content you actually want to consume.

    - AI Language Coach: Get instant explanations when you tap any Korean word. \
    Claude AI provides pronunciation coaching, grammar explanations, and cultural context.

    - Smart Review System: Spaced repetition ensures you remember what you learn. \
    The app tracks your mastery across reading, listening, vocabulary, grammar, and pronunciation.

    - Personalized Daily Plans: Each day brings a customized learning plan that balances \
    new content, review, and skill building — all within your chosen time goal.

    - CEFR-Aligned Progress: Track your journey from complete beginner (pre-A1) to \
    intermediate (B2) with concrete milestones like "Can follow a K-drama episode with Korean subtitles."

    - Offline Support: Download media for offline learning. Review sessions and Hangul \
    lessons work without an internet connection.

    SUBSCRIPTION TIERS:
    - Free: Complete Hangul course, basic review
    - Core ($12.99/mo): AI coaching (50 interactions/day), full media library
    - Pro ($19.99/mo): Unlimited AI coaching, media downloads, advanced progress tracking

    Start learning Korean today — the way it was meant to be learned.
    """

    static let keywords = [
        "Korean", "Learn Korean", "Hangul", "K-drama",
        "K-pop", "Webtoon", "Language Learning", "SRS",
        "Spaced Repetition", "AI Tutor"
    ]

    static let primaryCategory = "Education"
    static let secondaryCategory = "Reference"

    static let privacyPolicyURL = "https://hallyu.app/privacy"
    static let termsOfServiceURL = "https://hallyu.app/terms"
    static let supportURL = "https://hallyu.app/support"

    static let screenshotDescriptions = [
        "Daily learning plan with personalized activities",
        "Hangul lesson with animated stroke order",
        "K-drama clip with tappable Korean subtitles",
        "AI coaching explaining vocabulary in context",
        "Progress dashboard showing CEFR level advancement",
        "Spaced repetition review with flashcards"
    ]
}

// MARK: - Privacy Policy Content

enum PrivacyPolicy {
    static let lastUpdated = "2026-03-19"

    static let content = """
    HALLYU PRIVACY POLICY
    Last updated: \(lastUpdated)

    1. INFORMATION WE COLLECT
    - Account information (email, display name) when you create an account
    - Learning progress data (lessons completed, review scores, mastery levels)
    - Audio recordings you create during pronunciation practice (stored locally, never uploaded without consent)
    - Usage analytics (features used, session duration) to improve the app

    2. HOW WE USE YOUR INFORMATION
    - To personalize your learning experience and generate daily plans
    - To sync your progress across devices (when signed in)
    - To provide AI-powered coaching through our language model integration
    - To improve our content and features based on aggregate usage patterns

    3. AI COACHING
    - When you use AI coaching features, your learning context (current media, vocabulary level) \
    is sent to our AI provider (Anthropic) to generate responses
    - We do not send personal identifying information to AI providers
    - AI interactions may be cached locally to improve response times

    4. DATA STORAGE
    - Learning data is stored locally on your device using SwiftData
    - When signed in, data syncs to our cloud database (Supabase) for cross-device access
    - Audio recordings remain on your device and are not uploaded to our servers

    5. DATA SHARING
    - We do not sell your personal information
    - We share data only with: our cloud provider (Supabase) for sync, \
    our AI provider (Anthropic) for coaching features, and Apple for subscription management

    6. YOUR RIGHTS
    - You can export your learning data at any time
    - You can delete your account and all associated data
    - You can use the app in anonymous mode without creating an account

    7. CONTACT
    For privacy questions, contact: privacy@hallyu.app
    """
}
