import SwiftUI

// MARK: - TableauPilePreviewView

/// A modal view that shows all cards in a tableau pile in a scrollable list.
/// Activated by long-pressing on a tableau pile.
struct TableauPilePreviewView: View {
    let pile: [TableauCard]
    let pileIndex: Int
    @Binding var isPresented: Bool

    @Environment(\.cardWidth) private var cardWidth
    private let haptic = HapticManager.shared

    var body: some View {
        // Card list container
        VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Tableau Pile \(pileIndex + 1)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        haptic.light()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .withClickSound()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Scrollable card list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(pile.enumerated()), id: \.offset) { index, tableauCard in
                            cardRow(tableauCard: tableauCard, index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 400, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.feltGreen)
                    .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
            )
            .padding(40)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    @ViewBuilder
    private func cardRow(tableauCard: TableauCard, index: Int) -> some View {
        HStack(spacing: 0) {
            // Card preview
            CardView(
                card: tableauCard.card,
                isFaceUp: tableauCard.isFaceUp,
                isHighlighted: false
            )
            .frame(width: 100)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tableauCard.isFaceUp ? Color.white.opacity(0.1) : Color.black.opacity(0.2))
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isPresented = true

    let samplePile: [TableauCard] = [
        TableauCard(card: Card(id: "c1", label: "Europe", type: .base, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: false),
        TableauCard(card: Card(id: "c2", label: "France", type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: false),
        TableauCard(card: Card(id: "c3", label: "Italy", type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: true),
        TableauCard(card: Card(id: "c4", label: "Spain", type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: true),
        TableauCard(card: Card(id: "c5", label: "Germany", type: .partner, groupId: "eu", possibleGroupIds: ["eu"], imageName: nil), isFaceUp: true),
    ]

    return ZStack {
        Color.feltGreen.ignoresSafeArea()

        // Simulate the shadow overlay from GameView
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        if isPresented {
            TableauPilePreviewView(pile: samplePile, pileIndex: 0, isPresented: $isPresented)
        }
    }
}
