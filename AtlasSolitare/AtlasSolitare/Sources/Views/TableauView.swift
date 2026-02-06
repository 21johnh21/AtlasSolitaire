import SwiftUI

// MARK: - TableauView

/// Renders all 4 tableau piles side by side in a single row.
/// Each pile fans its cards vertically — face-down cards are closely spaced,
/// face-up cards are more spread out so their labels are readable.
struct TableauView: View {
    /// The current tableau state (array of piles, each pile bottom→top).
    let piles: [[TableauCard]]
    /// The currently selected card id (for highlight), nil if none.
    let selectedCardId: String?

    /// Called when a face-up top card is tapped.  Passes the card and its pile index.
    var onTapCard: ((Card, Int) -> Void)?
    /// Called when an empty pile is tapped (for tap-to-place).  Passes pile index.
    var onTapEmptyPile: ((Int) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: CardLayout.horizontalSpacing) {
            ForEach(0..<piles.count, id: \.self) { pileIndex in
                SingleTableauPile(
                    pile: piles[pileIndex],
                    pileIndex: pileIndex,
                    selectedCardId: selectedCardId,
                    onTapCard: onTapCard,
                    onTapEmptyPile: onTapEmptyPile
                )
            }
        }
    }
}

// MARK: - SingleTableauPile

/// Renders one tableau pile with proper card fanning offsets.
private struct SingleTableauPile: View {
    let pile: [TableauCard]
    let pileIndex: Int
    let selectedCardId: String?

    var onTapCard: ((Card, Int) -> Void)?
    var onTapEmptyPile: ((Int) -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            if pile.isEmpty {
                emptySlot
                    .onTapGesture { onTapEmptyPile?(pileIndex) }
            } else {
                ForEach(pile.indices, id: \.self) { i in
                    let tc = pile[i]
                    let yOffset = computeOffset(upTo: i)

                    CardView(
                        card: tc.card,
                        isFaceUp: tc.isFaceUp,
                        isHighlighted: tc.isFaceUp && selectedCardId == tc.card.id,
                        onTap: tc.isFaceUp && i == pile.count - 1
                            ? { onTapCard?(tc.card, pileIndex) }
                            : nil
                    )
                    .offset(y: yOffset)
                    // Face-down cards have lower z so face-up cards render on top.
                    .zIndex(Double(i))
                }
            }
        }
        // Height: tallest pile (all cards fanned out) + one card height.
        .frame(width: CardLayout.width, height: pileHeight)
        .accessibilityLabel("Tableau pile \(pileIndex + 1), \(pile.count) card\(pile.count == 1 ? "" : "s")")
    }

    // ─── Offset calculation ─────────────────────────────────────────────────

    /// Cumulative y-offset for card at position `index`.
    private func computeOffset(upTo index: Int) -> CGFloat {
        var offset: CGFloat = 0
        for i in 0..<index {
            offset += pile[i].isFaceUp ? CardLayout.faceUpOffset : CardLayout.faceDownOffset
        }
        return offset
    }

    /// Total height needed to display this pile without clipping.
    private var pileHeight: CGFloat {
        guard !pile.isEmpty else { return CardLayout.height }
        return computeOffset(upTo: pile.count - 1) + CardLayout.height
    }

    // ─── Empty pile placeholder ─────────────────────────────────────────────
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .cardFrame()
    }
}

// MARK: - Preview

#Preview {
    let samplePiles: [[TableauCard]] = [
        [TableauCard(card: Card(id: "c1", label: "France",  type: .partner, groupId: "eu", imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c2", label: "Italy",   type: .partner, groupId: "eu", imageName: nil), isFaceUp: true)],
        [TableauCard(card: Card(id: "c3", label: "Japan",   type: .partner, groupId: "is", imageName: nil), isFaceUp: true)],
        [],
        [TableauCard(card: Card(id: "c4", label: "US States", type: .base, groupId: "us", imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c5", label: "Texas",   type: .partner, groupId: "us", imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c6", label: "Florida", type: .partner, groupId: "us", imageName: nil), isFaceUp: true)]
    ]

    TableauView(piles: samplePiles, selectedCardId: "c2")
        .padding()
        .background(Color.feltGreen)
        .frame(maxHeight: .infinity, alignment: .top)
}
