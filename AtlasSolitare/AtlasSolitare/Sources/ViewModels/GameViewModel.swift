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


    /// User settings.
    @Published var settings: AppSettings = AppSettings()

    /// The ID of the most recently completed group (for showing celebration animation).
    @Published private(set) var recentlyCompletedGroupId: String?

    // ─── Dependencies ───────────────────────────────────────────────────────
    private let engine: GameEngine
    private let deckManager: DeckManager
    private let persistence: PersistenceManager
    private let audio = AudioManager.shared
    private let haptic = HapticManager.shared

    // ─── Timer ──────────────────────────────────────────────────────────────
    private var gameTimer: Timer?
    @Published private(set) var currentElapsedTime: TimeInterval = 0

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
            currentElapsedTime = saved.elapsedTime
            publishState()
            startTimer()
        } else {
            phase = .menu
        }
    }

    // ─── MARK: Intent Methods (called by Views) ────────────────────────────

    /// User tapped the stock pile — draw one card.
    func tapStock() {
        if engine.state.stock.isEmpty {
            // Auto-reshuffle when stock is empty and user taps.
            reshuffle()
            return
        }
        engine.drawFromStock()
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

    /// Drag-and-drop: user dropped a card onto a foundation.
    func dropOnFoundation(card: Card, source: MoveSource, pileIndex: Int) {
        attemptMove(card: card, source: source, target: .foundation(pileIndex: pileIndex))
    }

    /// Drag-and-drop: user dropped multiple cards onto a foundation pile.
    func dropOnFoundation(cards: [Card], source: MoveSource, pileIndex: Int) {
        attemptMoveStackToFoundation(cards: cards, source: source, pileIndex: pileIndex)
    }

    /// Drag-and-drop: user dropped a card onto a tableau pile.
    func dropOnTableau(card: Card, source: MoveSource, pileIndex: Int) {
        attemptMove(card: card, source: source, target: .tableau(pileIndex: pileIndex))
    }

    /// Drag-and-drop: user dropped multiple cards onto a tableau pile.
    func dropOnTableau(cards: [Card], source: MoveSource, pileIndex: Int) {
        attemptMoveStack(cards: cards, source: source, target: .tableau(pileIndex: pileIndex))
    }

    /// Start a new game (called from menu or win screen "Play Again").
    func startNewGame() {
        do {
            // Pick 3 random groups per round (configurable).
            let deck = try deckManager.buildRandomDeck(groupCount: 3)
            engine.newGame(deck: deck, seed: deck.seed)

            // Reset stats for new game
            currentElapsedTime = 0
            engine.state.elapsedTime = 0
            engine.state.startTime = Date()

            phase = .playing
            startTimer()
            autosave()
        } catch {
            // Fallback: stay on menu.
            #if DEBUG
            print("[GameViewModel] Failed to build deck: \(error.localizedDescription)")
            #endif
        }
    }

    /// Continue a saved game (called from menu "Continue Game" button).
    func continueGame() {
        guard let saved = try? persistence.loadGameState(), saved.phase == .playing else {
            return
        }
        engine.state = saved
        currentElapsedTime = saved.elapsedTime
        publishState()
        startTimer()
    }

    /// Return to the main menu (without clearing saved game).
    func returnToMenu() {
        stopTimer()
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


    /// Get the name of a group by its ID.
    func groupName(for groupId: String) -> String? {
        gameState?.deck.groups.first(where: { $0.id == groupId })?.name
    }

    // ─── MARK: Private ──────────────────────────────────────────────────────

    private func attemptMove(card: Card, source: MoveSource, target: MoveTarget) {
        let result = engine.move(card: card, source: source, target: target)
        switch result {
        case .valid:
            audio.play(.move)
            haptic.dropSuccess()
            autosave()
        case .invalid:
            audio.play(.invalid)
            haptic.dropFail()
        }
    }

    private func attemptMoveStack(cards: [Card], source: MoveSource, target: MoveTarget) {
        guard !cards.isEmpty else { return }
        let result = engine.moveStack(cards: cards, source: source, target: target)
        switch result {
        case .valid:
            audio.play(.move)
            haptic.dropSuccess()
            autosave()
        case .invalid:
            audio.play(.invalid)
            haptic.dropFail()
        }
    }

    private func attemptMoveStackToFoundation(cards: [Card], source: MoveSource, pileIndex: Int) {
        let result = engine.moveStackToFoundation(cards: cards, source: source, foundationIndex: pileIndex)
        switch result {
        case .valid:
            audio.play(.move)
            haptic.dropSuccess()
            autosave()
        case .invalid:
            audio.play(.invalid)
            haptic.dropFail()
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
        haptic.groupCompletionRumble()
        recentlyCompletedGroupId = groupId

        // Clear the celebration after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.recentlyCompletedGroupId == groupId {
                self?.recentlyCompletedGroupId = nil
            }
        }
    }

    private func handleWin() {
        stopTimer()
        audio.play(.win)
        haptic.winRumble()
        try? persistence.clearGameState()
    }

    // ─── Persistence helpers ────────────────────────────────────────────────

    private func autosave() {
        // Update elapsed time before saving
        if gameTimer != nil {
            engine.state.elapsedTime = currentElapsedTime
        }
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

    // ─── Timer helpers ──────────────────────────────────────────────────────

    private func startTimer() {
        // Stop any existing timer
        stopTimer()

        // Reset start time to now
        engine.state.startTime = Date()

        // Start a timer that fires every second
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentElapsedTime = self.engine.state.elapsedTime + Date().timeIntervalSince(self.engine.state.startTime)
        }
    }

    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil

        // Save the elapsed time to the state
        if phase == .playing {
            engine.state.elapsedTime = currentElapsedTime
        }
    }
}

// MARK: - SelectedCard

/// Holds a card and where it came from, used by the tap-to-select flow.
struct SelectedCard {
    let card: Card
    let source: MoveSource
}
