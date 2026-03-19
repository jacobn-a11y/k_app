import Testing
import Foundation
@testable import HallyuCore

@Suite("CulturalContextViewModel Tests")
struct CulturalContextViewModelTests {

    private func makeViewModel() -> CulturalContextViewModel {
        CulturalContextViewModel(claudeService: MockClaudeService())
    }

    @Test("Initial state is idle")
    func initialState() {
        let vm = makeViewModel()
        #expect(vm.phase == .idle)
        #expect(vm.moment == "")
        #expect(vm.response == nil)
        #expect(!vm.isActive)
    }

    @Test("Flag moment fetches cultural context")
    func flagMoment() async {
        let vm = makeViewModel()
        await vm.flagMoment(moment: "bowing scene", mediaContext: "office drama")
        #expect(vm.phase == .showingExplanation)
        #expect(vm.response != nil)
        #expect(vm.hasResponse)
        #expect(vm.moment == "bowing scene")
        #expect(vm.isActive)
    }

    @Test("Response includes explanation")
    func responseContent() async {
        let vm = makeViewModel()
        await vm.flagMoment(moment: "honorifics", mediaContext: "family scene")
        guard let response = vm.response else {
            Issue.record("Expected response")
            return
        }
        #expect(!response.explanation.isEmpty)
    }

    @Test("Save to collection marks as saved")
    func saveToCollection() async {
        let vm = makeViewModel()
        await vm.flagMoment(moment: "bowing", mediaContext: "drama")
        #expect(!vm.savedToCollection)
        vm.saveToCollection()
        #expect(vm.savedToCollection)
    }

    @Test("Save without response does nothing")
    func saveWithoutResponse() {
        let vm = makeViewModel()
        vm.saveToCollection()
        #expect(!vm.savedToCollection)
    }

    @Test("Dismiss resets all state")
    func dismiss() async {
        let vm = makeViewModel()
        await vm.flagMoment(moment: "bowing", mediaContext: "drama")
        vm.saveToCollection()
        vm.dismiss()
        #expect(vm.phase == .idle)
        #expect(vm.moment == "")
        #expect(vm.response == nil)
        #expect(!vm.savedToCollection)
        #expect(!vm.isActive)
    }
}
