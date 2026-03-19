import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - View

struct SpotInTheWildView: View {
    @State private var viewModel: SpotInTheWildViewModel
    @State private var showFeedback: Bool = false
    @State private var lastTapResult: SpotInTheWildViewModel.TapResult?
    @State private var feedbackPosition: CGPoint = .zero
    let onComplete: ((Double) -> Void)?

    init(task: SpotInTheWildTask, onComplete: ((Double) -> Void)? = nil) {
        _viewModel = State(initialValue: SpotInTheWildViewModel(task: task))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 16) {
            // Instruction
            VStack(spacing: 4) {
                Text("Find all the")
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(String(viewModel.task.targetJamo))
                        .scaledFont(size: 36, weight: .bold)
                        .foregroundStyle(.blue)
                    Text("in this image!")
                        .font(.headline)
                }
                Text("\(viewModel.remainingCount) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Image area with tap targets
            GeometryReader { geo in
                ZStack {
                    taskSurfaceBackground

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Spot the character", systemImage: "hand.tap.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                            Spacer()
                        }

                        Spacer()

                        Text(viewModel.task.imageDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()

                    // Show target overlays
                    ForEach(viewModel.task.tapTargets) { target in
                        targetOverlay(target: target, in: geo.size)
                            .opacity(viewModel.foundTargets.contains(target.id) ? 1.0 : 0.92)
                    }

                    // Show found targets
                    ForEach(viewModel.task.tapTargets) { target in
                        if viewModel.foundTargets.contains(target.id) {
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                                .frame(
                                    width: target.boundingBox.width * geo.size.width,
                                    height: target.boundingBox.height * geo.size.height
                                )
                                .position(
                                    x: (target.boundingBox.midX) * geo.size.width,
                                    y: (target.boundingBox.midY) * geo.size.height
                                )
                                .overlay {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .position(
                                            x: (target.boundingBox.midX) * geo.size.width,
                                            y: (target.boundingBox.midY) * geo.size.height
                                        )
                                }
                        }
                    }

                    // Tap feedback
                    if showFeedback {
                        let isHit = {
                            if case .found = lastTapResult { return true }
                            return false
                        }()
                        Image(systemName: isHit ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(isHit ? .green : .red)
                            .position(feedbackPosition)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let normalized = CGPoint(
                        x: location.x / geo.size.width,
                        y: location.y / geo.size.height
                    )
                    feedbackPosition = location
                    lastTapResult = viewModel.handleTap(at: normalized)
                    showFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFeedback = false
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)

            // Completion
            if viewModel.isComplete {
                VStack(spacing: 8) {
                    Label("All found!", systemImage: "party.popper.fill")
                        .font(.title2)
                        .foregroundStyle(.green)

                    Text("Accuracy: \(Int(viewModel.score * 100))%")
                        .font(.headline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            guard isComplete else { return }
            onComplete?(viewModel.score)
        }
    }

    private var pseudoMediaBackdrop: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(pseudoSceneGradient)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
    }

    private var pseudoMediaAccents: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: -92, y: -80)

            RoundedRectangle(cornerRadius: 24)
                .fill(.black.opacity(0.08))
                .frame(width: 170, height: 72)
                .rotationEffect(.degrees(-12))
                .offset(x: 86, y: -62)

            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.10))
                .frame(width: 150, height: 56)
                .rotationEffect(.degrees(11))
                .offset(x: 80, y: 95)
        }
    }

    private func targetOverlay(target: TapTarget, in size: CGSize) -> some View {
        let isFound = viewModel.foundTargets.contains(target.id)
        let width = target.boundingBox.width * size.width
        let height = target.boundingBox.height * size.height

        return VStack(spacing: 2) {
            Text(target.character)
                .font(.system(size: max(min(width, height) * 0.65, 18), weight: .bold, design: .rounded))
                .foregroundStyle(isFound ? .green : .primary)

            Text(isFound ? "Found" : "Tap")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isFound ? .green : .secondary)
        }
        .frame(width: width, height: height)
        .padding(4)
        .background(isFound ? Color.green.opacity(0.16) : Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFound ? Color.green : Color.white.opacity(0.75), lineWidth: 2)
        )
        .shadow(color: .black.opacity(isFound ? 0.08 : 0.16), radius: 6, x: 0, y: 2)
        .position(
            x: (target.boundingBox.midX) * size.width,
            y: (target.boundingBox.midY) * size.height
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(target.character) \(isFound ? "found" : "tap target")")
    }

    private var pseudoSceneGradient: LinearGradient {
        let palette = taskPalette
        return LinearGradient(
            colors: [palette.top, palette.mid, palette.bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var taskPalette: (top: Color, mid: Color, bottom: Color) {
        switch viewModel.task.targetJamo {
        case "ㄱ":
            return (.indigo.opacity(0.95), .blue.opacity(0.90), .cyan.opacity(0.95))
        case "ㅏ":
            return (.orange.opacity(0.95), .pink.opacity(0.88), .red.opacity(0.82))
        default:
            return (.purple.opacity(0.95), .blue.opacity(0.88), .mint.opacity(0.92))
        }
    }

    @ViewBuilder
    private var taskSurfaceBackground: some View {
        if let image = bundledTaskImage {
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.16))
                }
        } else {
            pseudoMediaBackdrop
            pseudoMediaAccents
        }
    }

    private var bundledTaskImage: Image? {
        #if canImport(UIKit)
        guard let image = UIImage(named: viewModel.task.imageName) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(named: viewModel.task.imageName) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}
