import SwiftUI

struct ContentView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar") {
                PlaceholderView(title: "Daily Plan")
            }
            Tab("Learn", systemImage: "book.fill") {
                MediaLibraryView()
            }
            Tab("Review", systemImage: "arrow.counterclockwise") {
                PlaceholderView(title: "Review")
            }
            Tab("Progress", systemImage: "chart.bar.fill") {
                PlaceholderView(title: "Progress")
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                PlaceholderView(title: "Settings")
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
