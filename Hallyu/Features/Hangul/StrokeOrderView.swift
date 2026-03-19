import SwiftUI

struct StrokeOrderView: View {
    let strokePaths: [StrokePath]
    let character: Character
    @AppStorage("autoplayAnimations") private var autoplayAnimations: Bool = true
    @State private var animationProgress: Double = 0
    @State private var currentStroke: Int = 0
    @State private var isAnimating: Bool = false
    @State private var animationSpeed: AnimationSpeed = .normal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum AnimationSpeed: String, CaseIterable {
        case slow = "Slow"
        case normal = "Normal"

        var duration: Double {
            switch self {
            case .slow: return 1.5
            case .normal: return 0.7
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Character display
            Text(String(character))
                .scaledFont(size: 32, weight: .bold)
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Jamo character \(String(character))")
                .accessibilityValue(strokeProgressValue)
                .accessibilityHint(
                    reduceMotion
                        ? "Reduced motion is enabled, so the full stroke order is shown at once."
                        : "Shows the stroke order for this character."
                )

            // Canvas
            Canvas { context, size in
                let scale = min(size.width, size.height)

                // Draw completed strokes
                for i in 0..<currentStroke {
                    guard i < strokePaths.count else { break }
                    drawStroke(context: context, stroke: strokePaths[i], scale: scale, progress: 1.0, color: .primary)
                }

                // Draw current stroke with animation
                if currentStroke < strokePaths.count {
                    drawStroke(
                        context: context,
                        stroke: strokePaths[currentStroke],
                        scale: scale,
                        progress: animationProgress,
                        color: .blue
                    )

                    // Draw pen indicator
                    if animationProgress > 0 && animationProgress < 1 {
                        let stroke = strokePaths[currentStroke]
                        if let position = interpolatePosition(points: stroke.points, progress: animationProgress) {
                            let penPoint = CGPoint(x: position.x * scale, y: position.y * scale)
                            let penCircle = Path(ellipseIn: CGRect(
                                x: penPoint.x - 4, y: penPoint.y - 4,
                                width: 8, height: 8
                            ))
                            context.fill(penCircle, with: .color(.red))
                        }
                    }
                }

                // Draw remaining strokes as guides
                for i in (currentStroke + 1)..<strokePaths.count {
                    drawStroke(context: context, stroke: strokePaths[i], scale: scale, progress: 1.0, color: .gray.opacity(0.2))
                }
            }
            .frame(width: 200, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
            .accessibilityHidden(true)

            // Controls
            HStack(spacing: 20) {
                Button(action: replay) {
                    Label(isAnimating ? "Playing..." : "Replay", systemImage: "arrow.counterclockwise")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isAnimating)
                .accessibilityLabel("Replay stroke animation")
                .accessibilityHint(
                    reduceMotion
                        ? "Resets the character display without animation."
                        : "Plays the stroke order animation again."
                )

                Picker("Speed", selection: $animationSpeed) {
                    ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                        Text(speed.rawValue).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140, minHeight: 44)
                .accessibilityLabel("Animation speed")
                .accessibilityHint("Choose how fast the stroke animation plays.")
            }
        }
        .onAppear {
            if autoplayAnimations && !reduceMotion {
                startAnimation()
            } else {
                isAnimating = false
                currentStroke = strokePaths.count
                animationProgress = 1.0
            }
        }
    }

    private func drawStroke(context: GraphicsContext, stroke: StrokePath, scale: CGFloat, progress: Double, color: Color) {
        guard stroke.points.count >= 2 else { return }

        var path = Path()
        let scaledPoints = stroke.points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }

        path.move(to: scaledPoints[0])

        let totalSegments = scaledPoints.count - 1
        let segmentsToShow = Int(Double(totalSegments) * progress)
        let partialProgress = (Double(totalSegments) * progress) - Double(segmentsToShow)

        for i in 0..<min(segmentsToShow, totalSegments) {
            path.addLine(to: scaledPoints[i + 1])
        }

        if segmentsToShow < totalSegments && partialProgress > 0 {
            let from = scaledPoints[segmentsToShow]
            let to = scaledPoints[segmentsToShow + 1]
            let intermediate = CGPoint(
                x: from.x + (to.x - from.x) * partialProgress,
                y: from.y + (to.y - from.y) * partialProgress
            )
            path.addLine(to: intermediate)
        }

        context.stroke(path, with: .color(color), lineWidth: 4)
    }

    private func interpolatePosition(points: [CGPoint], progress: Double) -> CGPoint? {
        guard points.count >= 2 else { return points.first }

        let totalSegments = points.count - 1
        let exactSegment = Double(totalSegments) * progress
        let segmentIndex = min(Int(exactSegment), totalSegments - 1)
        let segmentProgress = exactSegment - Double(segmentIndex)

        let from = points[segmentIndex]
        let to = points[min(segmentIndex + 1, points.count - 1)]

        return CGPoint(
            x: from.x + (to.x - from.x) * segmentProgress,
            y: from.y + (to.y - from.y) * segmentProgress
        )
    }

    private func startAnimation() {
        guard !isAnimating else { return }
        if reduceMotion {
            isAnimating = false
            currentStroke = strokePaths.count
            animationProgress = 1
            return
        }
        isAnimating = true
        currentStroke = 0
        animationProgress = 0
        animateNextStroke()
    }

    private func animateNextStroke() {
        guard !reduceMotion else { return }
        guard currentStroke < strokePaths.count else {
            isAnimating = false
            return
        }

        animationProgress = 0
        withAnimation(reduceMotion ? nil : .linear(duration: animationSpeed.duration)) {
            animationProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationSpeed.duration + 0.2) {
            currentStroke += 1
            animateNextStroke()
        }
    }

    private func replay() {
        if reduceMotion {
            isAnimating = false
            currentStroke = strokePaths.count
            animationProgress = 1
            return
        }
        isAnimating = false
        currentStroke = 0
        animationProgress = 0
        startAnimation()
    }

    private var strokeProgressValue: String {
        guard !strokePaths.isEmpty else { return "No stroke data available" }
        if reduceMotion {
            return "Stroke order shown statically"
        }
        return "Stroke \(min(currentStroke + 1, strokePaths.count)) of \(strokePaths.count)"
    }
}

// MARK: - Trace Practice View

struct StrokeTracePracticeView: View {
    let targetPaths: [StrokePath]
    @State private var userPoints: [[CGPoint]] = []
    @State private var currentDrawing: [CGPoint] = []
    @State private var score: Double?

    var body: some View {
        VStack(spacing: 16) {
            Canvas { context, size in
                let scale = min(size.width, size.height)

                // Draw target as guide
                for stroke in targetPaths {
                    var path = Path()
                    let scaled = stroke.points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
                    guard let first = scaled.first else { continue }
                    path.move(to: first)
                    for point in scaled.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 6)
                }

                // Draw user strokes
                for stroke in userPoints {
                    guard stroke.count >= 2 else { continue }
                    var path = Path()
                    path.move(to: stroke[0])
                    for point in stroke.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.blue), lineWidth: 3)
                }

                // Draw current stroke
                if currentDrawing.count >= 2 {
                    var path = Path()
                    path.move(to: currentDrawing[0])
                    for point in currentDrawing.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.blue), lineWidth: 3)
                }
            }
            .frame(width: 200, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentDrawing.append(value.location)
                    }
                    .onEnded { _ in
                        userPoints.append(currentDrawing)
                        currentDrawing = []
                        if userPoints.count >= targetPaths.count {
                            score = calculateScore()
                        }
                    }
            )

            if let score = score {
                HStack {
                    Text("Accuracy:")
                    Text("\(Int(score * 100))%")
                        .fontWeight(.bold)
                        .foregroundStyle(score > 0.7 ? .green : score > 0.4 ? .orange : .red)
                }

                Button("Try Again") {
                    userPoints = []
                    currentDrawing = []
                    self.score = nil
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func calculateScore() -> Double {
        guard !targetPaths.isEmpty, !userPoints.isEmpty else { return 0 }

        var totalScore = 0.0
        let pairs = min(targetPaths.count, userPoints.count)

        for i in 0..<pairs {
            let targetPoints = targetPaths[i].points
            let userStroke = userPoints[i]

            guard !targetPoints.isEmpty, !userStroke.isEmpty else { continue }

            // Sample and compare points
            let sampleCount = 10
            var strokeScore = 0.0

            for s in 0..<sampleCount {
                let t = Double(s) / Double(sampleCount - 1)
                let targetIdx = min(Int(t * Double(targetPoints.count - 1)), targetPoints.count - 1)
                let userIdx = min(Int(t * Double(userStroke.count - 1)), userStroke.count - 1)

                // Normalize user points to 0-1 range
                let canvasSize = 200.0
                let normalizedUser = CGPoint(
                    x: userStroke[userIdx].x / canvasSize,
                    y: userStroke[userIdx].y / canvasSize
                )

                let dx = normalizedUser.x - targetPoints[targetIdx].x
                let dy = normalizedUser.y - targetPoints[targetIdx].y
                let distance = sqrt(dx * dx + dy * dy)

                // Score inversely proportional to distance (max distance ~1.4)
                strokeScore += max(0, 1.0 - distance * 2)
            }

            totalScore += strokeScore / Double(sampleCount)
        }

        return totalScore / Double(pairs)
    }
}
