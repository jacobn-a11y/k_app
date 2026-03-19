import SwiftUI

struct MilestoneCardView: View {
    let info: MilestoneInfo
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var hasAutoCompleted = false

    var body: some View {
        ZStack {
            // Confetti particles
            if showConfetti {
                ConfettiOverlay()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                if showContent {
                    // Icon
                    Image(systemName: milestoneIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(milestoneColor)
                        .symbolEffect(.bounce, value: showContent)
                        .transition(.scale.combined(with: .opacity))

                    // Count
                    Text(milestoneValue)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(milestoneColor)
                        .contentTransition(.numericText())
                        .transition(.scale.combined(with: .opacity))

                    // Message
                    Text(info.message)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    // Encouragement
                    Text("Keep it up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            HapticManager.play(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeIn.delay(0.3)) {
                showConfetti = true
            }
            autoAdvance()
        }
        .accessibilityLabel("Milestone: \(info.message)")
    }

    private var milestoneIcon: String {
        switch info.type {
        case .wordsLearned: return "textformat.abc"
        case .cardsCompleted: return "rectangle.stack.fill"
        case .minutesStudied: return "clock.fill"
        case .streakInSession: return "flame.fill"
        }
    }

    private var milestoneColor: Color {
        switch info.type {
        case .wordsLearned: return .blue
        case .cardsCompleted: return .purple
        case .minutesStudied: return .green
        case .streakInSession: return .orange
        }
    }

    private var milestoneValue: String {
        switch info.type {
        case .wordsLearned(let n): return "\(n)"
        case .cardsCompleted(let n): return "\(n)"
        case .minutesStudied(let n): return "\(n)m"
        case .streakInSession(let n): return "\(n)"
        }
    }

    private func autoAdvance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard !hasAutoCompleted else { return }
            hasAutoCompleted = true
            onComplete()
        }
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                animateParticles(in: geo.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        particles = (0..<30).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.0...2.0)
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 20
                particles[i].position.x += CGFloat.random(in: -60...60)
                particles[i].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Streak Card

struct StreakCardView: View {
    let days: Int
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var flameScale: CGFloat = 0.3
    @State private var hasAutoCompleted = false

    var body: some View {
        VStack(spacing: 20) {
            if showContent {
                // Animated flame
                Image(systemName: "flame.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flameScale)
                    .transition(.scale)

                // Streak count
                Text("\(days)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
                    .transition(.scale.combined(with: .opacity))

                Text(days == 1 ? "Day Streak" : "Day Streak!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .transition(.opacity)

                Text(streakMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .transition(.opacity)
            }
        }
        .onAppear {
            HapticManager.play(.medium)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.2)) {
                flameScale = 1.0
            }
            autoAdvance()
        }
        .accessibilityLabel("\(days) day streak. \(streakMessage)")
    }

    private var flameGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var streakMessage: String {
        switch days {
        case 1: return "You started a streak! Come back tomorrow to keep it going."
        case 2...4: return "Great start! Keep the momentum going."
        case 5...9: return "You're on fire! Consistency is key to fluency."
        case 10...29: return "Incredible dedication! Your Korean is improving fast."
        case 30...99: return "A whole month of learning! You're truly committed."
        default: return "Legendary streak! You're an inspiration."
        }
    }

    private func autoAdvance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard !hasAutoCompleted else { return }
            hasAutoCompleted = true
            onComplete()
        }
    }
}
