import SwiftUI

// MARK: - StockView

/// Renders the stock pile (face-down stack) and the reshuffle affordance.
/// Tapping the pile draws a card; when empty and waste is non-empty it
/// shows a reshuffle indicator.
struct StockView: View {
    /// Number of cards remaining in the stock.
    let cardCount: Int
    /// Whether the waste pile has cards (determines reshuffle affordance).
    let canReshuffle: Bool

    /// Called when the user taps the stock pile area.
    var onTap: (() -> Void)?

    @Environment(\.cardWidth) private var cardWidth

    var body: some View {
        ZStack {
            if cardCount > 0 {
                stockStack
            } else if canReshuffle {
                reshuffleIcon
            } else {
                emptySlot
            }
        }
        .cardFrame(width: cardWidth)
        .onTapGesture { onTap?() }
        .accessibilityLabel(cardCount > 0 ? "\(cardCount) cards in stock" : (canReshuffle ? "Tap to reshuffle" : "Stock empty"))
    }

    // ─── Stacked face-down cards (show up to 3 layers for depth) ────────────
    private var stockStack: some View {
        ZStack(alignment: .bottom) {
            // Bottom layers (offset for visual depth).
            ForEach(0..<min(cardCount, 3), id: \.self) { i in
                let offset = CGFloat(min(cardCount, 3) - 1 - i) * 2.5
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .fill(Color.cardBack)
                    .cardFrame(width: cardWidth)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 4 + CGFloat(i),
                        x: 1,
                        y: 2 + CGFloat(i) * 0.5
                    )
                    .offset(y: -offset)
            }
        }
    }

    /// Circular arrow icon shown when stock is empty but reshuffle is available.
    private var reshuffleIcon: some View {
        let iconSize = cardWidth / 85 * 32  // Scale icon with card width

        return RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.accentGold.opacity(0.6), Color.accentGold.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .stroke(Color.accentGold.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color.accentGold.opacity(0.3), radius: 6, x: 0, y: 2)
    }

    /// Dashed outline when stock is empty and no reshuffle is possible.
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        StockView(cardCount: 8,  canReshuffle: false)
        StockView(cardCount: 0,  canReshuffle: true)
        StockView(cardCount: 0,  canReshuffle: false)
    }
    .padding()
    .background(Color.feltGreen)
}
