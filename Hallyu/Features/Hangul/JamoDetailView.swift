import SwiftUI

struct JamoDetailView: View {
    let jamo: JamoEntry
    let step: HangulLessonViewModel.JamoLessonStep
    let pronunciationFeedback: PronunciationFeedback?
    let recognitionResult: SpeechRecognitionResult?
    let isRecording: Bool

    var onAdvance: () -> Void
    var onTrace: (Double) -> Void
    var onStartRecording: () -> Void
    var onStopRecording: () -> Void
    var onPlayPronunciation: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator for steps
            stepIndicator

            switch step {
            case .strokeAnimation:
                strokeAnimationSection
            case .listenPronunciation:
                listenSection
            case .mnemonicHint:
                mnemonicSection
            case .tracePractice:
                traceSection
            case .speakPractice:
                speakSection
            case .claudeCoaching:
                coachingSection
            }

            Spacer()

            // Next button
            Button(action: onAdvance) {
                Text(step == .speakPractice && recognitionResult == nil ? "Skip" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(HangulLessonViewModel.JamoLessonStep.allCases, id: \.rawValue) { s in
                RoundedRectangle(cornerRadius: 2)
                    .fill(s <= step ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 3)
            }
        }
    }

    // MARK: - Sections

    private var strokeAnimationSection: some View {
        VStack(spacing: 16) {
            Text("Watch how to write")
                .font(.headline)

            StrokeOrderView(
                strokePaths: jamo.strokePaths,
                character: jamo.character
            )

            Text(String(jamo.character))
                .font(.system(size: 80, weight: .bold))
        }
    }

    private var listenSection: some View {
        VStack(spacing: 16) {
            Text("Listen carefully")
                .font(.headline)

            Text(String(jamo.character))
                .font(.system(size: 100, weight: .bold))

            Text(jamo.romanization)
                .font(.title2)
                .foregroundStyle(.secondary)

            Button(action: onPlayPronunciation) {
                Label("Play Sound", systemImage: "speaker.wave.3.fill")
                    .font(.title3)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("IPA: [\(jamo.ipa)]")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var mnemonicSection: some View {
        VStack(spacing: 16) {
            Text("Remember it!")
                .font(.headline)

            Text(String(jamo.character))
                .font(.system(size: 80, weight: .bold))

            Text(jamo.mnemonic)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(jamo.romanization)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var traceSection: some View {
        VStack(spacing: 16) {
            Text("Trace the character")
                .font(.headline)

            StrokeTracePracticeView(targetPaths: jamo.strokePaths)
        }
    }

    private var speakSection: some View {
        VStack(spacing: 16) {
            Text("Say it out loud!")
                .font(.headline)

            Text(String(jamo.character))
                .font(.system(size: 80, weight: .bold))

            Text(jamo.romanization)
                .font(.title2)
                .foregroundStyle(.secondary)

            Button(action: {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                }
            }) {
                Label(
                    isRecording ? "Stop" : "Record",
                    systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.title2)
                .foregroundStyle(isRecording ? .red : .blue)
                .padding()
                .background(
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                )
            }

            if let result = recognitionResult {
                VStack(spacing: 8) {
                    Text("Heard: \(result.transcript)")
                        .font(.title3)

                    let isGood = result.confidence >= 0.8
                    Label(
                        isGood ? "Great pronunciation!" : "Let's improve that",
                        systemImage: isGood ? "checkmark.circle.fill" : "arrow.clockwise"
                    )
                    .foregroundStyle(isGood ? .green : .orange)
                }
            }
        }
    }

    private var coachingSection: some View {
        VStack(spacing: 16) {
            Text("Pronunciation Coach")
                .font(.headline)

            if let feedback = pronunciationFeedback {
                VStack(alignment: .leading, spacing: 12) {
                    Text(feedback.feedback)
                        .font(.body)

                    if let tip = feedback.articulatoryTip {
                        Label(tip, systemImage: "lightbulb.fill")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }

                    if !feedback.similarSounds.isEmpty {
                        Text("Practice these similar sounds:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            ForEach(feedback.similarSounds, id: \.self) { sound in
                                Text(sound)
                                    .font(.title3)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ProgressView("Getting feedback...")
            }
        }
    }
}
