import SwiftUI

// MARK: - Jamo Watch Card (Stroke Animation)

struct JamoWatchFeedCard: View {
    let jamo: JamoEntry
    let onComplete: () -> Void

    @State private var animatedPathIndex: Int = 0
    @State private var hasCompleted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Text("Watch")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            // Large jamo character
            Text(String(jamo.character))
                .font(.system(size: 160, weight: .light))
                .foregroundStyle(.primary)
                .accessibilityLabel("Korean character \(jamo.romanization)")

            // Romanization and IPA
            VStack(spacing: 4) {
                Text(jamo.romanization)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("[\(jamo.ipa)]")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Mnemonic
            Text(jamo.mnemonic)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Stroke path indicators
            HStack(spacing: 8) {
                ForEach(0..<jamo.strokePaths.count, id: \.self) { index in
                    Circle()
                        .fill(index <= animatedPathIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            animateStrokes()
        }
    }

    private func animateStrokes() {
        guard !reduceMotion else {
            animatedPathIndex = jamo.strokePaths.count - 1
            completeAfterDelay()
            return
        }

        for i in 0..<jamo.strokePaths.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animatedPathIndex = i
                }
                if i == jamo.strokePaths.count - 1 {
                    completeAfterDelay()
                }
            }
        }
    }

    private func completeAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard !hasCompleted else { return }
            hasCompleted = true
            onComplete()
        }
    }
}

// MARK: - Jamo Trace Card

struct JamoTraceFeedCard: View {
    let jamo: JamoEntry
    let onComplete: (Double) -> Void

    @State private var tracePoints: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var hasSubmitted = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Trace")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            Text(String(jamo.character))
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            // Trace canvas
            traceCanvas
                .frame(width: 250, height: 250)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if !hasSubmitted {
                HStack(spacing: 16) {
                    Button("Clear") {
                        tracePoints = []
                        currentStroke = []
                    }
                    .buttonStyle(.bordered)
                    .frame(minWidth: 44, minHeight: 44)

                    Button("Done") {
                        submitTrace()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(tracePoints.isEmpty && currentStroke.isEmpty)
                }
            } else {
                Label("Nice work!", systemImage: "hand.thumbsup.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .accessibilityLabel("Trace the character \(jamo.romanization)")
    }

    private var traceCanvas: some View {
        Canvas { context, size in
            // Draw guide character lightly
            let guideText = Text(String(jamo.character))
                .font(.system(size: 180, weight: .ultraLight))
                .foregroundColor(.gray.opacity(0.15))
            context.draw(guideText, at: CGPoint(x: size.width / 2, y: size.height / 2))

            // Draw completed strokes
            for stroke in tracePoints {
                drawStroke(stroke, in: &context, color: .accentColor)
            }
            // Draw current stroke
            if !currentStroke.isEmpty {
                drawStroke(currentStroke, in: &context, color: .accentColor)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentStroke.append(value.location)
                }
                .onEnded { _ in
                    if !currentStroke.isEmpty {
                        tracePoints.append(currentStroke)
                        currentStroke = []
                    }
                }
        )
    }

    private func drawStroke(_ points: [CGPoint], in context: inout GraphicsContext, color: Color) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(path, with: .color(color), lineWidth: 6)
    }

    private func submitTrace() {
        hasSubmitted = true
        // Simple scoring: more strokes matching expected count = better
        let expectedStrokes = jamo.strokePaths.count
        let actualStrokes = tracePoints.count
        let score = actualStrokes > 0 ? min(1.0, Double(min(actualStrokes, expectedStrokes)) / Double(expectedStrokes)) : 0.0
        onComplete(max(0.5, score)) // Floor at 0.5 for attempting
    }
}

// MARK: - Jamo Speak Card

struct JamoSpeakFeedCard: View {
    let jamo: JamoEntry
    let services: ServiceContainer
    let onComplete: (Double) -> Void

    @State private var isRecording = false
    @State private var recognitionResult: SpeechRecognitionResult?
    @State private var hasCompleted = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Speak")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(2)

            Text(String(jamo.character))
                .font(.system(size: 120, weight: .light))
                .foregroundStyle(.primary)

            Text("Say: \"\(jamo.romanization)\"")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let result = recognitionResult {
                resultView(result: result)
            } else if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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
                .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
                .frame(minWidth: 72, minHeight: 72)
            }
        }
    }

    private func resultView(result: SpeechRecognitionResult) -> some View {
        VStack(spacing: 8) {
            Text("\(Int(result.confidence * 100))%")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(result.confidence >= 0.7 ? .green : .orange)

            Text(result.transcript)
                .font(.body)
                .foregroundStyle(.secondary)
        }
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
