import SwiftUI
import UniformTypeIdentifiers

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
    /// Called when drag starts from a tableau card. Returns a DragPayload for the card and any cards stacked on top.
    var onDragPayload: ((Card, Int, Int) -> DragPayload)?
    /// Called when a payload is dropped on a tableau pile. Returns success status.
    var onDropPayload: ((DragPayload, Int) -> Bool)?

    var body: some View {
        HStack(alignment: .top, spacing: CardLayout.horizontalSpacing) {
            ForEach(0..<piles.count, id: \.self) { pileIndex in
                SingleTableauPile(
                    pile: piles[pileIndex],
                    pileIndex: pileIndex,
                    selectedCardId: selectedCardId,
                    onTapCard: onTapCard,
                    onTapEmptyPile: onTapEmptyPile,
                    onDragPayload: onDragPayload,
                    onDropPayload: onDropPayload
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
    var onDragPayload: ((Card, Int, Int) -> DragPayload)?
    var onDropPayload: ((DragPayload, Int) -> Bool)?

    var body: some View {
        ZStack(alignment: .top) {
            if pile.isEmpty {
                emptySlot
                    .onTapGesture { onTapEmptyPile?(pileIndex) }
            } else {
                ForEach(pile.indices, id: \.self) { i in
                    let tc = pile[i]
                    let yOffset = computeOffset(upTo: i)
                    let isTopCard = (i == pile.count - 1)
                    let isDraggable = tc.isFaceUp && canDragFromIndex(i)

                    CardView(
                        card: tc.card,
                        isFaceUp: tc.isFaceUp,
                        isHighlighted: tc.isFaceUp && selectedCardId == tc.card.id,
                        onTap: tc.isFaceUp && isTopCard
                            ? { onTapCard?(tc.card, pileIndex) }
                            : nil
                    )
                    .offset(y: yOffset)
                    // Face-down cards have lower z so face-up cards render on top.
                    .zIndex(Double(i))
                    .if(isDraggable) { view in
                        view.draggable(onDragPayload?(tc.card, pileIndex, i) ?? DragPayload(card: tc.card, source: .tableau(pileIndex: pileIndex)))
                    }
                }
            }
        }
        // Height: tallest pile (all cards fanned out) + one card height.
        .frame(width: CardLayout.width, height: pileHeight)
        .contentShape(Rectangle()) // Make the entire pile area accept drops
        .dropDestination(for: DragPayload.self) { items, location in
            print("[TableauView] 🎯 Drop detected on pile \(pileIndex), items count: \(items.count)")
            guard let payload = items.first else {
                print("[TableauView] ❌ No payload in items")
                return false
            }
            print("[TableauView] ✅ Calling onDropPayload for pile \(pileIndex)")
            let result = onDropPayload?(payload, pileIndex) ?? false
            print("[TableauView] Drop result: \(result)")
            return result
        }
        .accessibilityLabel("Tableau pile \(pileIndex + 1), \(pile.count) card\(pile.count == 1 ? "" : "s")")
    }

    // ─── Drag helpers ───────────────────────────────────────────────────────

    /// Determines if a card at the given index can be dragged.
    /// A card is draggable if it's face-up and forms a valid stack with subsequent cards.
    private func canDragFromIndex(_ index: Int) -> Bool {
        print("[TableauView] canDragFromIndex called: index=\(index), pile.count=\(pile.count)")

        guard index >= 0, index < pile.count else {
            print("[TableauView] ❌ Invalid index")
            return false
        }
        guard pile[index].isFaceUp else {
            print("[TableauView] ❌ Card is face down")
            return false
        }

        // Get the valid stack starting from this index
        let stackIndices = Rules.getMovableStack(from: pile, startIndex: index)

        // Can drag if this is part of a valid stack that extends to the top of the pile
        let canDrag = !stackIndices.isEmpty && stackIndices.contains(pile.count - 1)
        print("[TableauView] canDrag=\(canDrag) (stackIndices=\(stackIndices), needsToContain=\(pile.count - 1))")
        return canDrag
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

// MARK: - View Extension for Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
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
