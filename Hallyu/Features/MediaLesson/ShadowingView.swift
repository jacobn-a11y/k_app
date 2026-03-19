import SwiftUI
import AVFoundation

/// Step 5.3: Shadowing practice - user listens to and repeats key sentences.
struct ShadowingView: View {
    @Bindable var viewModel: MediaLessonViewModel
    @State private var isRecording: Bool = false
    @State private var lastTranscript: String = ""
    @State private var lastConfidence: Double = 0
    @State private var lastPronunciationScore: PronunciationScore?
    @State private var showFeedback: Bool = false
    @State private var lastClaudeFeedback: PronunciationFeedback?
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 16) {
            if let sentence = viewModel.currentShadowingSentence {
                sentenceView(sentence)
            } else {
                completedView
            }
        }
        .padding()
    }

    // MARK: - Sentence View

    private func sentenceView(_ sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 20) {
            // Progress
            HStack {
                Text("Sentence \(viewModel.shadowingCurrentIndex + 1) of \(viewModel.shadowingSentences.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if sentence.attempts > 0 {
                    Text("Attempt \(sentence.attempts)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Target sentence
            VStack(spacing: 12) {
                Text(sentence.korean)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(sentence.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )

            // Play native audio button
            Button {
                playNativeSentence(sentence.korean)
            } label: {
                Label("Listen to Native", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Recording area
            recordingArea(sentence: sentence)

            // Feedback area
            if showFeedback {
                feedbackArea(sentence: sentence)
            }

            Spacer()
        }
    }

    // MARK: - Recording

    private func recordingArea(sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 12) {
            // Waveform placeholder
            if isRecording {
                waveformIndicator
            }

            // Record button
            Button {
                if isRecording {
                    stopRecording(targetSentence: sentence.korean)
                } else {
                    startRecording()
                }
            } label: {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .scaledFont(size: 32)
                    Text(isRecording ? "Stop Recording" : "Record Your Voice")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? .red : .accentColor)
        }
    }

    private var waveformIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: CGFloat.random(in: 8...32))
            }
        }
        .frame(height: 40)
        .padding(.horizontal)
    }

    // MARK: - Feedback

    private func feedbackArea(sentence: MediaLessonViewModel.ShadowingSentence) -> some View {
        VStack(spacing: 12) {
            // Transcript comparison
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(sentence.korean)
                    .font(.body)

                HStack {
                    Text("You said:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(lastTranscript.isEmpty ? "(no speech detected)" : lastTranscript)
                    .font(.body)
                    .foregroundStyle((lastPronunciationScore?.overall ?? lastConfidence) >= 0.7 ? .green : .orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            // Confidence score
            HStack {
                let overall = lastPronunciationScore?.overall ?? lastConfidence
                Text("Match: \(Int(overall * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(overall >= 0.7 ? .green : .orange)

                Spacer()

                confidenceBadge
            }

            if let score = lastPronunciationScore {
                Text("Jamo \(Int(score.jamoAccuracy * 100))% • Prosody \(Int(score.prosodyAccuracy * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showFeedback = false
                    lastTranscript = ""
                    lastConfidence = 0
                    lastPronunciationScore = nil
                    lastClaudeFeedback = nil
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    withAnimation { viewModel.nextShadowingSentence() }
                    showFeedback = false
                    lastTranscript = ""
                    lastConfidence = 0
                    lastPronunciationScore = nil
                    lastClaudeFeedback = nil
                } label: {
                    Text(viewModel.shadowingCurrentIndex + 1 < viewModel.shadowingSentences.count ? "Next" : "Finish")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if let claudeFeedback = lastClaudeFeedback {
                VStack(alignment: .leading, spacing: 6) {
                    Text(claudeFeedback.feedback)
                        .font(.subheadline)
                    if let tip = claudeFeedback.articulatoryTip {
                        Text("Tip: \(tip)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var confidenceBadge: some View {
        let overall = lastPronunciationScore?.overall ?? lastConfidence
        let (text, color): (String, Color) = {
            if overall >= 0.9 { return ("Excellent", .green) }
            if overall >= 0.7 { return ("Good", .blue) }
            if overall >= 0.5 { return ("Fair", .orange) }
            return ("Keep Trying", .red)
        }()

        return Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Recording Actions

    private func startRecording() {
        isRecording = true
        Task {
            _ = try? await viewModel.audioService.startRecording()
        }
    }

    private func stopRecording(targetSentence: String) {
        isRecording = false
        Task {
            guard let audioURL = try? await viewModel.audioService.stopRecording() else { return }
            let result = try? await viewModel.speechRecognition.recognizeSpeech(from: audioURL)
            let claudeFeedback = await viewModel.getPronunciationFeedback(
                transcript: result?.transcript ?? "",
                target: targetSentence
            )

            await MainActor.run {
                let transcript = result?.transcript ?? ""
                let asrConfidence = result?.confidence ?? 0
                let score = PronunciationScorer.evaluate(
                    transcript: transcript,
                    target: targetSentence,
                    asrConfidence: asrConfidence
                )

                lastTranscript = transcript
                lastConfidence = score.overall
                lastPronunciationScore = score
                lastClaudeFeedback = claudeFeedback
                showFeedback = true
                viewModel.recordShadowingAttempt(
                    transcript: lastTranscript,
                    confidence: score.overall
                )
            }
        }
    }

    private func playNativeSentence(_ text: String) {
        guard !text.isEmpty else { return }
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.42
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .scaledFont(size: 64)
                .foregroundStyle(.accentColor)

            Text("Shadowing Complete!")
                .font(.title2)
                .fontWeight(.bold)

            let practiced = viewModel.shadowingSentences.prefix(viewModel.shadowingCurrentIndex)
            let avgConfidence = practiced.isEmpty ? 0 :
                practiced.reduce(0.0) { $0 + $1.bestConfidence } / Double(practiced.count)

            Text("Average match: \(Int(avgConfidence * 100))%")
                .font(.title3)
                .foregroundStyle(avgConfidence >= 0.7 ? .green : .orange)

            Text("\(practiced.count) sentences practiced")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
