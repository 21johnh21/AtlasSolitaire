import SwiftUI

// MARK: - ButtonClickModifier

/// A view modifier that plays a click sound when a button is tapped.
/// Usage: Button("Text") { action }.withClickSound()
struct ButtonClickModifier: ViewModifier {
    let audio = AudioManager.shared

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    audio.play(.buttonClick)
                }
            )
    }
}

// MARK: - View Extension

extension View {
    /// Adds a click sound effect to any button or tappable view.
    /// The sound plays immediately when the tap begins for better feedback.
    func withClickSound() -> some View {
        modifier(ButtonClickModifier())
    }
}
