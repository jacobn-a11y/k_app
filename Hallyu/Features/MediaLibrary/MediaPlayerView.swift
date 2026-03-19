import SwiftUI
import AVKit

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
    let avPlayer: AVPlayer?
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

    var hasPlayableMedia: Bool {
        avPlayer != nil
    }

    init(content: MediaContent) {
        self.content = content
        if let url = URL(string: content.mediaUrl),
           let scheme = url.scheme?.lowercased(),
           ["https", "http", "file"].contains(scheme) {
            self.avPlayer = AVPlayer(url: url)
        } else {
            self.avPlayer = nil
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            avPlayer?.play()
            avPlayer?.rate = playbackRate
        } else {
            avPlayer?.pause()
        }
    }

    func seek(to time: Double) {
        currentTime = max(0, min(time, duration))
        avPlayer?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
        refreshPlaybackProgress()
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
        setPlaybackRate(Self.playbackRates[nextIndex])
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            avPlayer?.rate = playbackRate
        }
    }

    func tapWord(_ word: String) {
        highlightedWord = word
        showWordDetail = true
    }

    func dismissWordDetail() {
        showWordDetail = false
        highlightedWord = nil
    }

    func refreshPlaybackProgress() {
        if let playerTime = avPlayer?.currentTime().seconds,
           playerTime.isFinite {
            currentTime = playerTime
        }
        let timeMs = Int(currentTime * 1000)
        if let index = segments.firstIndex(where: { timeMs >= $0.startMs && timeMs < $0.endMs }) {
            currentSegmentIndex = index
        }
    }
}

// MARK: - MediaPlayerView

struct MediaPlayerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.subtitleModeOverride) private var subtitleModeOverride
    @AppStorage("highContrastMode") private var highContrastMode: Bool = false
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @AppStorage("defaultSubtitleMode") private var defaultSubtitleMode: String = "korean"
    @AppStorage("showRomanization") private var showRomanization: Bool = true
    @State private var viewModel: MediaPlayerViewModel
    @State private var didApplySubtitleOverride = false
    private let playbackTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

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
        .onReceive(playbackTimer) { _ in
            guard viewModel.isPlaying else { return }
            viewModel.refreshPlaybackProgress()
        }
        .onAppear {
            guard !didApplySubtitleOverride else { return }
            viewModel.setPlaybackRate(Float(defaultPlaybackSpeed))
            if let subtitleModeOverride {
                viewModel.subtitleMode = subtitleModeOverride
            } else {
                viewModel.subtitleMode = subtitleModeFromSettings(defaultSubtitleMode)
            }
            didApplySubtitleOverride = true
        }
        .onChange(of: subtitleModeOverride) { _, override in
            guard let override else { return }
            viewModel.subtitleMode = override
        }
        .onChange(of: defaultPlaybackSpeed) { _, speed in
            viewModel.setPlaybackRate(Float(speed))
        }
        .onChange(of: defaultSubtitleMode) { _, mode in
            guard subtitleModeOverride == nil else { return }
            viewModel.subtitleMode = subtitleModeFromSettings(mode)
        }
        .onDisappear {
            viewModel.avPlayer?.pause()
            viewModel.isPlaying = false
        }
    }

    // MARK: - Video Player Area

    private var videoPlayerArea: some View {
        ZStack {
            if let player = viewModel.avPlayer, viewModel.hasPlayableMedia {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .onAppear {
                        player.pause()
                    }
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.black)
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash.fill")
                                .scaledFont(size: 32)
                                .foregroundStyle(.white.opacity(0.75))
                            Text("No playable stream for this item")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
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

            if showRomanization && HangulUtilities.containsKorean(segment.textKr) {
                Text(romanizedText(for: segment.textKr))
                    .font(.caption)
                    .foregroundStyle(highContrastMode ? Color.primary : .secondary)
            }

            if viewModel.subtitleMode == .koreanAndEnglish {
                Text(segment.textEn)
                    .font(.subheadline)
                    .foregroundStyle(highContrastMode ? Color.primary : .secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            isActive
                ? (highContrastMode ? Color.primary.opacity(0.18) : Color.accentColor.opacity(0.1))
                : Color.clear
        )
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

                if showRomanization && HangulUtilities.containsKorean(segment.textKr) {
                    Text(romanizedText(for: segment.textKr))
                        .font(.caption)
                        .foregroundStyle(highContrastMode ? Color.primary : .secondary)
                        .padding(.horizontal)
                }

                if viewModel.subtitleMode == .koreanAndEnglish {
                    Text(segment.textEn)
                        .font(.subheadline)
                        .foregroundStyle(highContrastMode ? Color.primary : .secondary)
                        .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 60)
        .padding(.vertical, 8)
        .background(highContrastMode ? Color(.systemGray5) : Color(.systemGray6))
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        VStack(spacing: 8) {
            // Progress bar
            HStack(spacing: 8) {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(highContrastMode ? Color.primary : .secondary)

                Slider(value: $viewModel.currentTime, in: 0...max(viewModel.duration, 1)) { editing in
                    if !editing {
                        viewModel.seek(to: viewModel.currentTime)
                    }
                }

                Text(formatTime(viewModel.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(highContrastMode ? Color.primary : .secondary)
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
                        .scaledFont(size: 44)
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
                        .foregroundStyle(highContrastMode ? Color.white : Color.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(highContrastMode ? Color.black.opacity(0.8) : Color(.systemGray5))
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
                    viewModel.setPlaybackRate(rate)
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
        Group {
            if let word = viewModel.highlightedWord {
                ClaudeWordCoachSheet(
                    mediaContentId: viewModel.content.id,
                    word: word,
                    mediaTitle: viewModel.content.title,
                    transcript: viewModel.currentSegment?.textKr ?? viewModel.content.transcriptKr,
                    learnerLevel: appState.currentCEFRLevel.rawValue,
                    userId: appState.currentUserId ?? UUID()
                ) {
                    viewModel.dismissWordDetail()
                }
            } else {
                ContentUnavailableView("No Word Selected", systemImage: "text.cursor")
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

    private func subtitleModeFromSettings(_ value: String) -> SubtitleMode {
        switch value.lowercased() {
        case "none":
            return .none
        case "both":
            return .koreanAndEnglish
        default:
            return .koreanOnly
        }
    }

    private func romanizedText(for text: String) -> String {
        HangulUtilities.romanize(text)
    }
}

// MARK: - Claude Coach Sheet

private struct ClaudeWordCoachSheet: View {
    enum Tool: String, CaseIterable, Identifiable {
        case comprehension
        case grammar
        case culture
        case practice

        var id: String { rawValue }

        var label: String {
            switch self {
            case .comprehension: return "Meaning"
            case .grammar: return "Grammar"
            case .culture: return "Culture"
            case .practice: return "Practice"
            }
        }
    }

    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState

    let mediaContentId: UUID
    let word: String
    let mediaTitle: String
    let transcript: String
    let learnerLevel: String
    let userId: UUID
    let onClose: () -> Void

    @State private var selectedTool: Tool = .comprehension
    @State private var didInitialize = false
    @State private var comprehensionVM: ComprehensionCoachViewModel?
    @State private var grammarVM: GrammarExplainerViewModel?
    @State private var culturalVM: CulturalContextViewModel?
    @State private var contentAdapterVM: ContentAdapterViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Claude Tools", selection: $selectedTool) {
                    ForEach(Tool.allCases) { tool in
                        Text(tool.label).tag(tool)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTool {
                case .comprehension:
                    if let comprehensionVM {
                        ComprehensionCoachView(
                            viewModel: comprehensionVM,
                            transcript: transcript,
                            learnerLevel: learnerLevel,
                            knownVocabulary: [],
                            userId: userId
                        )
                    }
                case .grammar:
                    if let grammarVM {
                        GrammarExplainerView(viewModel: grammarVM, userId: userId)
                    }
                case .culture:
                    if let culturalVM {
                        CulturalContextView(viewModel: culturalVM)
                    }
                case .practice:
                    if let contentAdapterVM {
                        ContentAdapterView(viewModel: contentAdapterVM, userId: userId)
                    }
                }
            }
            .padding()
            .navigationTitle(word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
        .task {
            await initializeIfNeeded()
        }
    }

    private func initializeIfNeeded() async {
        guard !didInitialize else { return }
        didInitialize = true

        let comprehension = ComprehensionCoachViewModel(
            claudeService: services.claude,
            learnerModel: services.learnerModel,
            subscriptionTier: appState.subscriptionTier
        )
        comprehension.onWordTapped(
            word: word,
            mediaTitle: mediaTitle,
            transcript: transcript,
            learnerLevel: learnerLevel,
            knownVocabulary: []
        )

        let grammar = GrammarExplainerViewModel(
            claudeService: services.claude,
            learnerModel: services.learnerModel
        )
        let grammarPattern = KoreanTextAnalyzer.detectGrammarPatterns(in: transcript).first ?? word
        grammar.presentGrammar(pattern: grammarPattern, mediaContext: transcript)

        let cultural = CulturalContextViewModel(claudeService: services.claude)
        await cultural.flagMoment(moment: transcript, mediaContext: mediaTitle)

        let contentAdapter = ContentAdapterViewModel(
            claudeService: services.claude,
            learnerModel: services.learnerModel
        )
        await contentAdapter.generateExercises(
            mediaContentId: mediaContentId,
            learnerLevel: learnerLevel
        )

        comprehensionVM = comprehension
        grammarVM = grammar
        culturalVM = cultural
        contentAdapterVM = contentAdapter
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

// MARK: - Subtitle Mode Override Environment Key

private struct SubtitleModeOverrideKey: EnvironmentKey {
    static let defaultValue: SubtitleMode? = nil
}

extension EnvironmentValues {
    var subtitleModeOverride: SubtitleMode? {
        get { self[SubtitleModeOverrideKey.self] }
        set { self[SubtitleModeOverrideKey.self] = newValue }
    }
}
