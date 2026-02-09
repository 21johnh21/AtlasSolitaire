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
                    .overlay(
                        // Globe design overlay
                        ZStack {
                            // Outer border
                            RoundedRectangle(cornerRadius: CardLayout.cornerRadius - 3)
                                .stroke(Color.accentGold.verySubtle(), lineWidth: 1.5)
                                .padding(4)

                            // Globe with latitude/longitude lines
                            globeDesign
                                .padding(12)

                            // Atlas "A" monogram centered
                            Text("A")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color.accentGold.subtle())
                                .shadow(color: Color.accentGold.verySubtle(), radius: 4, x: 0, y: 2)
                        }
                    )
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

    /// Globe design with latitude/longitude grid lines
    @ViewBuilder
    private var globeDesign: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.45

            ZStack {
                // Circle outline (globe)
                Circle()
                    .stroke(Color.accentGold.verySubtle(), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // Vertical meridian lines (longitude)
                ForEach(0..<6, id: \.self) { i in
                    Ellipse()
                        .stroke(Color.accentGold.verySubtle(), lineWidth: 0.8)
                        .frame(width: radius * 2 * CGFloat(i + 1) / 6, height: radius * 2)
                        .position(center)
                }

                // Horizontal parallel lines (latitude)
                ForEach(0..<3, id: \.self) { i in
                    let offsetY = radius * CGFloat(i + 1) / 3

                    // Above equator
                    Ellipse()
                        .stroke(Color.accentGold.verySubtle(), lineWidth: 0.8)
                        .frame(width: radius * 2, height: radius * 0.4)
                        .position(x: center.x, y: center.y - offsetY)

                    // Below equator
                    Ellipse()
                        .stroke(Color.accentGold.verySubtle(), lineWidth: 0.8)
                        .frame(width: radius * 2, height: radius * 0.4)
                        .position(x: center.x, y: center.y + offsetY)
                }

                // Equator (stronger line)
                Rectangle()
                    .fill(Color.accentGold.verySubtle())
                    .frame(width: radius * 2, height: 1)
                    .position(center)
            }
        }
    }

    /// Circular arrow icon shown when stock is empty but reshuffle is available.
    private var reshuffleIcon: some View {
        let iconSize = cardWidth / 85 * 32  // Scale icon with card width

        return RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.accentGold.standard(), Color.accentGold.medium()],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(Color.white.veryStrong())
                    .shadow(color: Color.black.subtle(), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .stroke(Color.accentGold.medium(), lineWidth: 2)
            )
            .shadow(color: Color.accentGold.subtle(), radius: 6, x: 0, y: 2)
    }

    /// Dashed outline when stock is empty and no reshuffle is possible.
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.subtle(), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
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
