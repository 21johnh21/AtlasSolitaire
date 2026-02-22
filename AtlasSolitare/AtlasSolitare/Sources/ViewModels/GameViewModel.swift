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
    private let gameCenter = GameCenterManager.shared

    // ─── Timer ──────────────────────────────────────────────────────────────
    private var gameTimer: Timer?
    @Published private(set) var currentElapsedTime: TimeInterval = 0
    private var sessionStartTime: Date?
    private var baseElapsedTime: TimeInterval = 0

    // ─── Deck History (to avoid repeating recent decks) ────────────────────
    /// Tracks the group IDs from recent games to avoid repetition.
    /// Stores up to the last 3 games worth of group IDs.
    private var recentDeckHistory: [[String]] = []
    private let maxDeckHistorySize = 3

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
        gameCenter.authenticatePlayer()
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
        audio.play(.cardPlace)
        haptic.dropSuccess()
        autosave()
    }

    /// User tapped the reshuffle button explicitly.
    func reshuffle() {
        guard Rules.canReshuffle(stock: engine.state.stock, waste: engine.state.waste) else { return }
        engine.reshuffle()
        audio.play(.shuffle)
        autosave()
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
            // Gather group IDs from recent games to avoid repetition
            let excludedGroupIds = Set(recentDeckHistory.flatMap { $0 })

            // Pick 5 random groups per round (configurable), excluding recent ones
            let deck = try deckManager.buildRandomDeck(groupCount: 5, excludeGroupIds: excludedGroupIds)
            engine.newGame(deck: deck, seed: deck.seed)

            // Track this deck's groups in history
            let currentGroupIds = deck.groups.map { $0.id }
            recentDeckHistory.append(currentGroupIds)
            // Keep only the last N games
            if recentDeckHistory.count > maxDeckHistorySize {
                recentDeckHistory.removeFirst()
            }

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

    /// Start a demo/tutorial game with simple demo groups.
    func startDemoGame() {
        do {
            // Build the demo deck
            let deck = try deckManager.buildDemoDeck()
            engine.newGame(deck: deck, seed: deck.seed)

            // Reset stats for demo game
            currentElapsedTime = 0
            engine.state.elapsedTime = 0
            engine.state.startTime = Date()

            phase = .playing
            startTimer()
            // Don't autosave demo games
        } catch {
            // Fallback: stay on menu.
            #if DEBUG
            print("[GameViewModel] Failed to build demo deck: \(error.localizedDescription)")
            #endif
        }
    }

    /// Return to the main menu (without clearing saved game).
    func returnToMenu() {
        stopTimer()
        phase = .menu
        // Trigger potential interstitial ad
        AdManager.shared.onGameEnd()
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

    func toggleAds() {
        settings.adsEnabled.toggle()
        AdManager.shared.globalAdsEnabled = settings.adsEnabled
        saveSettings()
    }

    func showLeaderboard() {
        gameCenter.showLeaderboard()
    }

    func showAchievements() {
        gameCenter.showAchievements()
    }

    #if DEBUG
    /// DEV ONLY: Auto-complete the current game to test win screen and interstitial ads
    func devAutoWin() {
        print("[GameViewModel] 🎮 DEV: Auto-completing game...")

        // Mark all groups as completed
        engine.state.completedGroups = Set(engine.state.deck.groups.map { $0.id })

        // Clear all piles
        engine.state.stock = []
        engine.state.waste = []
        engine.state.foundations = Array(repeating: FoundationPile(), count: 4)
        engine.state.tableau = Array(repeating: [], count: 7)

        // Set cleared card count to total cards
        let totalCards = engine.state.deck.groups.reduce(0) { $0 + $1.cards.count }
        engine.state.clearedCardCount = totalCards

        // Trigger win
        engine.state.phase = .won
        publishState()
        handleWin()

        print("[GameViewModel] 🎮 DEV: Game auto-completed! Interstitial should trigger.")
    }
    #endif

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

    /// The number of cards in the waste pile.
    var wasteCount: Int { engine.state.waste.count }

    /// The waste pile array.
    var waste: [Card] { engine.state.waste }

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
            audio.play(.cardPlace)
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
            audio.play(.cardPlace)
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
            audio.play(.cardPlace)
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

        // Update statistics
        let isFirstWin = settings.totalWins == 0
        settings.totalWins += 1
        settings.currentWinStreak += 1
        if settings.currentWinStreak > settings.bestWinStreak {
            settings.bestWinStreak = settings.currentWinStreak
        }
        saveSettings()

        // Submit to Game Center
        let timeInSeconds = Int(currentElapsedTime)
        let moves = engine.state.moveCount
        gameCenter.submitGameResult(timeInSeconds: timeInSeconds, moves: moves)
        gameCenter.processGameWin(
            timeInSeconds: currentElapsedTime,
            moves: moves,
            isFirstWin: isFirstWin,
            currentWinStreak: settings.currentWinStreak,
            totalWins: settings.totalWins
        )

        // Trigger potential interstitial ad
        AdManager.shared.onGameEnd()

        try? persistence.clearGameState()
    }

    // ─── Persistence helpers ────────────────────────────────────────────────

    private func autosave() {
        // Update elapsed time with current value before saving
        engine.state.elapsedTime = currentElapsedTime
        try? persistence.saveGameState(engine.state)
    }

    private func loadSettings() {
        if let s = try? persistence.loadSettings() {
            settings = s
            audio.isEnabled  = s.soundEnabled
            haptic.isEnabled = s.hapticsEnabled
            AdManager.shared.globalAdsEnabled = s.adsEnabled
        }
    }

    private func saveSettings() {
        try? persistence.saveSettings(settings)
    }

    // ─── Timer helpers ──────────────────────────────────────────────────────

    private func startTimer() {
        // Stop any existing timer
        stopTimer()

        // Store the base time and session start
        baseElapsedTime = engine.state.elapsedTime
        sessionStartTime = Date()

        // Start a timer that fires every second
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let sessionStart = self.sessionStartTime else { return }
            // Calculate elapsed time: base time + time since this session started
            self.currentElapsedTime = self.baseElapsedTime + Date().timeIntervalSince(sessionStart)
        }
    }

    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        sessionStartTime = nil

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
