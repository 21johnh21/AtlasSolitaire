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
    /// Whether the top card is currently selected.
    let isSelected: Bool

    /// Called when the user taps the top card (for tap-to-select).
    var onTapCard: (() -> Void)?
    /// Called when the user taps the empty slot while a card is selected (tap-to-place).
    var onTapEmpty: (() -> Void)?
    /// Called when a card is dropped onto this foundation (drag-and-drop).
    /// The parent view handles the actual drop payload.
    var onDrop: ((Card, MoveSource) -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            // Category banner (shown when foundation has a base card)
            if !pile.isEmpty, let groupName = groupName {
                categoryBanner(groupName)
            } else {
                // Spacer to keep alignment consistent
                Color.clear
                    .frame(height: 20)
            }

            // Card or empty slot
            ZStack {
                if let top = pile.topCard {
                    CardView(
                        card: top,
                        isFaceUp: true,
                        isHighlighted: isSelected,
                        onTap: onTapCard
                    )
                    // Small card-count badge when more than 1 card is stacked.
                    .overlay(alignment: .bottomTrailing) {
                        if pile.cards.count > 1 {
                            countBadge
                        }
                    }
                } else {
                    emptySlot
                        .onTapGesture { onTapEmpty?() }
                }
            }
        }
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
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            .cardFrame()
            .overlay(
                VStack(spacing: 2) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.25))
                    Text("Base")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.25))
                }
            )
    }

    /// Small badge showing how many cards are on this pile (for visual feedback).
    private var countBadge: some View {
        Text("\(pile.cards.count)")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(3)
            .background(Color.accentGold)
            .clipShape(Circle())
            .padding(2)
    }

    /// Category banner showing the group name
    private func categoryBanner(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color.accentGold)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: CardLayout.width)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentGold.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentGold.opacity(0.3), lineWidth: 1)
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
        FoundationView(pile: emptyPile,    pileIndex: 0, isSelected: false)
        FoundationView(pile: occupiedPile, pileIndex: 1, isSelected: false)
        FoundationView(pile: emptyPile,    pileIndex: 2, isSelected: false)
        FoundationView(pile: emptyPile,    pileIndex: 3, isSelected: false)
    }
    .padding()
    .background(Color.feltGreen)
}
