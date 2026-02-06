import SwiftUI

// MARK: - WasteView

/// Renders the waste pile.  Only the top card is visible and interactive.
/// Supports both tap-to-select and drag gesture initiation.
struct WasteView: View {
    /// The top card of the waste pile, nil if empty.
    let topCard: Card?
    /// Whether the top card is currently selected (tap-to-select flow).
    let isSelected: Bool

    /// Called when the user taps the top waste card.
    var onTap: (() -> Void)?
    /// Called when a drag gesture begins on the top card.
    var onDragStart: (() -> Void)?

    var body: some View {
        ZStack {
            if let card = topCard {
                CardView(
                    card: card,
                    isFaceUp: true,
                    isHighlighted: isSelected,
                    onTap: onTap,
                    onDragStart: onDragStart
                )
                // Draggable: the drag gesture is handled by the parent GameView
                // via .draggable() on this view.  We expose onDragStart for haptics.
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
            .cardFrame()
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
