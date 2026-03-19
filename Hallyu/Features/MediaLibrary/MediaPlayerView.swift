import SwiftUI

enum SubtitleMode: String, CaseIterable {
    case none = "none"
    case koreanOnly = "korean"
    case koreanAndEnglish = "both"

    var displayName: String {
        switch self {
        case .none: return "No Subtitles"
        case .koreanOnly: return "Korean Only"
        case .koreanAndEnglish: return "Korean + English"
        }
    }

    var iconName: String {
        switch self {
        case .none: return "captions.bubble"
        case .koreanOnly: return "captions.bubble.fill"
        case .koreanAndEnglish: return "text.bubble.fill"
        }
    }
}

@Observable
final class MediaPlayerViewModel {
    let content: MediaContent
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var playbackRate: Float = 1.0
    var subtitleMode: SubtitleMode = .koreanOnly
    var currentSegmentIndex: Int = 0
    var highlightedWord: String?
    var showWordDetail: Bool = false

    static let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var segments: [MediaContent.TranscriptSegment] {
        content.transcriptSegments
    }

    var currentSegment: MediaContent.TranscriptSegment? {
        guard !segments.isEmpty else { return nil }
        let timeMs = Int(currentTime * 1000)
        return segments.first { timeMs >= $0.startMs && timeMs < $0.endMs }
            ?? (currentSegmentIndex < segments.count ? segments[currentSegmentIndex] : nil)
    }

    var duration: Double {
        Double(content.durationSeconds)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var isVideoContent: Bool {
        content.contentType == "drama" || content.contentType == "short_video" || content.contentType == "music"
    }

    var isTextContent: Bool {
        content.contentType == "webtoon" || content.contentType == "news"
    }

    init(content: MediaContent) {
        self.content = content
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func seek(to time: Double) {
        currentTime = max(0, min(time, duration))
        updateCurrentSegment()
    }

    func seekForward(_ seconds: Double = 10) {
        seek(to: currentTime + seconds)
    }

    func seekBackward(_ seconds: Double = 10) {
        seek(to: currentTime - seconds)
    }

    func nextSegment() {
        guard currentSegmentIndex < segments.count - 1 else { return }
        currentSegmentIndex += 1
        if let segment = segments[safe: currentSegmentIndex] {
            seek(to: Double(segment.startMs) / 1000.0)
        }
    }

    func previousSegment() {
        guard currentSegmentIndex > 0 else { return }
        currentSegmentIndex -= 1
        if let segment = segments[safe: currentSegmentIndex] {
            seek(to: Double(segment.startMs) / 1000.0)
        }
    }

    func cycleSubtitleMode() {
        let modes = SubtitleMode.allCases
        guard let currentIndex = modes.firstIndex(of: subtitleMode) else { return }
        let nextIndex = (currentIndex + 1) % modes.count
        subtitleMode = modes[nextIndex]
    }

    func cyclePlaybackRate() {
        guard let currentIndex = Self.playbackRates.firstIndex(of: playbackRate) else {
            playbackRate = 1.0
            return
        }
        let nextIndex = (currentIndex + 1) % Self.playbackRates.count
        playbackRate = Self.playbackRates[nextIndex]
    }

    func tapWord(_ word: String) {
        highlightedWord = word
        showWordDetail = true
    }

    func dismissWordDetail() {
        showWordDetail = false
        highlightedWord = nil
    }

    private func updateCurrentSegment() {
        let timeMs = Int(currentTime * 1000)
        if let index = segments.firstIndex(where: { timeMs >= $0.startMs && timeMs < $0.endMs }) {
            currentSegmentIndex = index
        }
    }
}

// MARK: - MediaPlayerView

struct MediaPlayerView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: MediaPlayerViewModel

    init(content: MediaContent) {
        _viewModel = State(initialValue: MediaPlayerViewModel(content: content))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isVideoContent {
                videoPlayerArea
            } else {
                textReaderArea
            }

            subtitleArea
            playerControls
        }
        .navigationTitle(viewModel.content.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    subtitleModeMenu
                    playbackRateMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showWordDetail) {
            wordDetailSheet
        }
    }

    // MARK: - Video Player Area

    private var videoPlayerArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black)
                .frame(height: 220)
                .overlay {
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Video Player")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
        }
    }

    // MARK: - Text Reader Area

    private var textReaderArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(viewModel.segments.enumerated()), id: \.offset) { index, segment in
                    textSegmentView(segment: segment, index: index)
                }

                if viewModel.segments.isEmpty && !viewModel.content.transcriptKr.isEmpty {
                    tappableText(viewModel.content.transcriptKr)
                        .padding()
                }
            }
            .padding()
        }
        .frame(maxHeight: 300)
    }

    private func textSegmentView(segment: MediaContent.TranscriptSegment, index: Int) -> some View {
        let isActive = index == viewModel.currentSegmentIndex
        return VStack(alignment: .leading, spacing: 4) {
            tappableText(segment.textKr)
                .fontWeight(isActive ? .medium : .regular)

            if viewModel.subtitleMode == .koreanAndEnglish {
                Text(segment.textEn)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            viewModel.currentSegmentIndex = index
            viewModel.seek(to: Double(segment.startMs) / 1000.0)
        }
    }

    private func tappableText(_ text: String) -> some View {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return WrappingHStack(words: words) { word in
            Text(word + " ")
                .font(.body)
                .foregroundStyle(word == viewModel.highlightedWord ? Color.accentColor : .primary)
                .background(word == viewModel.highlightedWord ? Color.accentColor.opacity(0.15) : Color.clear)
                .onTapGesture {
                    let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
                    if HangulUtilities.containsKorean(cleaned) {
                        viewModel.tapWord(cleaned)
                    }
                }
        }
    }

    // MARK: - Subtitle Area

    private var subtitleArea: some View {
        VStack(spacing: 4) {
            if viewModel.subtitleMode != .none, let segment = viewModel.currentSegment {
                tappableText(segment.textKr)
                    .padding(.horizontal)

                if viewModel.subtitleMode == .koreanAndEnglish {
                    Text(segment.textEn)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 60)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        VStack(spacing: 8) {
            // Progress bar
            HStack(spacing: 8) {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption2)
                    .monospacedDigit()

                Slider(value: $viewModel.currentTime, in: 0...max(viewModel.duration, 1)) { editing in
                    if !editing {
                        viewModel.seek(to: viewModel.currentTime)
                    }
                }

                Text(formatTime(viewModel.duration))
                    .font(.caption2)
                    .monospacedDigit()
            }
            .padding(.horizontal)

            // Playback controls
            HStack(spacing: 32) {
                Button { viewModel.previousSegment() } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Button { viewModel.seekBackward() } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Button { viewModel.togglePlayback() } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Button { viewModel.seekForward() } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                Button { viewModel.nextSegment() } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }

            // Bottom controls
            HStack {
                Button { viewModel.cycleSubtitleMode() } label: {
                    Label(viewModel.subtitleMode.displayName, systemImage: viewModel.subtitleMode.iconName)
                        .font(.caption)
                }

                Spacer()

                Button { viewModel.cyclePlaybackRate() } label: {
                    Text("\(viewModel.playbackRate, specifier: "%.1f")x")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Menus

    private var subtitleModeMenu: some View {
        Section("Subtitles") {
            ForEach(SubtitleMode.allCases, id: \.rawValue) { mode in
                Button {
                    viewModel.subtitleMode = mode
                } label: {
                    HStack {
                        Text(mode.displayName)
                        if viewModel.subtitleMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    private var playbackRateMenu: some View {
        Section("Speed") {
            ForEach(MediaPlayerViewModel.playbackRates, id: \.self) { rate in
                Button {
                    viewModel.playbackRate = rate
                } label: {
                    HStack {
                        Text("\(rate, specifier: "%.1f")x")
                        if viewModel.playbackRate == rate {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Word Detail Sheet

    private var wordDetailSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let word = viewModel.highlightedWord {
                    Text(word)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let rank = KoreanTextAnalyzer.frequencyRank(for: word) {
                        Text("Frequency rank: #\(rank)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text("Tap to get Claude's explanation")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Button("Add to Review") {
                        viewModel.dismissWordDetail()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Word Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { viewModel.dismissWordDetail() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Wrapping HStack for Tappable Words

struct WrappingHStack<Content: View>: View {
    let words: [String]
    let content: (String) -> Content

    var body: some View {
        // Simple flow using a concatenated Text approach for inline wrapping
        HStack(spacing: 0) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                content(word)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Array Safe Subscript

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
