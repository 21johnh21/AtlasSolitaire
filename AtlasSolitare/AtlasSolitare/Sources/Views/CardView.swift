import SwiftUI

// MARK: - CardView

/// The single reusable card component.  Renders either the face-up or face-down
/// side depending on `isFaceUp`, and exposes all the interaction + animation hooks
/// the spec requires.
struct CardView: View, Equatable {
    let card: Card
    let isFaceUp: Bool

    /// When true the card is visually highlighted (selected state).
    var isHighlighted: Bool = false

    // MARK: - Equatable
    static func == (lhs: CardView, rhs: CardView) -> Bool {
        lhs.card.id == rhs.card.id &&
        lhs.isFaceUp == rhs.isFaceUp &&
        lhs.isHighlighted == rhs.isHighlighted
    }

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

    @Environment(\.cardWidth) private var cardWidth

    // ─── Body ───────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            if isFaceUp {
                faceUpView
            } else {
                faceDownView
            }
        }
        .cardFrame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: CardLayout.cornerRadius))
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
        let fontSize = cardWidth / 85 * 13  // Scale font with card width
        let padding = cardWidth / 85 * 6    // Scale padding with card width

        return RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
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
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(Color.textDark)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(padding)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
                    .stroke(Color.gray.medium(), lineWidth: 1.5)
            )
    }

    /// Small colored badge in the top-left indicating base vs partner.
    @ViewBuilder
    private var badge: some View {
        if card.isBase {
            // BASE badge with stronger visual hierarchy
            Text("BASE")
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Color.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentGold)
                        .shadow(color: Color.accentGold.medium(), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(red: 0.95, green: 0.82, blue: 0.45), lineWidth: 1)
                )
        } else {
            // Partner badge - small icon instead of bullet
            Image(systemName: "circle.fill")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(Color.accentGold)
        }
    }

    // ─── Face-down ──────────────────────────────────────────────────────────
    private var faceDownView: some View {
        RoundedRectangle(cornerRadius: CardLayout.cornerRadius)
            .fill(Color.cardBack)
            .overlay(
                // Simple geometric pattern on the back.
                RoundedRectangle(cornerRadius: CardLayout.cornerRadius - 3)
                    .stroke(Color.white.verySubtle(), lineWidth: 1)
                    .padding(4)
            )
            .overlay(
                // Atlas icon with subtle styling
                ZStack {
                    Text("A")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.white.verySubtle())

                    // Subtle inner glow effect
                    Text("A")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.05))
                        .blur(radius: 2)
                }
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
