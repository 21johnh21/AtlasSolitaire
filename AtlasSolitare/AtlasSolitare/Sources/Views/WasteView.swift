import SwiftUI

// MARK: - WasteView

/// Renders the waste pile.  Only the top card is visible and interactive.
/// Supports both tap-to-select and drag gesture initiation.
/// Shows visual stacking effect for up to 5 cards below the top card.
struct WasteView: View {
    /// The top card of the waste pile, nil if empty.
    let topCard: Card?
    /// Number of cards in the waste pile.
    var wasteCount: Int = 0
    /// Set of card IDs currently being dragged.
    var draggingCardIds: Set<String> = []

    /// Called when drag starts - returns a DragPayload for the card.
    var onDragPayload: ((Card) -> DragPayload)?

    @Environment(\.cardWidth) private var cardWidth

    /// Offset for each stacked card (in points).
    private let stackOffset: CGFloat = 6

    var body: some View {
        let isDragging = topCard.map { draggingCardIds.contains($0.id) } ?? false
        // Show up to 5 cards stacked below the top card
        let stackCount = min(max(wasteCount - 1, 0), 5)

        return ZStack(alignment: .topLeading) {
            // Draw stacked cards from left to right, each offset progressively
            ForEach(0..<stackCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cardFrame(width: cardWidth)
                    .offset(x: CGFloat(index) * stackOffset, y: 0)
            }

            // Top card or empty slot
            if let card = topCard {
                if !isDragging {
                    CardView(
                        card: card,
                        isFaceUp: true,
                        isHighlighted: false
                    )
                    .offset(x: CGFloat(stackCount) * stackOffset, y: 0)
                    .draggable(onDragPayload?(card) ?? DragPayload(card: card, source: .waste)) {
                        CardView(
                            card: card,
                            isFaceUp: true,
                            isHighlighted: false
                        )
                        .environment(\.cardWidth, cardWidth)
                    }
                } else {
                    emptySlot
                        .offset(x: CGFloat(stackCount) * stackOffset, y: 0)
                }
            } else {
                emptySlot
            }
        }
        .accessibilityLabel(topCard.map { "Waste pile, top card: \($0.label), \(wasteCount) cards total" } ?? "Waste pile empty")
    }

    /// Dashed outline placeholder when the waste is empty.
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.subtle(), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            .cardFrame(width: cardWidth)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        WasteView(topCard: Card(id: "w1", label: "Italy", type: .partner, groupId: "europe_01", possibleGroupIds: ["europe_01"], imageName: nil))
        WasteView(topCard: Card(id: "w2", label: "Japan", type: .partner, groupId: "islands_01", possibleGroupIds: ["islands_01"], imageName: nil))
        WasteView(topCard: nil)
    }
    .padding()
    .background(Color.feltGreen)
}
