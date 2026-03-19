import SwiftUI

struct CulturalContextView: View {
    @Bindable var viewModel: CulturalContextViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "globe.asia.australia.fill")
                    .foregroundStyle(.teal)
                Text("Cultural Context")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            // Moment description
            if !viewModel.moment.isEmpty {
                Text("\"\(viewModel.moment)\"")
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView("Getting cultural context...")
                    .padding()

            case .showingExplanation:
                if let response = viewModel.response {
                    culturalExplanationView(response)
                }

            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func culturalExplanationView(_ response: CulturalContextResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main explanation
            Text(response.explanation)
                .font(.body)

            // Social dynamics
            if let dynamics = response.socialDynamics {
                sectionView(title: "Social Dynamics", icon: "person.2.fill", content: dynamics)
            }

            // Honorific note
            if let honorific = response.honorificNote {
                sectionView(title: "Honorifics", icon: "text.quote", content: honorific)
            }

            // Historical context
            if let historical = response.historicalContext {
                sectionView(title: "Historical Background", icon: "clock.arrow.circlepath", content: historical)
            }

            // Related media
            if !response.relatedMedia.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("See also in:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(response.relatedMedia, id: \.self) { title in
                        Label(title, systemImage: "film")
                            .font(.subheadline)
                    }
                }
            }

            // Save button
            if !viewModel.savedToCollection {
                Button {
                    viewModel.saveToCollection()
                } label: {
                    Label("Save to Collection", systemImage: "bookmark")
                }
                .buttonStyle(.bordered)
            } else {
                Label("Saved", systemImage: "bookmark.fill")
                    .foregroundStyle(.teal)
            }
        }
    }

    private func sectionView(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(content)
                .font(.body)
                .padding(8)
                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
