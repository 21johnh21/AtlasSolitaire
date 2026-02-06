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
        .cardFrame()
        .onTapGesture { onTap?() }
        .accessibilityLabel(cardCount > 0 ? "\(cardCount) cards in stock" : (canReshuffle ? "Tap to reshuffle" : "Stock empty"))
    }

    // ─── Stacked face-down cards (show up to 3 layers for depth) ────────────
    private var stockStack: some View {
        ZStack(alignment: .bottom) {
            // Bottom layers (offset slightly for visual depth).
            ForEach(0..<min(cardCount, 3), id: \.self) { i in
                let offset = CGFloat(min(cardCount, 3) - 1 - i) * 1.5
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .fill(Color.cardBack)
                    .cardFrame()
                    .cardShadow()
                    .offset(y: -offset)
            }
        }
    }

    /// Circular arrow icon shown when stock is empty but reshuffle is available.
    private var reshuffleIcon: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(Color.cardBack.opacity(0.5))
            .overlay(
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 28))
                    .foregroundColor(Color.white.opacity(0.7))
            )
            .cardShadow()
    }

    /// Dashed outline when stock is empty and no reshuffle is possible.
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
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
