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

        GeometryReader { geo in
            let availableHeight = geo.size.height
            let scale = compressionScale(availableHeight: availableHeight)

            ZStack(alignment: .top) {
                if showEmptySlot {
                    emptySlot
                } else {
                    ForEach(pile.indices, id: \.self) { i in
                        let tc = pile[i]
                        let yOffset = computeOffset(upTo: i, scale: scale)
                        let isDraggable = tc.isFaceUp && canDragFromIndex(i)
                        let isBeingDragged = draggingCardIds.contains(tc.card.id)

                        if !isBeingDragged {
                            CardView(
                                card: tc.card,
                                isFaceUp: tc.isFaceUp,
                                isHighlighted: false
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
            .frame(width: cardWidth, alignment: .top)
            // Extend the drop target to cover the full rendered pile height so
            // cards can be dropped anywhere on the pile, not just the top card.
            .contentShape(Rectangle().size(CGSize(
                width: cardWidth,
                height: max(naturalPileHeight(scale: scale), CardLayout.height(for: cardWidth))
            )))
            .dropDestination(for: DragPayload.self) { items, location in
                guard let payload = items.first else { return false }
                return onDropPayload?(payload, pileIndex) ?? false
            }
            .accessibilityLabel("Tableau pile \(pileIndex + 1), \(pile.count) card\(pile.count == 1 ? "" : "s")")
        }
        .frame(width: cardWidth)
    }

    // ─── Drag helpers ───────────────────────────────────────────────────────

    /// Determines if a card at the given index can be dragged.
    /// A card is only draggable if it is the bottommost card of a valid movable stack.
    /// This prevents grabbing the middle of a stack and splitting it apart.
    private func canDragFromIndex(_ index: Int) -> Bool {
        guard index >= 0, index < pile.count else { return false }
        guard pile[index].isFaceUp else { return false }

        // Find the bottommost card of the valid stack that reaches the top of the pile.
        // Walk upward from this card's position to find where the contiguous group starts.
        let stackIndices = Rules.getMovableStack(from: pile, startIndex: index)

        // This card must extend a stack all the way to the top of the pile.
        guard !stackIndices.isEmpty && stackIndices.contains(pile.count - 1) else {
            return false
        }

        // Only the bottommost card of the stack may be the drag handle.
        // If there's a card above this one that is also part of the same stack,
        // this card is in the middle and should not be individually draggable.
        if index > 0 {
            let cardAboveIndices = Rules.getMovableStack(from: pile, startIndex: index - 1)
            if cardAboveIndices.contains(pile.count - 1) {
                // The card above is also the start of a stack reaching the top,
                // meaning this card is not the bottommost — disallow drag.
                return false
            }
        }

        return true
    }

    /// Creates a visual preview of the card stack being dragged
    @ViewBuilder
    private func dragPreviewForStack(startingAt index: Int) -> some View {
        let stackIndices = Rules.getMovableStack(from: pile, startIndex: index)
        let cardHeight = CardLayout.height(for: cardWidth)
        let stackHeight = cardHeight + CGFloat(stackIndices.count - 1) * CardLayout.faceUpOffset

        // SwiftUI centers the drag preview under the finger. Since the grabbed card
        // sits at the top of the preview frame (y=0), we offset the entire preview
        // upward so the grabbed card aligns with the touch point instead of the
        // frame center. The correction is: move up by (stackHeight/2 - cardHeight/2).
        let verticalCorrection = (stackHeight / 2) - (cardHeight / 2)

        ZStack(alignment: .top) {
            ForEach(Array(stackIndices.enumerated()), id: \.element) { offset, cardIndex in
                let tc = pile[cardIndex]
                CardView(
                    card: tc.card,
                    isFaceUp: true,
                    isHighlighted: false
                )
                .environment(\.cardWidth, cardWidth)
                .offset(y: CGFloat(offset) * CardLayout.faceUpOffset)
                .zIndex(Double(offset))
            }
        }
        .frame(width: cardWidth, height: stackHeight)
        .offset(y: -verticalCorrection)
    }

    // ─── Offset calculation ─────────────────────────────────────────────────

    /// Cumulative y-offset for card at position `index`, scaled for compression.
    private func computeOffset(upTo index: Int, scale: CGFloat = 1.0) -> CGFloat {
        var offset: CGFloat = 0
        for i in 0..<index {
            offset += (pile[i].isFaceUp ? CardLayout.faceUpOffset : CardLayout.faceDownOffset) * scale
        }
        return offset
    }

    /// Total height needed to display this pile at natural (uncompressed) size.
    private var naturalPileHeight: CGFloat {
        let cardHeight = CardLayout.height(for: cardWidth)
        guard !pile.isEmpty else { return cardHeight }
        return computeOffset(upTo: pile.count - 1) + cardHeight
    }

    /// Total rendered height of the pile at the given compression scale.
    private func naturalPileHeight(scale: CGFloat) -> CGFloat {
        let cardHeight = CardLayout.height(for: cardWidth)
        guard !pile.isEmpty else { return cardHeight }
        return computeOffset(upTo: pile.count - 1, scale: scale) + cardHeight
    }

    /// Returns a scale factor (0...1) to compress card offsets so the pile fits
    /// within `availableHeight`. Cards are never scaled below a minimum offset
    /// to keep them distinguishable.
    private func compressionScale(availableHeight: CGFloat) -> CGFloat {
        let cardHeight = CardLayout.height(for: cardWidth)
        guard availableHeight > cardHeight, naturalPileHeight > availableHeight else {
            return 1.0  // No compression needed
        }

        // The offsets between cards (excluding the final card's height) must fit
        let totalOffsetSpace = availableHeight - cardHeight
        let naturalOffsetSpace = naturalPileHeight - cardHeight

        let scale = totalOffsetSpace / naturalOffsetSpace

        // Don't compress below a minimum so cards remain visually distinct
        let minFaceDownOffset: CGFloat = 6
        let minFaceUpOffset: CGFloat = 10
        let minScaleFaceDown = minFaceDownOffset / CardLayout.faceDownOffset
        let minScaleFaceUp   = minFaceUpOffset   / CardLayout.faceUpOffset
        let minScale = min(minScaleFaceDown, minScaleFaceUp)

        return max(scale, minScale)
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
        [TableauCard(card: Card(id: "c1", label: "France",  type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c2", label: "Italy",   type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: true)],
        [TableauCard(card: Card(id: "c3", label: "Japan",   type: .partner, groupId: "is", possibleGroupIds: ["is"], imageName: nil), isFaceUp: true)],
        [],
        [TableauCard(card: Card(id: "c4", label: "US States", type: .base, groupId: "us", possibleGroupIds: ["us"], imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c5", label: "Texas",   type: .partner, groupId: "us", possibleGroupIds: ["us"], imageName: nil), isFaceUp: false),
         TableauCard(card: Card(id: "c6", label: "Florida", type: .partner, groupId: "us", possibleGroupIds: ["us"], imageName: nil), isFaceUp: true)]
    ]

    TableauView(piles: samplePiles)
        .padding()
        .background(Color.feltGreen)
        .frame(maxHeight: .infinity, alignment: .top)
}
