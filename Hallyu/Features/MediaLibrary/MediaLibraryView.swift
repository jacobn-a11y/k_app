import SwiftUI
import SwiftData

struct MediaLibraryView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.modelContext) private var modelContext
    @Query private var mediaContent: [MediaContent]
    @State private var viewModel = MediaLibraryViewModel()
    @State private var showFilters = false
    @State private var selectedContent: MediaContent?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                contentTypeBar
                filterBar
                contentGrid
            }
            .navigationTitle("Media Library")
            .searchable(text: searchQueryBinding, prompt: "Search media...")
            .onChange(of: mediaContent) { _, newContent in
                viewModel.loadContent(from: newContent)
            }
            .onAppear {
                viewModel.loadContent(from: mediaContent)
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .navigationDestination(item: $selectedContent) { content in
                MediaDetailView(content: content, viewModel: viewModel)
            }
        }
    }

    // MARK: - Content Type Bar

    private var contentTypeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MediaContentType.allCases) { type in
                    contentTypeChip(type)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func contentTypeChip(_ type: MediaContentType) -> some View {
        let isSelected = viewModel.filters.contentType == type
        return Button {
            viewModel.updateContentType(type)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.caption)
                Text(type.displayName)
                    .font(.subheadline)
                if type != .all, let count = viewModel.contentTypeCounts[type] {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack {
            Menu {
                ForEach(CEFRFilter.allCases) { level in
                    Button(level.displayName) {
                        viewModel.updateCEFRLevel(level)
                    }
                }
            } label: {
                filterLabel("Level: \(viewModel.filters.cefrLevel.displayName)")
            }

            Menu {
                ForEach(DurationFilter.allCases) { duration in
                    Button(duration.displayName) {
                        viewModel.updateDuration(duration)
                    }
                }
            } label: {
                filterLabel("Duration: \(viewModel.filters.duration.displayName)")
            }

            Spacer()

            Menu {
                ForEach(MediaSortOrder.allCases) { order in
                    Button(order.displayName) {
                        viewModel.updateSortOrder(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func filterLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }

    // MARK: - Content Grid

    private var contentGrid: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading media library...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredContent.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(viewModel.filteredContent, id: \.id) { content in
                            MediaCardView(
                                content: content,
                                coverage: viewModel.coverage(for: content),
                                coverageLevel: viewModel.coverageLevel(for: content),
                                formattedDuration: viewModel.formattedDuration(for: content)
                            )
                            .onTapGesture {
                                selectedContent = content
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Media Found", systemImage: "magnifyingglass")
        } description: {
            if viewModel.filters.isFiltered {
                Text("Try adjusting your filters")
            } else {
                Text("Media content will appear here")
            }
        } actions: {
            if viewModel.filters.isFiltered {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Content Type") {
                    ForEach(MediaContentType.allCases) { type in
                        Button {
                            viewModel.updateContentType(type)
                        } label: {
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                                Spacer()
                                if viewModel.filters.contentType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("CEFR Level") {
                    ForEach(CEFRFilter.allCases) { level in
                        Button {
                            viewModel.updateCEFRLevel(level)
                        } label: {
                            HStack {
                                Text(level.displayName)
                                Spacer()
                                if viewModel.filters.cefrLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Duration") {
                    ForEach(DurationFilter.allCases) { duration in
                        Button {
                            viewModel.updateDuration(duration)
                        } label: {
                            HStack {
                                Text(duration.displayName)
                                Spacer()
                                if viewModel.filters.duration == duration {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFilters = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { viewModel.clearFilters() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Bindings

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { viewModel.filters.searchQuery },
            set: { viewModel.updateSearchQuery($0) }
        )
    }
}

// MARK: - Media Card View

struct MediaCardView: View {
    let content: MediaContent
    let coverage: Double
    let coverageLevel: CoverageLevel
    let formattedDuration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail placeholder
            ZStack(alignment: .bottomTrailing) {
                // Downloaded indicator
                if content.thumbnailUrl.hasPrefix("local://") {
                    // Show offline badge overlay
                }
                RoundedRectangle(cornerRadius: 8)
                    .fill(thumbnailColor)
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: contentTypeIcon)
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                if content.durationSeconds > 0 {
                    Text(formattedDuration)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.7))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(content.cefrLevel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(cefrColor.opacity(0.2))
                        .foregroundStyle(cefrColor)
                        .clipShape(Capsule())

                    difficultyIndicator
                }

                if !content.source.isEmpty {
                    Text(content.source)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(content.title), \(content.cefrLevel) level, \(coverageLevel.label) difficulty")
        .accessibilityHint("Double tap to view details")
    }

    private var contentTypeIcon: String {
        (MediaContentType(rawValue: content.contentType) ?? .drama).iconName
    }

    private var thumbnailColor: Color {
        switch content.contentType {
        case "drama": return .purple.opacity(0.6)
        case "news": return .blue.opacity(0.6)
        case "webtoon": return .orange.opacity(0.6)
        case "short_video": return .pink.opacity(0.6)
        case "music": return .green.opacity(0.6)
        default: return .gray.opacity(0.6)
        }
    }

    private var cefrColor: Color {
        switch content.cefrLevel {
        case "pre-A1", "A1": return .green
        case "A2": return .blue
        case "B1": return .orange
        case "B2": return .red
        default: return .gray
        }
    }

    private var difficultyIndicator: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(difficultyColor)
                .frame(width: 6, height: 6)
            Text(coverageLevel.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var difficultyColor: Color {
        switch coverageLevel {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }
}
