import Foundation

// MARK: - FoundationPile

/// Represents one of the 4 foundation slots.
/// Empty when `cards` is empty.  The first card placed must be a base card.
struct FoundationPile: Codable, Equatable {
    /// Cards in this pile, bottom-to-top.  Index 0 is the base card (if any).
    var cards: [Card] = []

    /// The group this foundation is currently serving, derived from the base card.
    var groupId: String? {
        cards.first?.groupId
    }

    var isEmpty: Bool { cards.isEmpty }

    /// The top card (last element), or nil if empty.
    var topCard: Card? { cards.last }
}

// MARK: - GamePhase

/// High-level state the game can be in.
enum GamePhase: String, Codable {
    case menu       /// Main menu / splash
    case playing    /// Active game in progress
    case won        /// All groups cleared — win screen shown
}

// MARK: - GameState

/// Single source of truth for an in-progress game.  Fully Codable so it can be
/// persisted to disk as JSON and restored byte-for-byte.
struct GameState: Codable, Equatable {
    // ─── Deck info ──────────────────────────────────────────────────────────
    /// The deck (groups + metadata) for the current round.
    var deck: Deck

    // ─── Piles ──────────────────────────────────────────────────────────────
    /// Stock pile — cards are face-down; only the count / order matters.
    var stock: [Card] = []

    /// Waste pile — top card (last element) is face-up and draggable.
    var waste: [Card] = []

    /// Exactly 4 foundation piles.
    var foundations: [FoundationPile] = Array(repeating: FoundationPile(), count: 4)

    /// Tableau piles.  Each pile is an ordered array of TableauCards (bottom → top).
    var tableau: [[TableauCard]] = []

    // ─── Progress ───────────────────────────────────────────────────────────
    /// Set of group IDs that have been fully completed and cleared.
    var completedGroups: Set<String> = []

    /// Running counter of total cards cleared (for stats / display).
    var clearedCardCount: Int = 0

    /// Set of partner card labels that have been placed on foundation piles.
    /// Used to prevent the same card (by label) from being placed on multiple foundation piles.
    /// Normalized to lowercase for comparison.
    var usedPartnerCardLabels: Set<String> = []

    // ─── Statistics ─────────────────────────────────────────────────────────
    /// Total number of moves made in this game.
    var moveCount: Int = 0

    /// Time when the game started (used to calculate elapsed time).
    var startTime: Date = Date()

    /// Total elapsed time in seconds (tracked when game is paused/saved).
    var elapsedTime: TimeInterval = 0

    // ─── Phase ──────────────────────────────────────────────────────────────
    var phase: GamePhase = .playing

    // ─── Undo (optional, single-level) ─────────────────────────────────────
    // TODO: Implement undo by storing previousState in GameViewModel, not here
    // (Cannot have recursive struct stored property in Swift value types)

    // MARK: - Derived

    /// True when every group in the deck has been completed.
    var isWon: Bool {
        completedGroups.count == deck.groupCount
    }

    /// Total number of cards still in play (not yet cleared).
    var cardsInPlay: Int {
        stock.count + waste.count +
        foundations.reduce(0) { $0 + $1.cards.count } +
        tableau.reduce(0) { $0 + $1.count }
    }
}

// MARK: - AppSettings

/// User-configurable settings, persisted alongside game state.
struct AppSettings: Codable {
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // Game Center statistics
    var totalWins: Int = 0
    var currentWinStreak: Int = 0
    var bestWinStreak: Int = 0
}
