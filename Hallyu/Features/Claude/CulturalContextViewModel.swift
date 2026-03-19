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

    // MARK: - Init

    init(claudeService: ClaudeServiceProtocol) {
        self.claudeService = claudeService
    }

    // MARK: - Actions

    func flagMoment(moment: String, mediaContext: String) async {
        self.moment = moment
        self.mediaContext = mediaContext
        self.response = nil
        self.savedToCollection = false
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
}
