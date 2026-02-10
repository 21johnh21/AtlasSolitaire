import Foundation

// MARK: - GameEngine

/// Stateful game engine.  Owns a mutable `GameState` and exposes high-level
/// operations (draw, move, reshuffle, newGame).  All mutation goes through this
/// class so the ViewModel can observe changes and trigger UI updates.
///
/// The engine is **not** an ObservableObject itself — the ViewModel wraps it and
/// publishes state.  This keeps the engine testable without SwiftUI.
class GameEngine {

    // ─── State ──────────────────────────────────────────────────────────────
    var state: GameState

    // ─── Callbacks (injected by ViewModel) ─────────────────────────────────
    /// Called after any state mutation so the ViewModel can re-publish.
    var onStateChanged: (() -> Void)?

    /// Called when a group is completed and cleared.  Passes the groupId.
    var onGroupCompleted: ((String) -> Void)?

    /// Called when the player wins.
    var onWin: (() -> Void)?

    // ─── Init ───────────────────────────────────────────────────────────────
    init(state: GameState) {
        self.state = state
        // Rebuild the usedPartnerCardLabels set from the current game state
        rebuildUsedCardLabels()
    }

    /// Rebuild the usedPartnerCardLabels set by scanning all visible cards in play.
    /// This is called on initialization to ensure the set is correct when loading a saved game.
    private func rebuildUsedCardLabels() {
        var usedLabels = Set<String>()

        // Scan foundation piles
        for foundation in state.foundations {
            for card in foundation.cards {
                if card.isPartner {
                    let normalizedLabel = card.label.lowercased().trimmingCharacters(in: .whitespaces)
                    usedLabels.insert(normalizedLabel)
                }
            }
        }

        // Scan tableau piles (only face-up cards)
        for pile in state.tableau {
            for tableauCard in pile where tableauCard.isFaceUp {
                if tableauCard.card.isPartner {
                    let normalizedLabel = tableauCard.card.label.lowercased().trimmingCharacters(in: .whitespaces)
                    usedLabels.insert(normalizedLabel)
                }
            }
        }

        // Scan waste pile (all cards visible)
        for card in state.waste {
            if card.isPartner {
                let normalizedLabel = card.label.lowercased().trimmingCharacters(in: .whitespaces)
                usedLabels.insert(normalizedLabel)
            }
        }

        state.usedPartnerCardLabels = usedLabels
    }

    // ─── MARK: Public Operations ────────────────────────────────────────────

    /// Draw the top card from the stock onto the waste.
    /// If the stock is empty this is a no-op (caller should check `canReshuffle`).
    func drawFromStock() {
        guard let card = state.stock.popLast() else { return }
        state.waste.append(card)
        state.moveCount += 1
        notifyChanged()
    }

    /// Reshuffle: move all waste cards back into the stock in random order.
    /// Unlimited reshuffles allowed per spec.
    func reshuffle() {
        guard Rules.canReshuffle(stock: state.stock, waste: state.waste) else { return }
        state.stock = state.waste.shuffled()
        state.waste.removeAll()
        state.moveCount += 1
        notifyChanged()
    }

    /// Attempt to move a card from `source` to `target`.
    /// Returns the validation result so the caller (ViewModel) can trigger
    /// the appropriate haptic / sound.
    @discardableResult
    func move(card: Card, source: MoveSource, target: MoveTarget) -> MoveValidation {
        let validation = Rules.validate(
            card: card,
            source: source,
            target: target,
            foundations: state.foundations,
            tableau: state.tableau,
            usedCardLabels: state.usedPartnerCardLabels
        )

        switch validation {
        case .invalid:
            return validation   // caller handles feedback

        case .valid:
            // 1. Remove card from source.
            removeCard(from: source)

            // 2. Place card at target.
            placeCard(card, at: target)

            // 3. If placing a partner card anywhere (foundation or tableau), track it as used
            if card.isPartner {
                let normalizedLabel = card.label.lowercased().trimmingCharacters(in: .whitespaces)
                state.usedPartnerCardLabels.insert(normalizedLabel)
            }

            // 4. Reveal new top card in tableau if source was tableau.
            if case .tableau(let idx) = source {
                revealTopCard(in: idx)
            }

            // 5. Check for group completion on foundations.
            if case .foundation(let idx) = target {
                checkAndClearGroup(at: idx)
            }

            // 6. Increment move count.
            state.moveCount += 1

            notifyChanged()
            return .valid
        }
    }

    /// Attempt to move a stack of cards from `source` to `target`.
    /// Validates that the first card can be placed, then moves all cards in order.
    @discardableResult
    func moveStack(cards: [Card], source: MoveSource, target: MoveTarget) -> MoveValidation {
        print("[GameEngine] moveStack called: \(cards.count) card(s)")
        for (i, card) in cards.enumerated() {
            print("[GameEngine]   Card \(i): \(card.label) (type: \(card.type), group: \(card.groupId))")
        }

        guard let firstCard = cards.first else {
            print("[GameEngine] ❌ No cards to move")
            return .invalid(reason: "No cards to move")
        }

        // Only allow moving stacks to tableau (not foundation)
        guard case .tableau = target else {
            print("[GameEngine] ❌ Target is not tableau")
            return .invalid(reason: "Stacks can only be moved to tableau piles")
        }

        print("[GameEngine] Validating first card placement...")
        // Validate the first card can be placed
        let validation = Rules.validate(
            card: firstCard,
            source: source,
            target: target,
            foundations: state.foundations,
            tableau: state.tableau,
            usedCardLabels: state.usedPartnerCardLabels
        )

        switch validation {
        case .invalid(let reason):
            print("[GameEngine] ❌ Validation failed: \(reason)")
            return validation

        case .valid:
            print("[GameEngine] ✅ Validation passed, moving \(cards.count) card(s)")
            // Remove all cards from source
            for (i, _) in cards.enumerated() {
                removeCard(from: source)
                print("[GameEngine]   Removed card \(i) from source")
            }

            // Place all cards at target in order
            for (i, card) in cards.enumerated() {
                placeCard(card, at: target)
                print("[GameEngine]   Placed card \(i): \(card.label) at target")

                // Track partner cards as used
                if card.isPartner {
                    let normalizedLabel = card.label.lowercased().trimmingCharacters(in: .whitespaces)
                    state.usedPartnerCardLabels.insert(normalizedLabel)
                }
            }

            // Reveal new top card in tableau if source was tableau
            if case .tableau(let idx) = source {
                print("[GameEngine] Revealing top card in source pile \(idx)")
                revealTopCard(in: idx)
            }

            // Increment move count
            state.moveCount += 1

            notifyChanged()
            print("[GameEngine] ✅ Stack move complete")
            return .valid
        }
    }

    /// Attempt to move a stack of cards from `source` to a foundation pile.
    /// All cards must be valid for the foundation and will be added in sequence.
    @discardableResult
    func moveStackToFoundation(cards: [Card], source: MoveSource, foundationIndex: Int) -> MoveValidation {
        print("[GameEngine] moveStackToFoundation called: \(cards.count) card(s) to foundation \(foundationIndex)")
        for (i, card) in cards.enumerated() {
            print("[GameEngine]   Card \(i): \(card.label) (type: \(card.type), group: \(card.groupId))")
        }

        guard !cards.isEmpty else {
            print("[GameEngine] ❌ No cards to move")
            return .invalid(reason: "No cards to move")
        }

        guard foundationIndex >= 0, foundationIndex < state.foundations.count else {
            print("[GameEngine] ❌ Invalid foundation index")
            return .invalid(reason: "Invalid foundation index")
        }

        // Validate each card can be placed on the foundation in sequence
        var tempFoundation = state.foundations[foundationIndex]
        for (i, card) in cards.enumerated() {
            let validation = Rules.canPlaceOnFoundation(card: card, foundation: tempFoundation)
            if case .invalid(let reason) = validation {
                print("[GameEngine] ❌ Card \(i) (\(card.label)) cannot be placed: \(reason)")
                return validation
            }
            // Simulate adding the card to check the next one
            tempFoundation.cards.append(card)
        }

        print("[GameEngine] ✅ All cards validated, moving \(cards.count) card(s)")

        // Remove all cards from source
        for (i, _) in cards.enumerated() {
            removeCard(from: source)
            print("[GameEngine]   Removed card \(i) from source")
        }

        // Place all cards at foundation in order
        for (i, card) in cards.enumerated() {
            state.foundations[foundationIndex].cards.append(card)
            print("[GameEngine]   Placed card \(i): \(card.label) at foundation")

            // Track partner cards as used
            if card.isPartner {
                let normalizedLabel = card.label.lowercased().trimmingCharacters(in: .whitespaces)
                state.usedPartnerCardLabels.insert(normalizedLabel)
            }
        }

        // Reveal new top card in tableau if source was tableau
        if case .tableau(let idx) = source {
            print("[GameEngine] Revealing top card in source pile \(idx)")
            revealTopCard(in: idx)
        }

        // Increment move count
        state.moveCount += 1

        // Check for group completion
        checkAndClearGroup(at: foundationIndex)

        notifyChanged()
        print("[GameEngine] ✅ Stack move to foundation complete")
        return .valid
    }

    /// Start a brand new game from a given deck.  Deals cards Klondike-style.
    func newGame(deck: Deck, seed: UInt64? = nil) {
        var allCards = deck.allCards

        // Shuffle
        if let seed = seed {
            var rng = SeededRNG(seed: seed)
            allCards.shuffle(using: &rng)
        } else {
            allCards.shuffle()
        }

        // Deal tableau: pile 0 gets 1 card, pile 1 gets 2, etc.
        let tableauCount = 4
        var tableau: [[TableauCard]] = Array(repeating: [], count: tableauCount)
        var idx = 0
        for pile in 0..<tableauCount {
            for row in 0...pile {
                guard idx < allCards.count else { break }
                let isFaceUp = (row == pile)  // only the last card in each pile is face-up
                tableau[pile].append(TableauCard(card: allCards[idx], isFaceUp: isFaceUp))
                idx += 1
            }
        }

        // Remaining cards go to stock (face-down).
        let stock = Array(allCards[idx...])

        state = GameState(
            deck:             deck,
            stock:            stock,
            waste:            [],
            foundations:      Array(repeating: FoundationPile(), count: 4),
            tableau:          tableau,
            completedGroups:  [],
            clearedCardCount: 0,
            phase:            .playing
        )

        notifyChanged()
    }

    // ─── MARK: Private Helpers ──────────────────────────────────────────────

    private func removeCard(from source: MoveSource) {
        switch source {
        case .waste:
            state.waste.removeLast()
        case .tableau(let idx):
            state.tableau[idx].removeLast()
        case .foundation(let idx):
            state.foundations[idx].cards.removeLast()
        case .stock:
            state.stock.removeLast()
        }
    }

    private func placeCard(_ card: Card, at target: MoveTarget) {
        switch target {
        case .foundation(let idx):
            state.foundations[idx].cards.append(card)
        case .tableau(let idx):
            state.tableau[idx].append(TableauCard(card: card, isFaceUp: true))
        }
    }

    /// If the top card of a tableau pile is face-down, flip it face-up.
    private func revealTopCard(in pileIndex: Int) {
        guard let last = state.tableau[pileIndex].indices.last else { return }
        if !state.tableau[pileIndex][last].isFaceUp {
            state.tableau[pileIndex][last].isFaceUp = true
        }
    }

    /// Check if the group on the given foundation is complete; if so, clear it.
    private func checkAndClearGroup(at foundationIndex: Int) {
        guard let completedGroupId = Rules.checkGroupCompletion(
            foundationIndex: foundationIndex,
            foundations: state.foundations,
            deck: state.deck
        ) else { return }

        // Clear the foundation pile.
        let clearedCount = state.foundations[foundationIndex].cards.count
        state.foundations[foundationIndex].cards.removeAll()
        state.completedGroups.insert(completedGroupId)
        state.clearedCardCount += clearedCount

        // Reveal any newly exposed tableau cards after clearing.
        for i in state.tableau.indices {
            revealTopCard(in: i)
        }

        // Notify group-level callback.
        onGroupCompleted?(completedGroupId)

        // Check win.
        if state.isWon {
            state.phase = .won
            onWin?()
        }
    }

    private func notifyChanged() {
        onStateChanged?()
    }
}

// MARK: - SeededRNG

/// A simple seeded random-number generator for reproducible shuffles.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
