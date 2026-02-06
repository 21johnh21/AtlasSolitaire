import SwiftUI

// MARK: - CardView

/// The single reusable card component.  Renders either the face-up or face-down
/// side depending on `isFaceUp`, and exposes all the interaction + animation hooks
/// the spec requires.
struct CardView: View {
    let card: Card
    let isFaceUp: Bool

    /// When true the card is visually highlighted (selected state).
    var isHighlighted: Bool = false

    /// Unique string used as the `matchedGeometryEffect` id for move animations.
    var animationId: String { card.id }

    // ─── Interaction callbacks (set by parent) ─────────────────────────────
    var onTap:          (() -> Void)?   = nil
    var onLongPress:    (() -> Void)?   = nil
    var onDragStart:    (() -> Void)?   = nil
    var onDropSuccess:  (() -> Void)?   = nil
    var onDropFail:     (() -> Void)?   = nil
    /// Called specifically when a face-down card is flipped to face-up.
    var onFlip:         (() -> Void)?   = nil

    // ─── Body ───────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            if isFaceUp {
                faceUpView
            } else {
                faceDownView
            }
        }
        .cardFrame()
        .cardShadow()
        // 3D flip animation when isFaceUp changes.
        .rotation3DEffect(
            .degrees(isFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.4), value: isFaceUp)
        // Highlight border for selected state.
        .overlay(
            RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                .stroke(isHighlighted ? Color.accentGold : Color.clear, lineWidth: 3)
        )
        // ── Gestures ────────────────────────────────────────────────────────
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            onLongPress?()
        }
        // Accessibility
        .accessibilityLabel(isFaceUp ? card.label : "Face-down card")
        .accessibilityHint(isFaceUp ? "Card in group \(card.groupId)" : "Tap to reveal")
    }

    // ─── Face-up ────────────────────────────────────────────────────────────
    private var faceUpView: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(Color.cardWhite)
            .overlay(
                VStack(alignment: .leading, spacing: 4) {
                    // Type badge
                    HStack {
                        badge
                        Spacer()
                    }
                    Spacer()
                    // Label (large, centered)
                    Text(card.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textDark)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }

    /// Small colored badge in the top-left indicating base vs partner.
    private var badge: some View {
        Text(card.isBase ? "BASE" : "•")
            .font(.system(size: card.isBase ? 8 : 12, weight: .bold))
            .foregroundColor(card.isBase ? Color.white : Color.accentGold)
            .padding(.horizontal, card.isBase ? 4 : 0)
            .padding(.vertical, card.isBase ? 2 : 0)
            .background(card.isBase ? Color.accentGold : Color.clear)
            .cornerRadius(3)
    }

    // ─── Face-down ──────────────────────────────────────────────────────────
    private var faceDownView: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(Color.cardBack)
            .overlay(
                // Simple geometric pattern on the back.
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius - 3)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .padding(4)
            )
            .overlay(
                // Atlas icon placeholder (text for now).
                Text("A")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.25))
            )
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        CardView(card: Card(id: "test_base", label: "Countries of Europe", type: .base, groupId: "europe_01", imageName: nil), isFaceUp: true)
        CardView(card: Card(id: "test_partner", label: "France", type: .partner, groupId: "europe_01", imageName: nil), isFaceUp: true, isHighlighted: true)
        CardView(card: Card(id: "test_back", label: "Hidden", type: .partner, groupId: "europe_01", imageName: nil), isFaceUp: false)
    }
    .padding()
    .background(Color.feltGreen)
}
