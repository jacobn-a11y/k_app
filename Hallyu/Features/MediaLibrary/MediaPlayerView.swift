import AVFoundation
import AVKit
import Observation
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
    @Environment(\.subtitleModeOverride) private var subtitleModeOverride
    @State private var viewModel: MediaPlayerViewModel
    @State private var localPlayer: AVPlayer?
    @State private var playbackErrorMessage: String?
    @State private var isSeeking = false

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
        .inlineNavigationTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    subtitleModeMenu
                    playbackRateMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Playback options")
                .accessibilityHint("Change subtitles or playback speed.")
            }
        }
        .sheet(isPresented: $viewModel.showWordDetail) {
            wordDetailSheet
        }
        .task(id: viewModel.content.mediaUrl) {
            await configurePlayback()
            await monitorPlayback()
        }
        .task(id: subtitleModeOverride.map { "override-\($0.rawValue)" } ?? "default") {
            if let override = subtitleModeOverride {
                viewModel.subtitleMode = override
            }
        }
        .onDisappear {
            Task { await pausePlayback() }
        }
    }

    // MARK: - Video Player Area

    private var videoPlayerArea: some View {
        ZStack {
            if let player = activePlayer {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.black)
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(playbackErrorMessage ?? "Video Player")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
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

            if effectiveSubtitleMode == .koreanAndEnglish {
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
            Task { await seekPlayback(to: Double(segment.startMs) / 1000.0) }
        }
    }

    private func tappableText(_ text: String) -> some View {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return WrappingHStack(words: words) { word in
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            if HangulUtilities.containsKorean(cleaned) {
                Text(word + " ")
                    .font(.body)
                    .foregroundStyle(word == viewModel.highlightedWord ? Color.accentColor : .primary)
                    .background(word == viewModel.highlightedWord ? Color.accentColor.opacity(0.15) : Color.clear)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.tapWord(cleaned)
                    }
                    .accessibilityLabel(cleaned)
                    .accessibilityHint("Double tap to open the word detail sheet.")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        viewModel.tapWord(cleaned)
                    }
            } else {
                Text(word + " ")
                    .font(.body)
                    .foregroundStyle(word == viewModel.highlightedWord ? Color.accentColor : .primary)
                    .background(word == viewModel.highlightedWord ? Color.accentColor.opacity(0.15) : Color.clear)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Subtitle Area

    private var subtitleArea: some View {
        VStack(spacing: 4) {
            if effectiveSubtitleMode != .none, let segment = viewModel.currentSegment {
                tappableText(segment.textKr)
                    .padding(.horizontal)

                if effectiveSubtitleMode == .koreanAndEnglish {
                    Text(segment.textEn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 60)
        .padding(.vertical, 8)
        .background(softSurfaceBackground)
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption2)
                    .monospacedDigit()
                    .accessibilityHidden(true)

                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 1)
                ) { editing in
                    isSeeking = editing
                    if !editing {
                        Task { await seekPlayback(to: viewModel.currentTime) }
                    }
                }
                .accessibilityLabel("Playback progress")
                .accessibilityValue("\(formatTime(viewModel.currentTime)) of \(formatTime(viewModel.duration))")

                Text(formatTime(viewModel.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .accessibilityHidden(true)
            }
            .padding(.horizontal)

            HStack(spacing: 32) {
                Button {
                    Task { await moveToPreviousSegment() }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous segment")
                .accessibilityHint("Jumps to the previous transcript segment.")

                Button {
                    Task { await seekRelativePlayback(-10) }
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Skip back 10 seconds")
                .accessibilityHint("Rewinds the current media by ten seconds.")

                Button {
                    Task { await togglePlayback() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.isPlaying ? "Pause playback" : "Play playback")
                .accessibilityHint(viewModel.isPlaying ? "Pauses the current media." : "Starts playback of the current media.")

                Button {
                    Task { await seekRelativePlayback(10) }
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Skip forward 10 seconds")
                .accessibilityHint("Fast-forwards the current media by ten seconds.")

                Button {
                    Task { await moveToNextSegment() }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Next segment")
                .accessibilityHint("Jumps to the next transcript segment.")
            }

            HStack {
                Button {
                    guard subtitleModeOverride == nil else { return }
                    viewModel.cycleSubtitleMode()
                } label: {
                    Label(effectiveSubtitleMode.displayName, systemImage: effectiveSubtitleMode.iconName)
                        .font(.caption)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(subtitleModeOverride != nil)
                .accessibilityLabel("Subtitle mode")
                .accessibilityValue(effectiveSubtitleMode.displayName)
                .accessibilityHint("Changes subtitle display mode.")

                Spacer()

                Button {
                    Task { await cyclePlaybackRate() }
                } label: {
                    Text("\(viewModel.playbackRate, specifier: "%.1f")x")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(subtleSurfaceBackground)
                        .clipShape(Capsule())
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Playback speed")
                .accessibilityValue("\(viewModel.playbackRate, specifier: "%.1f") times")
                .accessibilityHint("Cycles through available playback speeds.")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Menus

    private var subtitleModeMenu: some View {
        Section("Subtitles") {
            if let override = subtitleModeOverride {
                Label("Forced to \(override.displayName)", systemImage: override.iconName)
            } else {
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
    }

    private var playbackRateMenu: some View {
        Section("Speed") {
            ForEach(MediaPlayerViewModel.playbackRates, id: \.self) { rate in
                Button {
                    viewModel.playbackRate = rate
                    Task { await applyPlaybackRate(rate) }
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
            .inlineNavigationTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { viewModel.dismissWordDetail() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private var effectiveSubtitleMode: SubtitleMode {
        subtitleModeOverride ?? viewModel.subtitleMode
    }

    private var mediaURL: URL? {
        URL(string: viewModel.content.mediaUrl)
    }

    private var activePlayer: AVPlayer? {
        (services.mediaPlayer as? AVMediaPlayerService)?.avPlayer ?? localPlayer
    }

    private var usingServicePlayer: Bool {
        (services.mediaPlayer as? AVMediaPlayerService)?.avPlayer != nil
    }

    private var softSurfaceBackground: Color {
        Color.secondary.opacity(0.08)
    }

    private var subtleSurfaceBackground: Color {
        Color.secondary.opacity(0.14)
    }

    @MainActor
    private func configurePlayback() async {
        guard let url = mediaURL else {
            playbackErrorMessage = "Missing media URL"
            localPlayer = nil
            viewModel.isPlaying = false
            return
        }

        playbackErrorMessage = nil
        localPlayer = AVPlayer(url: url)

        do {
            try await services.mediaPlayer.loadMedia(url: url)
        } catch {
            playbackErrorMessage = error.localizedDescription
        }

        if let override = subtitleModeOverride {
            viewModel.subtitleMode = override
        }

        await applyPlaybackRate(viewModel.playbackRate)
        await syncPlaybackState()
    }

    @MainActor
    private func monitorPlayback() async {
        while !Task.isCancelled {
            await syncPlaybackState()
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    @MainActor
    private func syncPlaybackState() async {
        guard !isSeeking else { return }

        guard let player = activePlayer else {
            viewModel.isPlaying = false
            return
        }

        let time = player.currentTime().seconds
        if time.isFinite {
            viewModel.seek(to: time)
        }

        viewModel.isPlaying = player.rate > 0
        if viewModel.isPlaying {
            viewModel.playbackRate = player.rate
        }
    }

    @MainActor
    private func togglePlayback() async {
        if viewModel.isPlaying {
            await pausePlayback()
        } else {
            await playPlayback()
        }
    }

    @MainActor
    private func playPlayback() async {
        if usingServicePlayer {
            await services.mediaPlayer.play()
        } else {
            localPlayer?.playImmediately(atRate: viewModel.playbackRate)
        }
        await syncPlaybackState()
    }

    @MainActor
    private func pausePlayback() async {
        if usingServicePlayer {
            await services.mediaPlayer.pause()
        } else {
            localPlayer?.pause()
        }
        viewModel.isPlaying = false
        await syncPlaybackState()
    }

    @MainActor
    private func seekPlayback(to time: Double) async {
        if usingServicePlayer {
            await services.mediaPlayer.seek(to: time)
        } else {
            let clamped = max(0, time)
            let seekTime = CMTime(seconds: clamped, preferredTimescale: 600)
            await localPlayer?.seek(to: seekTime)
        }
        viewModel.seek(to: time)
        await syncPlaybackState()
    }

    @MainActor
    private func seekRelativePlayback(_ offset: Double) async {
        await seekPlayback(to: viewModel.currentTime + offset)
    }

    @MainActor
    private func moveToPreviousSegment() async {
        viewModel.previousSegment()
        await seekPlayback(to: viewModel.currentTime)
    }

    @MainActor
    private func moveToNextSegment() async {
        viewModel.nextSegment()
        await seekPlayback(to: viewModel.currentTime)
    }

    @MainActor
    private func cyclePlaybackRate() async {
        viewModel.cyclePlaybackRate()
        await applyPlaybackRate(viewModel.playbackRate)
    }

    @MainActor
    private func applyPlaybackRate(_ rate: Float) async {
        if usingServicePlayer {
            await services.mediaPlayer.setPlaybackRate(rate)
        } else if let player = localPlayer {
            let wasPlaying = player.rate > 0
            if wasPlaying {
                player.rate = rate
            }
        }
        await syncPlaybackState()
    }

    private func formatTime(_ seconds: Double) -> String {
        let clamped = max(0, Int(seconds))
        let mins = clamped / 60
        let secs = clamped % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private struct InlineNavigationTitleDisplayModeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.navigationBarTitleDisplayMode(.inline)
        #else
        content
        #endif
    }
}

private extension View {
    func inlineNavigationTitleDisplayMode() -> some View {
        modifier(InlineNavigationTitleDisplayModeModifier())
    }
}

// MARK: - Wrapping HStack for Tappable Words

struct WrappingHStack<Content: View>: View {
    let words: [String]
    let content: (String) -> Content

    var body: some View {
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
