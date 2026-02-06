import SwiftUI
import UniformTypeIdentifiers

// MARK: - GameView

/// The main in-game screen.  Lays out Stock, Waste, Foundations, and Tableau
/// in portrait orientation and wires all interactions to the GameViewModel.
///
/// Drag-and-drop is implemented via SwiftUI's `.draggable()` / `.dropTarget()`
/// (iOS 16+).  A tap-to-select fallback is always available for accessibility.
struct GameView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── Top bar: stock + waste ──────────────────────────────────
                topRow
                    .padding(.top, 12)
                    .padding(.horizontal)

                // ── Foundations row ─────────────────────────────────────────
                foundationsRow
                    .padding(.top, 10)
                    .padding(.horizontal)

                // ── Progress indicator ─────────────────────────────────────
                progressRow
                    .padding(.top, 6)

                Spacer(minLength: 8)

                // ── Tableau (fills remaining vertical space) ──────────────
                tableauSection
                    .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.feltGreen)
            .ignoresSafeArea(edges: .bottom)
        }
        // Win screen overlay.
        .fullScreenCover(
            isPresented: Binding(
                get: { vm.phase == .won },
                set: { if !$0 { vm.returnToMenu() } }
            )
        ) {
            WinView(vm: vm)
        }
    }

    // ─── Top row: Stock (right) + Waste (left) ─────────────────────────────
    private var topRow: some View {
        HStack(alignment: .top, spacing: CardLayout.horizontalSpacing) {
            // Waste on the left.
            WasteView(
                topCard: vm.wasteTopCard,
                isSelected: vm.wasteTopCard.map { vm.isSelected($0) } ?? false,
                onTap: {
                    if let card = vm.wasteTopCard {
                        vm.tapCard(card: card, source: .waste)
                    }
                }
            )
            // TODO: Add .draggable for drag-and-drop (requires iOS 17+)
            // Tap-to-select works for now

            Spacer()

            // Stock on the right.
            StockView(
                cardCount: vm.gameState?.stock.count ?? 0,
                canReshuffle: vm.canReshuffle,
                onTap: vm.tapStock
            )
        }
    }

    // ─── 4 foundation slots ─────────────────────────────────────────────────
    private var foundationsRow: some View {
        HStack(spacing: CardLayout.horizontalSpacing) {
            ForEach(Array(0..<4), id: \.self) { idx in
                let pile = vm.foundations[safe: idx] ?? FoundationPile()
                FoundationView(
                    pile: pile,
                    pileIndex: idx,
                    isSelected: pile.topCard.map { vm.isSelected($0) } ?? false,
                    onTapCard: {
                        if let card = pile.topCard {
                            vm.tapCard(card: card, source: .foundation(pileIndex: idx))
                        }
                    },
                    onTapEmpty: {
                        vm.tapEmptyFoundation(pileIndex: idx)
                    }
                )
                // TODO: Add dropTarget for drag-and-drop (requires iOS 17+)
                // Tap-to-select works for now
            }
        }
    }

    // ─── Progress: "X / Y groups completed" ─────────────────────────────────
    private var progressRow: some View {
        Text("\(vm.completedGroupCount) / \(vm.totalGroupCount) groups completed")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.white.opacity(0.7))
    }

    // ─── Tableau ────────────────────────────────────────────────────────────
    private var tableauSection: some View {
        TableauView(
            piles: vm.tableau,
            selectedCardId: vm.selectedCard?.card.id,
            onTapCard: { card, pileIdx in
                vm.tapCard(card: card, source: .tableau(pileIndex: pileIdx))
            },
            onTapEmptyPile: { pileIdx in
                vm.tapEmptyTableau(pileIndex: pileIdx)
            }
        )
        // TODO: Add dropTarget for drag-and-drop (requires iOS 17+)
        // Tap-to-select works for now
    }
}

// MARK: - DragPayload

/// Conforms to Transferable so we can use SwiftUI drag-and-drop.
/// Wraps the card being dragged and its source location.
struct DragPayload: Codable, Transferable {
    let card: Card
    let sourceKey: String

    var source: MoveSource {
        MoveSource.from(key: sourceKey)
    }

    /// Convenience init that accepts an optional card (returns a dummy if nil).
    init(card: Card?, source: MoveSource) {
        self.card   = card ?? Card(id: "__nil__", label: "", type: .partner, groupId: "", imageName: nil)
        self.sourceKey = source.key
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - MoveSource serialization helpers

extension MoveSource {
    /// A compact string key for serialization in drag payloads.
    var key: String {
        switch self {
        case .stock:                        return "stock"
        case .waste:                        return "waste"
        case .tableau(let idx):             return "tableau_\(idx)"
        case .foundation(let idx):          return "foundation_\(idx)"
        }
    }

    /// Reconstruct a MoveSource from its key.
    static func from(key: String) -> MoveSource {
        if key == "stock"  { return .stock }
        if key == "waste"  { return .waste }
        if key.hasPrefix("tableau_"),    let idx = Int(key.dropFirst("tableau_".count))    { return .tableau(pileIndex: idx) }
        if key.hasPrefix("foundation_"), let idx = Int(key.dropFirst("foundation_".count)) { return .foundation(pileIndex: idx) }
        return .waste  // fallback
    }
}

// MARK: - Preview

#Preview {
    let vm = GameViewModel()
    GameView(vm: vm)
}
