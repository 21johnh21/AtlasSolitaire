import SwiftUI

// MARK: - WasteView

/// Renders the waste pile.  Only the top card is visible and interactive.
/// Supports both tap-to-select and drag gesture initiation.
struct WasteView: View {
    /// The top card of the waste pile, nil if empty.
    let topCard: Card?
    /// Whether the top card is currently selected (tap-to-select flow).
    let isSelected: Bool
    /// Set of card IDs currently being dragged.
    var draggingCardIds: Set<String> = []

    /// Called when the user taps the top waste card.
    var onTap: (() -> Void)?
    /// Called when drag starts - returns a DragPayload for the card.
    var onDragPayload: ((Card) -> DragPayload)?

    @Environment(\.cardWidth) private var cardWidth

    var body: some View {
        let isDragging = topCard.map { draggingCardIds.contains($0.id) } ?? false

        return ZStack {
            if let card = topCard {
                if !isDragging {
                    CardView(
                        card: card,
                        isFaceUp: true,
                        isHighlighted: isSelected,
                        onTap: onTap
                    )
                    .draggable(onDragPayload?(card) ?? DragPayload(card: card, source: .waste)) {
                        CardView(
                            card: card,
                            isFaceUp: true,
                            isHighlighted: false,
                            onTap: nil
                        )
                        .environment(\.cardWidth, cardWidth)
                    }
                } else {
                    emptySlot
                }
            } else {
                emptySlot
            }
        }
        .accessibilityLabel(topCard.map { "Waste pile, top card: \($0.label)" } ?? "Waste pile empty")
    }

    /// Dashed outline placeholder when the waste is empty.
    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .cardFrame(width: cardWidth)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        WasteView(topCard: Card(id: "w1", label: "Italy", type: .partner, groupId: "europe_01", imageName: nil), isSelected: false)
        WasteView(topCard: Card(id: "w2", label: "Japan", type: .partner, groupId: "islands_01", imageName: nil), isSelected: true)
        WasteView(topCard: nil, isSelected: false)
    }
    .padding()
    .background(Color.feltGreen)
}
