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
    @State private var showQuitConfirmation = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── Quit button ─────────────────────────────────────────────
                HStack {
                    quitButton
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // ── Top bar: stock + waste ──────────────────────────────────
                topRow
                    .padding(.top, 8)
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
        // Quit confirmation alert
        .alert("Quit Game?", isPresented: $showQuitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) {
                print("[GameView] Confirmed quit, returning to menu")
                vm.returnToMenu()
            }
        } message: {
            Text("Your current game will be saved and you can resume it later.")
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
            .draggable(vm.wasteTopCard.map { card in
                print("[GameView] Drag started from waste: \(card.label)")
                return DragPayload(card: card, source: .waste)
            } ?? DragPayload(card: nil, source: .waste))

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
                .dropDestination(for: DragPayload.self) { items, location in
                    guard let payload = items.first else {
                        print("[GameView] No payload in drop")
                        return false
                    }
                    print("[GameView] Dropping \(payload.card.label) on foundation \(idx)")
                    vm.dropOnFoundation(card: payload.card, source: payload.source, pileIndex: idx)
                    return true
                }
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
            },
onDragPayload: { card, pileIdx in
                print("[GameView] Creating drag payload for tableau pile \(pileIdx): \(card.label)")
                return DragPayload(card: card, source: .tableau(pileIndex: pileIdx))
            },
            onDropPayload: { payload, pileIdx in
                print("[GameView] Dropping \(payload.card.label) on tableau \(pileIdx)")
                vm.dropOnTableau(card: payload.card, source: payload.source, pileIndex: pileIdx)
                return true
            }
        )
    }

    // ─── Quit button ────────────────────────────────────────────────────────
    private var quitButton: some View {
        Button(action: {
            print("[GameView] Quit button tapped, showing confirmation")
            showQuitConfirmation = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                Text("Quit")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(Color.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.2))
            )
        }
        .accessibilityLabel("Quit game and return to menu")
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
