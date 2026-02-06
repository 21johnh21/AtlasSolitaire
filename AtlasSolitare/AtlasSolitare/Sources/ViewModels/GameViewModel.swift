import Foundation
import Combine
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - GameViewModel

/// The single ObservableObject that drives the entire game UI.
/// Owns a GameEngine, wires up persistence auto-save, and exposes
/// intent methods that Views call (tap stock, drag card, etc.).
class GameViewModel: ObservableObject {

    // ─── Published state ────────────────────────────────────────────────────
    /// Current game phase (menu / playing / won).
    @Published private(set) var phase: GamePhase = .menu

    /// The full game state — Views read pile contents from here.
    @Published private(set) var gameState: GameState?

    /// The currently selected card + its source (for tap-to-select flow).
    @Published private(set) var selectedCard: SelectedCard?

    /// User settings.
    @Published var settings: AppSettings = AppSettings()

    // ─── Dependencies ───────────────────────────────────────────────────────
    private let engine: GameEngine
    private let deckManager: DeckManager
    private let persistence: PersistenceManager
    private let audio = AudioManager.shared
    private let haptic = HapticManager.shared

    // ─── Init ───────────────────────────────────────────────────────────────
    init(
        engine: GameEngine? = nil,
        deckManager: DeckManager? = nil,
        persistence: PersistenceManager? = nil
    ) {
        // Provide a default GameEngine with an empty state; newGame() will replace it.
        let emptyDeck = Deck(id: "empty", name: "", groups: [], seed: nil)
        let emptyState = GameState(deck: emptyDeck)
        self.engine = engine ?? GameEngine(state: emptyState)
        self.deckManager = deckManager ?? DeckManager()
        self.persistence = persistence ?? PersistenceManager()

        // Wire engine callbacks.
        self.engine.onStateChanged = { [weak self] in
            self?.publishState()
        }
        self.engine.onGroupCompleted = { [weak self] groupId in
            self?.handleGroupCompleted(groupId)
        }
        self.engine.onWin = { [weak self] in
            self?.handleWin()
        }
    }

    // ─── Lifecycle ──────────────────────────────────────────────────────────

    /// Called once at app launch.  Restores a saved game or transitions to menu.
    func onAppear() {
        loadSettings()
        if let saved = try? persistence.loadGameState(), saved.phase == .playing {
            engine.state = saved
            publishState()
        } else {
            phase = .menu
        }
    }

    // ─── MARK: Intent Methods (called by Views) ────────────────────────────

    /// User tapped the stock pile — draw one card.
    func tapStock() {
        print("[GameViewModel] tapStock: stock has \(engine.state.stock.count) cards")
        if engine.state.stock.isEmpty {
            // Auto-reshuffle when stock is empty and user taps.
            print("[GameViewModel] Stock empty, reshuffling")
            reshuffle()
            return
        }
        engine.drawFromStock()
        print("[GameViewModel] Drew card to waste, waste now has \(engine.state.waste.count) cards")
        audio.play(.flip)
        haptic.dropSuccess()
    }

    /// User tapped the reshuffle button explicitly.
    func reshuffle() {
        guard Rules.canReshuffle(stock: engine.state.stock, waste: engine.state.waste) else { return }
        engine.reshuffle()
        audio.play(.move)
    }

    /// User tapped a card (tap-to-select flow).
    /// If nothing is selected, select this card.
    /// If this card is already selected, deselect.
    /// If a *different* card is selected, attempt a move from the selected card to this target.
    func tapCard(card: Card, source: MoveSource) {
        print("[GameViewModel] tapCard: \(card.label) from \(source)")

        guard let sel = selectedCard else {
            // Nothing selected yet — select this card if it's a valid source.
            if isCardDraggable(card: card, source: source) {
                print("[GameViewModel] Selected card: \(card.label)")
                selectedCard = SelectedCard(card: card, source: source)
                haptic.dragStart()
            } else {
                print("[GameViewModel] Card not draggable: \(card.label)")
            }
            return
        }

        if sel.card.id == card.id {
            // Tap same card again → deselect.
            print("[GameViewModel] Deselected card: \(card.label)")
            selectedCard = nil
            return
        }

        print("[GameViewModel] Already have selection: \(sel.card.label), tapped: \(card.label)")

        // A different card is tapped — try to move the selected card to this location
        // Check if the tapped card's pile can accept the selected card
        let targetIsFoundation = (source == .foundation(pileIndex: 0) ||
                                   source == .foundation(pileIndex: 1) ||
                                   source == .foundation(pileIndex: 2) ||
                                   source == .foundation(pileIndex: 3))
        let targetIsTableau = { () -> Bool in
            if case .tableau = source { return true }
            return false
        }()

        if targetIsFoundation {
            // Try to move selected card to this foundation pile
            if case .foundation(let idx) = source {
                print("[GameViewModel] Attempting move to foundation \(idx)")
                attemptMove(card: sel.card, source: sel.source, target: .foundation(pileIndex: idx))
            }
        } else if targetIsTableau {
            // Try to move selected card to this tableau pile
            if case .tableau(let idx) = source {
                print("[GameViewModel] Attempting move to tableau \(idx)")
                attemptMove(card: sel.card, source: sel.source, target: .tableau(pileIndex: idx))
            }
        } else {
            // Neither foundation nor tableau — just swap selection if new card is draggable
            if isCardDraggable(card: card, source: source) {
                print("[GameViewModel] Swapping selection to: \(card.label)")
                selectedCard = SelectedCard(card: card, source: source)
            } else {
                print("[GameViewModel] Deselecting (target not draggable)")
                selectedCard = nil
            }
        }
    }

    /// User tapped an empty foundation slot while a card is selected.
    func tapEmptyFoundation(pileIndex: Int) {
        print("[GameViewModel] tapEmptyFoundation: \(pileIndex)")
        guard let sel = selectedCard else {
            print("[GameViewModel] No card selected")
            return
        }
        print("[GameViewModel] Moving \(sel.card.label) to empty foundation \(pileIndex)")
        attemptMove(card: sel.card, source: sel.source, target: .foundation(pileIndex: pileIndex))
    }

    /// User tapped an empty tableau slot while a card is selected.
    func tapEmptyTableau(pileIndex: Int) {
        print("[GameViewModel] tapEmptyTableau: \(pileIndex)")
        guard let sel = selectedCard else {
            print("[GameViewModel] No card selected")
            return
        }
        print("[GameViewModel] Moving \(sel.card.label) to empty tableau \(pileIndex)")
        attemptMove(card: sel.card, source: sel.source, target: .tableau(pileIndex: pileIndex))
    }

    /// Drag-and-drop: user dropped a card onto a foundation.
    func dropOnFoundation(card: Card, source: MoveSource, pileIndex: Int) {
        attemptMove(card: card, source: source, target: .foundation(pileIndex: pileIndex))
    }

    /// Drag-and-drop: user dropped a card onto a tableau pile.
    func dropOnTableau(card: Card, source: MoveSource, pileIndex: Int) {
        attemptMove(card: card, source: source, target: .tableau(pileIndex: pileIndex))
    }

    /// Start a new game (called from menu or win screen "Play Again").
    func startNewGame() {
        do {
            // Pick 3 random groups per round (configurable).
            let deck = try deckManager.buildRandomDeck(groupCount: 3)
            engine.newGame(deck: deck, seed: deck.seed)
            phase = .playing
            autosave()
        } catch {
            // Fallback: log and stay on menu.
            print("[GameViewModel] Failed to build deck: \(error.localizedDescription)")
        }
    }

    /// Continue a saved game (called from menu "Continue Game" button).
    func continueGame() {
        print("[GameViewModel] Continuing saved game")
        guard let saved = try? persistence.loadGameState(), saved.phase == .playing else {
            print("[GameViewModel] No saved game found or game not in playing state")
            return
        }
        engine.state = saved
        publishState()
    }

    /// Return to the main menu (without clearing saved game).
    func returnToMenu() {
        print("[GameViewModel] Returning to menu")
        phase = .menu
        // Don't clear the game state - it's already auto-saved
    }

    // ─── Settings ───────────────────────────────────────────────────────────

    func toggleSound() {
        settings.soundEnabled.toggle()
        audio.isEnabled = settings.soundEnabled
        saveSettings()
    }

    func toggleHaptics() {
        settings.hapticsEnabled.toggle()
        haptic.isEnabled = settings.hapticsEnabled
        saveSettings()
    }

    // ─── MARK: Derived / Query Helpers (for Views) ─────────────────────────

    /// Whether there's a saved game available to continue
    var hasSavedGame: Bool {
        guard let saved = try? persistence.loadGameState() else { return false }
        return saved.phase == .playing
    }

    /// Whether the stock pile has cards.
    var stockHasCards: Bool { engine.state.stock.count > 0 }

    /// Whether reshuffle is available.
    var canReshuffle: Bool {
        Rules.canReshuffle(stock: engine.state.stock, waste: engine.state.waste)
    }

    /// The top card of the waste pile (nil if empty).
    var wasteTopCard: Card? { engine.state.waste.last }

    /// Current foundation piles.
    var foundations: [FoundationPile] { engine.state.foundations }

    /// Current tableau piles.
    var tableau: [[TableauCard]] { engine.state.tableau }

    /// Number of completed groups.
    var completedGroupCount: Int { engine.state.completedGroups.count }

    /// Total groups in this round.
    var totalGroupCount: Int { engine.state.deck.groupCount }

    /// Is a given card the currently selected card?
    func isSelected(_ card: Card) -> Bool {
        selectedCard?.card.id == card.id
    }

    // ─── MARK: Private ──────────────────────────────────────────────────────

    private func attemptMove(card: Card, source: MoveSource, target: MoveTarget) {
        print("[GameViewModel] attemptMove: \(card.label) from \(source) to \(target)")
        let result = engine.move(card: card, source: source, target: target)
        switch result {
        case .valid:
            print("[GameViewModel] ✅ Move succeeded")
            audio.play(.move)
            haptic.dropSuccess()
            selectedCard = nil
            autosave()
        case .invalid(let reason):
            print("[GameViewModel] ❌ Move failed: \(reason)")
            audio.play(.invalid)
            haptic.dropFail()
            selectedCard = nil
        }
    }

    /// A card is draggable if it's the top face-up card of its pile.
    private func isCardDraggable(card: Card, source: MoveSource) -> Bool {
        switch source {
        case .waste:
            return engine.state.waste.last?.id == card.id
        case .tableau(let idx):
            guard let top = engine.state.tableau[idx].last else { return false }
            return top.card.id == card.id && top.isFaceUp
        case .foundation(let idx):
            return engine.state.foundations[idx].topCard?.id == card.id
        case .stock:
            return false  // stock cards are not directly draggable
        }
    }

    private func publishState() {
        gameState = engine.state
        phase     = engine.state.phase
    }

    private func handleGroupCompleted(_ groupId: String) {
        audio.play(.completeGroup)
        haptic.success()
    }

    private func handleWin() {
        audio.play(.win)
        haptic.success()
        try? persistence.clearGameState()
    }

    // ─── Persistence helpers ────────────────────────────────────────────────

    private func autosave() {
        try? persistence.saveGameState(engine.state)
    }

    private func loadSettings() {
        if let s = try? persistence.loadSettings() {
            settings = s
            audio.isEnabled  = s.soundEnabled
            haptic.isEnabled = s.hapticsEnabled
        }
    }

    private func saveSettings() {
        try? persistence.saveSettings(settings)
    }
}

// MARK: - SelectedCard

/// Holds a card and where it came from, used by the tap-to-select flow.
struct SelectedCard {
    let card: Card
    let source: MoveSource
}
