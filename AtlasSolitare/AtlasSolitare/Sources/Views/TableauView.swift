import SwiftUI
import UniformTypeIdentifiers

// MARK: - TableauView

/// Renders all 4 tableau piles side by side in a single row.
/// Each pile fans its cards vertically — face-down cards are closely spaced,
/// face-up cards are more spread out so their labels are readable.
struct TableauView: View {
    /// The current tableau state (array of piles, each pile bottom→top).
    let piles: [[TableauCard]]
    /// Set of card IDs currently being dragged.
    var draggingCardIds: Set<String> = []

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
                    draggingCardIds: draggingCardIds,
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
    var draggingCardIds: Set<String> = []

    var onDragPayload: ((Card, Int, Int) -> DragPayload)?
    var onDropPayload: ((DragPayload, Int) -> Bool)?

    @Environment(\.cardWidth) private var cardWidth

    var body: some View {
        let visibleCards = pile.filter { !draggingCardIds.contains($0.card.id) }
        let showEmptySlot = pile.isEmpty || visibleCards.isEmpty

        ZStack(alignment: .top) {
            if showEmptySlot {
                emptySlot
            } else {
                ForEach(pile.indices, id: \.self) { i in
                    let tc = pile[i]
                    let yOffset = computeOffset(upTo: i)
                    let isTopCard = (i == pile.count - 1)
                    let isDraggable = tc.isFaceUp && canDragFromIndex(i)
                    let isBeingDragged = draggingCardIds.contains(tc.card.id)

                    if !isBeingDragged {
                        CardView(
                            card: tc.card,
                            isFaceUp: tc.isFaceUp,
                            isHighlighted: false,
                            onTap: nil
                        )
                        .equatable()
                        .offset(y: yOffset)
                        // Face-down cards have lower z so face-up cards render on top.
                        .zIndex(Double(i))
                        .if(isDraggable) { view in
                            view.draggable(onDragPayload?(tc.card, pileIndex, i) ?? DragPayload(card: tc.card, source: .tableau(pileIndex: pileIndex))) {
                                // Create a visual preview showing the stack of cards being dragged
                                dragPreviewForStack(startingAt: i)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: cardWidth)
        .contentShape(Rectangle()) // Make the entire pile area accept drops
        .dropDestination(for: DragPayload.self) { items, location in
            guard let payload = items.first else { return false }
            return onDropPayload?(payload, pileIndex) ?? false
        }
        .accessibilityLabel("Tableau pile \(pileIndex + 1), \(pile.count) card\(pile.count == 1 ? "" : "s")")
    }

    // ─── Drag helpers ───────────────────────────────────────────────────────

    /// Determines if a card at the given index can be dragged.
    /// A card is draggable if it's face-up and forms a valid stack with subsequent cards.
    private func canDragFromIndex(_ index: Int) -> Bool {
        guard index >= 0, index < pile.count else { return false }
        guard pile[index].isFaceUp else { return false }

        // Get the valid stack starting from this index
        let stackIndices = Rules.getMovableStack(from: pile, startIndex: index)

        // Can drag if this is part of a valid stack that extends to the top of the pile
        return !stackIndices.isEmpty && stackIndices.contains(pile.count - 1)
    }

    /// Creates a visual preview of the card stack being dragged
    @ViewBuilder
    private func dragPreviewForStack(startingAt index: Int) -> some View {
        let stackIndices = Rules.getMovableStack(from: pile, startIndex: index)
        let cardHeight = CardLayout.height(for: cardWidth)

        ZStack(alignment: .top) {
            ForEach(Array(stackIndices.enumerated()), id: \.element) { offset, cardIndex in
                let tc = pile[cardIndex]
                CardView(
                    card: tc.card,
                    isFaceUp: true,
                    isHighlighted: false,
                    onTap: nil
                )
                .environment(\.cardWidth, cardWidth)
                .offset(y: CGFloat(offset) * CardLayout.faceUpOffset)
                .zIndex(Double(offset))
            }
        }
        .frame(width: cardWidth, height: cardHeight + CGFloat(stackIndices.count - 1) * CardLayout.faceUpOffset)
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
        let cardHeight = CardLayout.height(for: cardWidth)
        guard !pile.isEmpty else { return cardHeight }
        return computeOffset(upTo: pile.count - 1) + cardHeight
    }

    // ─── Empty pile placeholder ─────────────────────────────────────────────
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.verySubtle(), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .cardFrame(width: cardWidth)
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

    TableauView(piles: samplePiles)
        .padding()
        .background(Color.feltGreen)
        .frame(maxHeight: .infinity, alignment: .top)
}
