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
    @State private var draggingCardIds: Set<String> = []
    @State private var cardWidth: CGFloat = CardLayout.width

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    updateCardWidth(for: geo.size.width)
                }
                .onChange(of: geo.size.width) { _, newWidth in
                    updateCardWidth(for: newWidth)
                }

            let _ = cardWidth  // Force usage to avoid warning

            VStack(spacing: 0) {
                // ── Quit button ─────────────────────────────────────────────
                HStack {
                    quitButton
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // ── Top row: waste + stats + stock ──────────────────────────
                topRow
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                // ── Foundations row ─────────────────────────────────────────
                foundationsRow
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                // ── Progress indicator ─────────────────────────────────────
                progressRow
                    .padding(.top, 6)

                Spacer(minLength: 8)

                // ── Tableau (fills remaining vertical space) ──────────────
                tableauSection
                    .padding(.horizontal, 16)

                Spacer(minLength: 12)
            }
            .environment(\.cardWidth, cardWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.feltGreen)
            .ignoresSafeArea(edges: .bottom)
            // Catch-all drop handler to clear dragging state if dropped on invalid area
            .dropDestination(for: DragPayload.self) { items, location in
                print("[GameView] 🚫 Drop on invalid area (game background)")
                print("[GameView]   Clearing dragging state")
                draggingCardIds.removeAll()
                return false // Don't accept the drop
            }
        }
        // Win screen overlay.
        .fullScreenCover(
            isPresented: Binding(
                get: { vm.phase == .won },
                set: { _ in }
            )
        ) {
            WinView(vm: vm)
        }
        // Group completion celebration overlay
        .overlay {
            if let completedGroupId = vm.recentlyCompletedGroupId,
               let groupName = vm.groupName(for: completedGroupId) {
                GroupCompletionView(groupName: groupName)
                    .transition(.opacity)
            }
        }
    }

    // ─── Top row: Waste (left) + Stats (center) + Stock (right) ───────────
    private var topRow: some View {
        HStack(alignment: .center, spacing: CardLayout.horizontalSpacing) {
            // Waste on the left.
            WasteView(
                topCard: vm.wasteTopCard,
                isSelected: vm.wasteTopCard.map { vm.isSelected($0) } ?? false,
                draggingCardIds: draggingCardIds,
                onTap: {
                    if let card = vm.wasteTopCard {
                        vm.tapCard(card: card, source: .waste)
                    }
                },
                onDragPayload: { card in
                    print("[GameView] 🎯 Waste drag started: \(card.label) (\(card.id))")
                    print("[GameView]   Previous draggingCardIds: \(draggingCardIds)")

                    // Clear any previous dragging state before starting new drag
                    draggingCardIds.removeAll()
                    draggingCardIds = [card.id]

                    print("[GameView]   New draggingCardIds: \(draggingCardIds)")
                    return DragPayload(card: card, source: .waste)
                }
            )

            Spacer()

            // Stats in the center
            statsDisplay

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
        let foundations = vm.foundations  // Cache the array lookup
        return HStack(spacing: CardLayout.horizontalSpacing) {
            ForEach(Array(0..<4), id: \.self) { idx in
                let pile = foundations[safe: idx] ?? FoundationPile()
                FoundationView(
                    pile: pile,
                    pileIndex: idx,
                    isSelected: pile.topCard.map { vm.isSelected($0) } ?? false,
                    draggingCardIds: draggingCardIds,
                    onDragStart: { card in
                        print("[GameView] 🎯 Foundation drag started: \(card.label) (\(card.id))")
                        print("[GameView]   Previous draggingCardIds: \(draggingCardIds)")

                        // Clear any previous dragging state before starting new drag
                        draggingCardIds.removeAll()
                        draggingCardIds = [card.id]

                        print("[GameView]   New draggingCardIds: \(draggingCardIds)")
                    },
                    onTapCard: {
                        if let card = pile.topCard {
                            vm.tapCard(card: card, source: .foundation(pileIndex: idx))
                        }
                    },
                    onTapEmpty: {
                        vm.tapEmptyFoundation(pileIndex: idx)
                    },
                    onDropPayload: { payload in
                        print("[GameView] 📥 Foundation drop: \(payload.cards.count) card(s) to pile \(idx)")
                        print("[GameView]   Cards: \(payload.cards.map { $0.label })")
                        print("[GameView]   draggingCardIds before drop: \(draggingCardIds)")

                        // If multiple cards, move them all to the foundation
                        if payload.cards.count > 1 {
                            vm.dropOnFoundation(cards: payload.cards, source: payload.source, pileIndex: idx)
                        } else {
                            vm.dropOnFoundation(card: payload.card, source: payload.source, pileIndex: idx)
                        }

                        // Clear dragging state immediately
                        print("[GameView] 🧹 Clearing dragging state for foundation drop")
                        draggingCardIds.removeAll()
                        print("[GameView]   draggingCardIds after clear: \(draggingCardIds)")

                        return true
                    }
                )
            }
        }
    }

    // ─── Stats display (top center) ─────────────────────────────────────────
    private var statsDisplay: some View {
        HStack(spacing: 12) {
            // Moves
            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                Text("\(vm.gameState?.moveCount ?? 0)")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color.white.opacity(0.75))

            // Separator
            Text("•")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.4))

            // Time
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text(formatTime(vm.currentElapsedTime))
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundColor(Color.white.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }

    // ─── Progress: "X / Y groups completed" ─────────────────────────────────
    private var progressRow: some View {
        Text("\(vm.completedGroupCount) / \(vm.totalGroupCount) groups completed")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.white.opacity(0.7))
    }

    // ─── Helper to format time ──────────────────────────────────────────────
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // ─── Tableau ────────────────────────────────────────────────────────────
    private var tableauSection: some View {
        let tableau = vm.tableau  // Cache the array lookup
        return TableauView(
            piles: tableau,
            selectedCardId: vm.selectedCard?.card.id,
            draggingCardIds: draggingCardIds,
            onTapCard: { card, pileIdx in
                vm.tapCard(card: card, source: .tableau(pileIndex: pileIdx))
            },
            onTapEmptyPile: { pileIdx in
                vm.tapEmptyTableau(pileIndex: pileIdx)
            },
            onDragPayload: { card, pileIdx, cardIdx in
                print("[GameView] 🎯 Tableau drag started: \(card.label) from pile \(pileIdx) index \(cardIdx)")
                print("[GameView]   Previous draggingCardIds: \(draggingCardIds)")

                // Clear any previous dragging state before starting new drag
                // Use a temporary variable to force SwiftUI to detect the change
                let oldIds = draggingCardIds
                draggingCardIds = []

                if !oldIds.isEmpty {
                    print("[GameView]   ⚠️ Cleared stale dragging state: \(oldIds)")
                }

                // Get the stack of cards starting from this index
                guard let state = vm.gameState else {
                    return DragPayload(card: card, source: .tableau(pileIndex: pileIdx))
                }
                let pile = state.tableau[pileIdx]
                let stackIndices = Rules.getMovableStack(from: pile, startIndex: cardIdx)
                let stackCards = stackIndices.map { pile[$0].card }

                print("[GameView]   Stack size: \(stackCards.count) cards")
                print("[GameView]   Cards: \(stackCards.map { $0.label })")

                // Mark these cards as being dragged
                draggingCardIds = Set(stackCards.map { $0.id })
                print("[GameView]   New draggingCardIds: \(draggingCardIds)")

                return DragPayload(cards: stackCards, source: .tableau(pileIndex: pileIdx))
            },
            onDropPayload: { payload, pileIdx in
                print("[GameView] 📥 Tableau drop: \(payload.cards.count) card(s) to pile \(pileIdx)")
                print("[GameView]   Cards: \(payload.cards.map { $0.label })")
                print("[GameView]   draggingCardIds before drop: \(draggingCardIds)")

                vm.dropOnTableau(cards: payload.cards, source: payload.source, pileIndex: pileIdx)

                // Clear dragging state immediately
                print("[GameView] 🧹 Clearing dragging state for tableau drop")
                draggingCardIds.removeAll()
                print("[GameView]   draggingCardIds after clear: \(draggingCardIds)")

                return true
            }
        )
    }

    // ─── Quit button ────────────────────────────────────────────────────────
    private var quitButton: some View {
        Button(action: {
            vm.returnToMenu()
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

    // ─── Helper methods ─────────────────────────────────────────────────────
    private func updateCardWidth(for screenWidth: CGFloat) {
        let newWidth = CardLayout.width(for: screenWidth)
        if abs(newWidth - cardWidth) > 0.1 {  // Only update if significantly different
            cardWidth = newWidth
        }
    }
}

// MARK: - DragPayload

/// Conforms to Transferable so we can use SwiftUI drag-and-drop.
/// Wraps the card(s) being dragged and its source location.
struct DragPayload: Codable, Transferable {
    let card: Card          // The primary (first) card being dragged
    let cards: [Card]       // All cards in the stack (including the first card)
    let sourceKey: String

    var source: MoveSource {
        MoveSource.from(key: sourceKey)
    }

    /// Convenience init that accepts an optional card (returns a dummy if nil).
    init(card: Card?, source: MoveSource) {
        self.card   = card ?? Card(id: "__nil__", label: "", type: .partner, groupId: "", imageName: nil)
        self.cards  = card.map { [$0] } ?? []
        self.sourceKey = source.key
    }

    /// Init for dragging multiple cards as a stack
    init(cards: [Card], source: MoveSource) {
        self.card   = cards.first ?? Card(id: "__nil__", label: "", type: .partner, groupId: "", imageName: nil)
        self.cards  = cards
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
