import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Color palette (game theme)

#if canImport(SwiftUI)

// MARK: - Environment key for card width

/// Environment key to pass calculated card width through the view hierarchy
struct CardWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = CardLayout.width
}

extension EnvironmentValues {
    var cardWidth: CGFloat {
        get { self[CardWidthKey.self] }
        set { self[CardWidthKey.self] = newValue }
    }
}

extension Color {
    /// Rich green table felt — primary game background.
    static let feltGreen    = Color(red: 0.12, green: 0.35, blue: 0.18)
    /// Slightly lighter green for hover / highlight states.
    static let feltHighlight = Color(red: 0.18, green: 0.45, blue: 0.25)
    /// Card face background.
    static let cardWhite    = Color(red: 0.97, green: 0.96, blue: 0.94)
    /// Card back pattern color.
    static let cardBack     = Color(red: 0.15, green: 0.25, blue: 0.40)
    /// Accent used for base-card headers.
    static let accentGold   = Color(red: 0.85, green: 0.72, blue: 0.35)
    /// Text on dark surfaces.
    static let textLight    = Color.white
    /// Text on light surfaces.
    static let textDark     = Color(red: 0.13, green: 0.13, blue: 0.13)
}

// MARK: - Standardized Opacity Scale

extension Color {
    /// Standardized opacity scale for consistent visual hierarchy
    /// Use these instead of arbitrary opacity values throughout the app

    // Very subtle (borders, hints, backgrounds)
    func verySubtle() -> Color { self.opacity(0.15) }

    // Subtle (secondary borders, empty states, disabled elements)
    func subtle() -> Color { self.opacity(0.25) }

    // Medium (overlays, shadows, secondary text)
    func medium() -> Color { self.opacity(0.4) }

    // Standard (primary overlays, secondary content)
    func standard() -> Color { self.opacity(0.6) }

    // Strong (primary text on backgrounds, important content)
    func strong() -> Color { self.opacity(0.8) }

    // VeryStrong (primary interactive elements, key text)
    func veryStrong() -> Color { self.opacity(0.9) }
}

// MARK: - View modifiers

extension View {
    /// Standard card-size frame for portrait layout.
    /// Optionally pass custom card width (useful for responsive layouts).
    func cardFrame(width: CGFloat? = nil) -> some View {
        let cardWidth = width ?? CardLayout.width
        let cardHeight = width.map { CardLayout.height(for: $0) } ?? CardLayout.height
        return self.frame(width: cardWidth, height: cardHeight)
    }

    /// Subtle shadow matching the felt surface.
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.25), radius: 4, x: 1, y: 2)
    }
}

// MARK: - CardLayout constants

/// Centralised card-dimension constants so every view stays consistent.
/// Card dimensions are calculated dynamically based on screen width.
enum CardLayout {
    /// Calculate card width based on available screen width
    /// Uses 4 cards + 3 spacings as the basis (for foundations/tableau rows)
    static func width(for screenWidth: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 32  // Total padding (16 per side)
        let availableWidth = screenWidth - horizontalPadding
        let totalSpacing: CGFloat = 3 * 8  // 3 gaps between 4 cards
        let cardWidth = (availableWidth - totalSpacing) / 4
        // Clamp between reasonable min/max values
        return min(max(cardWidth, 60), 85)
    }

    /// Calculate card height based on card width (maintaining aspect ratio)
    static func height(for cardWidth: CGFloat) -> CGFloat {
        return cardWidth * 1.41  // Standard card aspect ratio ~1.4:1
    }

    static let cornerRadius: CGFloat = 8
    /// Vertical offset between stacked face-down cards in a tableau pile.
    static let faceDownOffset: CGFloat = 18
    /// Vertical offset between stacked face-up cards in a tableau pile.
    static let faceUpOffset: CGFloat = 28
    /// Horizontal spacing between piles.
    static let horizontalSpacing: CGFloat = 8

    // Legacy constants for views that don't have access to screen width yet
    static let width:  CGFloat = 85
    static let height: CGFloat = 120
}

// MARK: - FeltBackground

/// A layered felt surface: a woven crosshatch texture beneath a radial vignette.
/// Matches the game's `feltGreen` palette and renders entirely in SwiftUI (no assets needed).
struct FeltBackground: View {
    var body: some View {
        ZStack {
            // Base fill
            Color.feltGreen

            // Woven crosshatch layer
            Canvas { context, size in
                let base   = Color(red: 0.12, green: 0.35, blue: 0.18)
                let light  = Color(red: 0.15, green: 0.40, blue: 0.22)
                let dark   = Color(red: 0.09, green: 0.28, blue: 0.14)

                let spacing: CGFloat = 6
                let lineWidth: CGFloat = 0.8

                // Diagonal lines going ↘ (top-left to bottom-right)
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    context.stroke(path, with: .color(light.opacity(0.18)), lineWidth: lineWidth)
                    x += spacing
                }

                // Diagonal lines going ↙ (top-right to bottom-left)
                var x2: CGFloat = -size.height
                while x2 < size.width + size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: x2 + size.height, y: 0))
                    path.addLine(to: CGPoint(x: x2, y: size.height))
                    context.stroke(path, with: .color(dark.opacity(0.15)), lineWidth: lineWidth)
                    x2 += spacing
                }

                // Suppress unused warning
                _ = base
            }
            .blendMode(.overlay)

            // Radial vignette: dark edges, lighter center
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.28)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 520
            )
            .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Array safe subscript

extension Array {
    /// Returns the element at `index`, or `nil` if out of bounds.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Optional String

extension Optional where Wrapped == String {
    /// Returns the string if non-nil and non-empty, otherwise a fallback.
    func orElse(_ fallback: String) -> String {
        switch self {
        case .some(let s) where !s.isEmpty: return s
        default: return fallback
        }
    }
}

#endif // canImport(SwiftUI)
