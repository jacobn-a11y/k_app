import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility View Modifiers

struct AccessibleLabel: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits

    init(_ label: String, hint: String? = nil, traits: AccessibilityTraits = []) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func accessibleLabel(_ label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        modifier(AccessibleLabel(label, hint: hint, traits: traits))
    }

    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        modifier(AccessibleLabel(label, hint: hint, traits: .isButton))
    }

    func accessibleHeader(_ label: String) -> some View {
        modifier(AccessibleLabel(label, traits: .isHeader))
    }

    func accessibleImage(_ description: String) -> some View {
        modifier(AccessibleLabel(description, traits: .isImage))
    }
}

// MARK: - Dynamic Type Scaling

struct ScaledFont: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }

    private var scaledSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall: return baseSize * 0.8
        case .small: return baseSize * 0.9
        case .medium: return baseSize
        case .large: return baseSize * 1.0
        case .xLarge: return baseSize * 1.1
        case .xxLarge: return baseSize * 1.2
        case .xxxLarge: return baseSize * 1.3
        case .accessibility1: return baseSize * 1.5
        case .accessibility2: return baseSize * 1.7
        case .accessibility3: return baseSize * 1.9
        case .accessibility4: return baseSize * 2.1
        case .accessibility5: return baseSize * 2.3
        @unknown default: return baseSize
        }
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(baseSize: size, weight: weight, design: design))
    }
}

// MARK: - High Contrast Support

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast

    let normalColor: Color
    let highContrastColor: Color

    func body(content: Content) -> some View {
        content.foregroundStyle(contrast == .increased ? highContrastColor : normalColor)
    }
}

extension View {
    func adaptiveColor(normal: Color, highContrast: Color) -> some View {
        modifier(HighContrastModifier(normalColor: normal, highContrastColor: highContrast))
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation?

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: UUID())
    }
}

extension View {
    func motionSensitiveAnimation(_ animation: Animation? = .default) -> some View {
        modifier(ReducedMotionModifier(animation: animation))
    }
}

// MARK: - Haptic Feedback

enum HapticType {
    case success
    case error
    case warning
    case light
    case medium
    case heavy
    case selection
}

struct HapticManager {
    static func play(_ type: HapticType) {
        #if canImport(UIKit)
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        #endif
    }

    static func prepareHaptic(_ type: HapticType) {
        #if canImport(UIKit)
        switch type {
        case .success, .error, .warning:
            UINotificationFeedbackGenerator().prepare()
        case .light:
            UIImpactFeedbackGenerator(style: .light).prepare()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).prepare()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).prepare()
        case .selection:
            UISelectionFeedbackGenerator().prepare()
        }
        #endif
    }
}

// MARK: - Accessibility Announcement

extension View {
    func announceOnAppear(_ message: String) -> some View {
        #if canImport(UIKit)
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .screenChanged, argument: message)
            }
        }
        #else
        self
        #endif
    }
}

// MARK: - Korean Character Accessibility

struct KoreanAccessibility {
    static func jamoDescription(_ jamo: Character) -> String {
        let descriptions: [Character: String] = [
            "ㄱ": "기역 (giyeok), sounds like g or k",
            "ㄴ": "니은 (nieun), sounds like n",
            "ㄷ": "디귿 (digeut), sounds like d or t",
            "ㄹ": "리을 (rieul), sounds like r or l",
            "ㅁ": "미음 (mieum), sounds like m",
            "ㅂ": "비읍 (bieup), sounds like b or p",
            "ㅅ": "시옷 (siot), sounds like s",
            "ㅇ": "이응 (ieung), silent or ng",
            "ㅈ": "지읒 (jieut), sounds like j",
            "ㅊ": "치읓 (chieut), sounds like ch",
            "ㅋ": "키읔 (kieuk), sounds like k",
            "ㅌ": "티읕 (tieut), sounds like t",
            "ㅍ": "피읖 (pieup), sounds like p",
            "ㅎ": "히읗 (hieut), sounds like h",
            "ㅏ": "아 (a), sounds like ah",
            "ㅓ": "어 (eo), sounds like uh",
            "ㅗ": "오 (o), sounds like oh",
            "ㅜ": "우 (u), sounds like oo",
            "ㅡ": "으 (eu), sounds like uh (unrounded)",
            "ㅣ": "이 (i), sounds like ee",
            "ㅐ": "애 (ae), sounds like eh",
            "ㅔ": "에 (e), sounds like ay",
            "ㅑ": "야 (ya), sounds like yah",
            "ㅕ": "여 (yeo), sounds like yuh",
        ]
        return descriptions[jamo] ?? "Korean character \(jamo)"
    }

    static func syllableDescription(_ syllable: String) -> String {
        guard let scalar = syllable.unicodeScalars.first,
              HangulUtilities.isHangulSyllable(scalar) else {
            return syllable
        }

        if let decomposed = HangulUtilities.decomposeSyllable(scalar) {
            var parts = "Composed of \(decomposed.initial) and \(decomposed.medial)"
            if let final_ = decomposed.final {
                parts += " with final \(final_)"
            }
            return "\(syllable): \(parts)"
        }
        return syllable
    }
}
