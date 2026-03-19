import SwiftUI

struct ContentView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar") {
                DailyPlanView()
            }
            Tab("Learn", systemImage: "book.fill") {
                MediaLibraryView()
            }
            Tab("Review", systemImage: "arrow.counterclockwise") {
                PlaceholderView(title: "Review")
            }
            Tab("Progress", systemImage: "chart.bar.fill") {
                ProgressDashboardView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .onAppear {
            MediaContentSeeder.seedIfNeeded(modelContext: modelContext)
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        NavigationStack {
            VStack {
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle(title)
        }
    }
}
