import Foundation
import Observation

@MainActor
@Observable
final class CulturalContextViewModel {

    // MARK: - State

    enum Phase: Equatable {
        case idle
        case loading
        case showingExplanation
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var moment: String = ""
    private(set) var mediaContext: String = ""
    private(set) var response: CulturalContextResponse?
    private(set) var savedToCollection: Bool = false

    let claudeService: ClaudeServiceProtocol
    private let subscriptionTier: AppState.SubscriptionTier

    // MARK: - Init

    init(
        claudeService: ClaudeServiceProtocol,
        subscriptionTier: AppState.SubscriptionTier = .core
    ) {
        self.claudeService = claudeService
        self.subscriptionTier = subscriptionTier
    }

    // MARK: - Actions

    func flagMoment(moment: String, mediaContext: String) async {
        self.moment = moment
        self.mediaContext = mediaContext
        self.response = nil
        self.savedToCollection = false

        do {
            try await claudeService.checkTierAllowed(tier: subscriptionTier)
        } catch {
            phase = .error(claudeErrorMessage(for: error))
            return
        }

        phase = .loading

        do {
            let result = try await claudeService.getCulturalContext(
                moment: moment,
                mediaContext: mediaContext
            )
            response = result
            phase = .showingExplanation
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func saveToCollection() {
        guard response != nil else { return }
        savedToCollection = true
    }

    func dismiss() {
        phase = .idle
        moment = ""
        mediaContext = ""
        response = nil
        savedToCollection = false
    }

    // MARK: - Computed

    var isActive: Bool {
        phase != .idle
    }

    var hasResponse: Bool {
        response != nil
    }

    private func claudeErrorMessage(for error: Error) -> String {
        if case ClaudeServiceError.tierLimitReached = error {
            return "Daily interaction limit reached for your subscription tier. Upgrade to continue."
        }
        return error.localizedDescription
    }
}
