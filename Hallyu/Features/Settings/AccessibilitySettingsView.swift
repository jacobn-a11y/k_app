import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("highContrastMode") private var highContrastMode: Bool = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("autoplayAnimations") private var autoplayAnimations: Bool = true

    var body: some View {
        List {
            Section("Visual") {
                Toggle(isOn: $highContrastMode) {
                    Label("High Contrast Mode", systemImage: "circle.lefthalf.filled")
                }
                .accessibilityLabel("High Contrast Mode")
                .accessibilityHint("Increases contrast for better readability")

                Toggle(isOn: $autoplayAnimations) {
                    Label("Autoplay Animations", systemImage: "play.circle")
                }
                .accessibilityLabel("Autoplay Animations")
                .accessibilityHint("Automatically play stroke order animations")
            } footer: {
                Text("High contrast mode increases color contrast for text and UI elements. The system Reduce Motion setting is also respected for animations.")
            }

            Section("Feedback") {
                Toggle(isOn: $hapticFeedbackEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap")
                }
                .accessibilityLabel("Haptic Feedback")
                .accessibilityHint("Toggle vibration feedback for pronunciation exercises and reviews")
            } footer: {
                Text("Provides tactile feedback during pronunciation exercises and review sessions.")
            }

            Section("Media Playback") {
                NavigationLink {
                    PlaybackAccessibilityView()
                } label: {
                    Label("Playback Settings", systemImage: "play.rectangle")
                }
            } footer: {
                Text("Configure default playback speed and subtitle preferences.")
            }

            Section("System Accessibility") {
                HStack {
                    Label("VoiceOver", systemImage: "speaker.wave.3")
                    Spacer()
                    Text(UIAccessibility.isVoiceOverRunning ? "On" : "Off")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Label("Dynamic Type", systemImage: "textformat.size")
                    Spacer()
                    Text(currentDynamicTypeLabel)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open System Accessibility Settings", systemImage: "gear")
                }
            } footer: {
                Text("VoiceOver and Dynamic Type are controlled in System Settings.")
            }
        }
        .navigationTitle("Accessibility")
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var currentDynamicTypeLabel: String {
        switch dynamicTypeSize {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "XX Large"
        case .xxxLarge: return "XXX Large"
        case .accessibility1: return "Accessibility 1"
        case .accessibility2: return "Accessibility 2"
        case .accessibility3: return "Accessibility 3"
        case .accessibility4: return "Accessibility 4"
        case .accessibility5: return "Accessibility 5"
        @unknown default: return "Default"
        }
    }
}

// MARK: - Playback Accessibility

struct PlaybackAccessibilityView: View {
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @AppStorage("defaultSubtitleMode") private var defaultSubtitleMode: String = "korean"
    @AppStorage("showRomanization") private var showRomanization: Bool = true

    var body: some View {
        List {
            Section("Default Playback Speed") {
                Picker("Speed", selection: $defaultPlaybackSpeed) {
                    Text("0.5x (Slow)").tag(0.5)
                    Text("0.75x").tag(0.75)
                    Text("1.0x (Normal)").tag(1.0)
                    Text("1.25x").tag(1.25)
                    Text("1.5x").tag(1.5)
                    Text("2.0x (Fast)").tag(2.0)
                }
                .accessibilityLabel("Default playback speed")
            } footer: {
                Text("Slower speeds can help with listening comprehension. This can always be changed during playback.")
            }

            Section("Subtitles") {
                Picker("Default Subtitle Mode", selection: $defaultSubtitleMode) {
                    Text("No Subtitles").tag("none")
                    Text("Korean Only").tag("korean")
                    Text("Korean + English").tag("both")
                }
                .accessibilityLabel("Default subtitle mode")

                Toggle(isOn: $showRomanization) {
                    Label("Show Romanization", systemImage: "character.textbox")
                }
                .accessibilityHint("Show romanized pronunciation alongside Korean text")
            }
        }
        .navigationTitle("Playback Settings")
    }
}
