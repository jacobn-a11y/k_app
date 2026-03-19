import SwiftUI

struct PronunciationFeedCard: View {
    let info: PronunciationCardInfo
    let services: ServiceContainer
    let onComplete: (Double) -> Void

    @State private var isRecording = false
    @State private var recognitionResult: SpeechRecognitionResult?
    @State private var hasCompleted = false
    @State private var isPlayingAudio = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Speak")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            if !info.sourceTitle.isEmpty {
                Text("From: \(info.sourceTitle)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Phrase to shadow
            VStack(spacing: 8) {
                Text(info.phrase)
                    .font(.system(size: 28, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(info.translation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            if let result = recognitionResult {
                // Result display
                VStack(spacing: 8) {
                    Text("\(Int(result.confidence * 100))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(confidenceColor(result.confidence))

                    Text(result.transcript)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text(feedbackText(confidence: result.confidence))
                        .font(.subheadline)
                        .foregroundStyle(confidenceColor(result.confidence))
                }
                .padding(.vertical, 8)
            } else if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Record button
            if !hasCompleted {
                Button {
                    toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.accentColor)
                            .frame(width: 72, height: 72)

                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .accessibilityLabel(isRecording ? "Stop recording" : "Record your pronunciation")
                .frame(minWidth: 72, minHeight: 72)

                Text(isRecording ? "Tap to stop" : "Tap to record")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }

    private func feedbackText(confidence: Double) -> String {
        if confidence >= 0.9 { return "Perfect!" }
        if confidence >= 0.8 { return "Great job!" }
        if confidence >= 0.6 { return "Good effort!" }
        return "Keep practicing!"
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            do {
                isRecording = true
                errorMessage = nil
                _ = try await services.audio.startRecording()
            } catch {
                isRecording = false
                errorMessage = "Couldn't start recording"
            }
        }
    }

    private func stopRecording() {
        Task {
            do {
                let audioURL = try await services.audio.stopRecording()
                isRecording = false

                let result = try await services.speechRecognition.recognizeSpeech(from: audioURL)
                recognitionResult = result
                hasCompleted = true
                onComplete(result.confidence)
            } catch {
                isRecording = false
                errorMessage = "Recognition failed. Try again."
            }
        }
    }
}
