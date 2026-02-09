import SwiftUI

// MARK: - FoundationView

/// Renders a single foundation pile slot.
/// Shows the top card if occupied, or an empty-slot placeholder.
/// Accepts drag-and-drop and tap-to-place interactions.
struct FoundationView: View {
    /// The foundation pile data.
    let pile: FoundationPile
    /// Index of this foundation slot (0–3).
    let pileIndex: Int
    /// Set of card IDs currently being dragged.
    var draggingCardIds: Set<String> = []
    /// Called when drag starts.
    var onDragStart: ((Card) -> Void)?

    /// Called when a payload is dropped onto this foundation (drag-and-drop).
    var onDropPayload: ((DragPayload) -> Bool)?

    @Environment(\.cardWidth) private var cardWidth

    var body: some View {
        let isDragging = pile.topCard.map { draggingCardIds.contains($0.id) } ?? false

        VStack(spacing: 4) {
            // Category banner (shown when foundation has a base card)
            if !pile.isEmpty, let groupName = groupName {
                categoryBanner(groupName)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: groupName)
            } else {
                // Spacer to keep alignment consistent
                Color.clear
                    .frame(width: cardWidth, height: 20)
            }

            // Card or empty slot
            ZStack {
                if let top = pile.topCard, !isDragging {
                    CardView(
                        card: top,
                        isFaceUp: true,
                        isHighlighted: false,
                        onTap: nil
                    )
                    // Small card-count badge when more than 1 card is stacked.
                    .overlay(alignment: .bottomTrailing) {
                        if pile.cards.count > 1 {
                            countBadge
                        }
                    }
                    .draggable(DragPayload(card: top, source: .foundation(pileIndex: pileIndex))) {
                        onDragStart?(top)
                        return CardView(
                            card: top,
                            isFaceUp: true,
                            isHighlighted: false,
                            onTap: nil
                        )
                        .environment(\.cardWidth, cardWidth)
                    }
                }

                if pile.topCard == nil || isDragging {
                    emptySlot
                }

                // Drop destination overlay
                Color.clear
                    .cardFrame(width: cardWidth)
                    .contentShape(Rectangle())
                    .dropDestination(for: DragPayload.self) { items, location in
                        guard let payload = items.first else { return false }
                        return onDropPayload?(payload) ?? false
                    }
            }
        }
        .frame(width: cardWidth)
        .accessibilityLabel(
            pile.isEmpty
                ? "Empty foundation slot \(pileIndex + 1)"
                : "Foundation \(pileIndex + 1): \(pile.topCard?.label ?? ""), \(groupName ?? "")"
        )
    }

    // ─── Computed Properties ────────────────────────────────────────────────

    /// The group name extracted from the base card, if present
    private var groupName: String? {
        guard let baseCard = pile.cards.first, baseCard.isBase else { return nil }
        return baseCard.label
    }

    // ─── Empty slot ─────────────────────────────────────────────────────────
    private var emptySlot: some View {
        let iconSize = cardWidth / 85 * 24  // Larger icon since no text

        return RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.subtle(), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            .cardFrame(width: cardWidth)
            .overlay(
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(Color.white.medium())
            )
    }

    /// Small badge showing how many cards are on this pile (for visual feedback).
    private var countBadge: some View {
        let badgeSize = cardWidth / 85 * 11  // Scale badge with card width

        return Text("\(pile.cards.count)")
            .font(.system(size: badgeSize, weight: .bold))
            .foregroundColor(.white)
            .padding(cardWidth / 85 * 4)
            .background(
                Circle()
                    .fill(Color.accentGold)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.subtle(), lineWidth: 1.5)
            )
            .padding(cardWidth / 85 * 3)
    }

    /// Category banner showing the group name
    private func categoryBanner(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color.accentGold)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: cardWidth)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentGold.verySubtle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentGold.subtle(), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    let emptyPile = FoundationPile()
    let occupiedPile = FoundationPile(cards: [
        Card(id: "europe_base", label: "Countries of Europe", type: .base, groupId: "europe_01", imageName: nil),
        Card(id: "france",      label: "France",              type: .partner, groupId: "europe_01", imageName: nil)
    ])

    HStack(spacing: 12) {
        FoundationView(pile: emptyPile,    pileIndex: 0)
        FoundationView(pile: occupiedPile, pileIndex: 1)
        FoundationView(pile: emptyPile,    pileIndex: 2)
        FoundationView(pile: emptyPile,    pileIndex: 3)
    }
    .padding()
    .background(Color.feltGreen)
}
