import SwiftUI

struct MediaDetailView: View {
    let content: MediaContent
    let viewModel: MediaLibraryViewModel
    @State private var showPlayer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection
                metadataSection
                descriptionSection
                vocabularyPreviewSection
                transcriptPreviewSection
            }
            .padding()
        }
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Start Lesson") {
                    showPlayer = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationDestination(isPresented: $showPlayer) {
            MediaPlayerView(content: content)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(thumbnailGradient)
                .frame(height: 200)
                .overlay {
                    Image(systemName: contentTypeIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(contentTypeLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                Text(content.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        HStack(spacing: 16) {
            metadataItem(icon: "chart.bar", label: content.cefrLevel, subtitle: "Level")
            metadataItem(icon: "clock", label: formattedDuration, subtitle: "Duration")
            metadataItem(icon: "text.book.closed", label: coverageLabel, subtitle: "Coverage")
            metadataItem(icon: "gauge", label: difficultyLabel, subtitle: "Difficulty")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metadataItem(icon: String, label: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !content.source.isEmpty {
                HStack {
                    Text("Source:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(content.source)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if !content.culturalNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cultural Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(content.culturalNotes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            if !content.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(content.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Vocabulary Preview

    private var vocabularyPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Vocabulary")
                .font(.headline)

            let tokens = KoreanTextAnalyzer.tokenize(content.transcriptKr)
            let uniqueTokens = Array(Set(tokens)).prefix(10)

            if uniqueTokens.isEmpty {
                Text("No vocabulary data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(uniqueTokens), id: \.self) { token in
                        vocabChip(token)
                    }
                }
            }
        }
    }

    private func vocabChip(_ word: String) -> some View {
        HStack {
            Text(word)
                .font(.subheadline)
            Spacer()
            if let rank = KoreanTextAnalyzer.frequencyRank(for: word) {
                Text("#\(rank)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Transcript Preview

    private var transcriptPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let segments = content.transcriptSegments
            if !segments.isEmpty {
                Text("Transcript Preview")
                    .font(.headline)

                ForEach(segments.prefix(3), id: \.startMs) { segment in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(segment.textKr)
                            .font(.body)
                        Text(segment.textEn)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if segments.count > 3 {
                    Text("\(segments.count - 3) more segments...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var contentTypeIcon: String {
        (MediaContentType(rawValue: content.contentType) ?? .drama).iconName
    }

    private var contentTypeLabel: String {
        (MediaContentType(rawValue: content.contentType) ?? .drama).displayName
    }

    private var thumbnailGradient: LinearGradient {
        let baseColor: Color = {
            switch content.contentType {
            case "drama": return .purple
            case "news": return .blue
            case "webtoon": return .orange
            case "short_video": return .pink
            case "music": return .green
            default: return .gray
            }
        }()
        return LinearGradient(
            colors: [baseColor.opacity(0.8), baseColor.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var formattedDuration: String {
        viewModel.formattedDuration(for: content)
    }

    private var coverageLabel: String {
        let pct = viewModel.coverage(for: content)
        return "\(Int(pct * 100))%"
    }

    private var difficultyLabel: String {
        let score = content.difficultyScore
        if score < 0.35 { return "Easy" }
        if score < 0.65 { return "Medium" }
        return "Hard"
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
