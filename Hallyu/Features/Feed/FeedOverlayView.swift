import SwiftUI

struct FeedOverlayView: View {
    let totalXP: Int
    let comboMultiplier: Int
    let goalProgress: Double
    let lastXPGain: Int
    let showXPAnimation: Bool
    let onDismissXP: () -> Void
    let onShowPlan: () -> Void

    var body: some View {
        VStack {
            // Top bar: XP counter + combo
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Spacer()

            // Bottom: progress dots + plan button
            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .allowsHitTesting(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            HStack(spacing: 12) {
                // XP counter with animation
                ZStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("\(totalXP) XP")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                    // Floating XP gain animation
                    if showXPAnimation {
                        Text("+\(lastXPGain)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.accentColor)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .offset(y: -28)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        onDismissXP()
                                    }
                                }
                            }
                    }
                }

                // Combo multiplier
                if comboMultiplier > 1 {
                    Text("x\(comboMultiplier)")
                        .font(.subheadline)
                        .fontWeight(.heavy)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.15), in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3), value: comboMultiplier)
        .animation(.spring(response: 0.3), value: totalXP)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Plan button
            Button {
                onShowPlan()
            } label: {
                Label("Plan", systemImage: "list.bullet.rectangle")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel("Show daily plan")
            .frame(minWidth: 44, minHeight: 44)

            Spacer()

            // Daily progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(goalProgress >= 1.0 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: goalProgress)

                if goalProgress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(Int(goalProgress * 100))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .accessibilityLabel("Daily goal progress: \(Int(goalProgress * 100)) percent")
        }
    }
}
