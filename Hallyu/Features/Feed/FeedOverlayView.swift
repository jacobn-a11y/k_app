import SwiftUI

struct FeedOverlayView: View {
    let totalXP: Int
    let comboMultiplier: Int
    let goalProgress: Double
    let lastXPGain: Int
    let showXPAnimation: Bool
    let isBonusRound: Bool
    let almostDoneCount: Int?
    let streakCelebration: Int?
    let onDismissXP: () -> Void
    let onDismissStreak: () -> Void
    let onDismissAlmostDone: () -> Void
    let onShowPlan: () -> Void
    let onShowSummary: () -> Void

    var body: some View {
        ZStack {
            VStack {
                // Top bar: XP counter + combo
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                // "Almost done" overlay
                if let remaining = almostDoneCount {
                    almostDoneOverlay(remaining: remaining)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }

                // Bonus round label
                if isBonusRound {
                    bonusRoundLabel
                        .padding(.bottom, 4)
                }

                // Bottom: progress dots + plan button
                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .allowsHitTesting(true)

            // Streak celebration toast
            if let streak = streakCelebration {
                streakCelebrationToast(streak: streak)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: almostDoneCount != nil)
        .animation(.spring(response: 0.4), value: isBonusRound)
        .animation(.spring(response: 0.3), value: streakCelebration)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Session summary button (pause)
            Button {
                onShowSummary()
            } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Pause and view session summary")
            .frame(minWidth: 44, minHeight: 44)

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

    // MARK: - Almost Done Overlay

    private func almostDoneOverlay(remaining: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flag.fill")
                .font(.caption)
            Text("\(remaining) more to hit today's goal!")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.accentColor, in: Capsule())
        .onAppear {
            HapticManager.play(.light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    onDismissAlmostDone()
                }
            }
        }
        .accessibilityLabel("\(remaining) cards remaining to reach today's goal")
    }

    // MARK: - Bonus Round Label

    private var bonusRoundLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text("Bonus Round")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.yellow)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.yellow.opacity(0.15), in: Capsule())
        .accessibilityLabel("Bonus round: extra practice beyond daily goal")
    }

    // MARK: - Streak Celebration Toast

    private func streakCelebrationToast(streak: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("\(streak) in a row!")
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            HapticManager.play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    onDismissStreak()
                }
            }
        }
        .accessibilityLabel("\(streak) correct answers in a row! Great job!")
    }
}
