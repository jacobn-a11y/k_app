import SwiftUI

struct FlashcardView: View {
    let frontContent: AnyView
    let backContent: AnyView
    let isFlipped: Bool
    var onTap: (() -> Void)?

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Back side
            cardSide(content: backContent, isBack: true)
                .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation < -90 || rotation > 90 ? 0 : 1)

            // Front side
            cardSide(content: frontContent, isBack: false)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                .opacity(rotation < -90 || rotation > 90 ? 0 : 1)
        }
        .onTapGesture {
            onTap?()
        }
        .accessibilityHint("Double tap to flip card")
        .accessibilityAddTraits(.isButton)
        .onChange(of: isFlipped) { _, flipped in
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = flipped ? 180 : 0
            }
        }
    }

    private func cardSide(content: AnyView, isBack: Bool) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Convenience Initializer

extension FlashcardView {
    init<Front: View, Back: View>(
        isFlipped: Bool,
        onTap: (() -> Void)? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.frontContent = AnyView(front())
        self.backContent = AnyView(back())
        self.isFlipped = isFlipped
        self.onTap = onTap
    }
}
