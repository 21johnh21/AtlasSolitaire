import Foundation

// MARK: - MoveSource

/// Where a card is being picked up from.
enum MoveSource: Equatable {
    case stock                          /// Top of the stock pile (tap-to-draw handled separately)
    case waste                          /// Top of the waste pile
    case tableau(pileIndex: Int)        /// Top card of a specific tableau pile
    case foundation(pileIndex: Int)     /// Top card of a specific foundation pile (not used in base rules but kept for extensibility)
}

// MARK: - MoveTarget

/// Where a card is being dropped onto.
enum MoveTarget: Equatable {
    case foundation(pileIndex: Int)     /// One of the 4 foundation slots
    case tableau(pileIndex: Int)        /// One of the tableau piles
}

// MARK: - MoveValidation

/// Result of a move-validation check.
enum MoveValidation {
    case valid                          /// Move is allowed — proceed.
    case invalid(reason: String)        /// Move is not allowed — reason for UI / logging.
}

// MARK: - Rules

/// Pure, stateless rule-checking module.  All methods are static and take only the
/// data they need — no references to GameState or any view model.  Easy to unit-test.
enum Rules {

    // ─── Foundation placement ──────────────────────────────────────────────

    /// Can `card` be placed onto `foundation`?
    static func canPlaceOnFoundation(card: Card, foundation: FoundationPile) -> MoveValidation {
        if foundation.isEmpty {
            // Only base cards may open a foundation slot.
            return card.isBase ? .valid : .invalid(reason: "Only a base card can start a foundation pile.")
        }

        // Foundation is occupied — card must be a partner of the same group.
        guard let baseGroupId = foundation.groupId else {
            return .invalid(reason: "Foundation has no base card.")  // should never happen
        }

        if card.isBase {
            return .invalid(reason: "A base card cannot be placed on an occupied foundation.")
        }

        if card.groupId != baseGroupId {
            return .invalid(reason: "Card does not belong to this foundation's group.")
        }

        return .valid
    }

    // ─── Tableau placement ─────────────────────────────────────────────────

    /// Can `card` be placed onto `targetPile` in the tableau?
    /// `targetPile` may be empty (accepts any card) or have a top card.
    static func canPlaceOnTableau(card: Card, targetPile: [TableauCard]) -> MoveValidation {
        if targetPile.isEmpty {
            // Empty tableau slot accepts any card (base or partner).
            return .valid
        }

        guard let topTableauCard = targetPile.last, topTableauCard.isFaceUp else {
            return .invalid(reason: "Cannot place onto a face-down card.")
        }

        let topCard = topTableauCard.card

        // Rule 1: Cannot place a base card on top of a partner card
        if card.isBase && topCard.isPartner {
            return .invalid(reason: "Cannot place a base card on top of a partner card.")
        }

        // Rule 2: Cannot place a partner card on top of a base card
        if card.isPartner && topCard.isBase {
            return .invalid(reason: "Cannot place a partner card on top of a base card.")
        }

        // Rule 3: Partner cards can only stack on partner cards from the same group
        if card.isPartner && topCard.isPartner {
            if card.groupId == topCard.groupId {
                return .valid
            }
            return .invalid(reason: "Partner cards must be from the same group.")
        }

        // Rule 4: Base cards can stack on base cards (same group)
        if card.isBase && topCard.isBase {
            if card.groupId == topCard.groupId {
                return .valid
            }
            return .invalid(reason: "Base cards must be from the same group.")
        }

        return .invalid(reason: "Invalid tableau placement.")
    }

    // ─── Full move validation ──────────────────────────────────────────────

    /// Validate a move from `source` to `target` given the current pile layout.
    static func validate(
        card: Card,
        source: MoveSource,
        target: MoveTarget,
        foundations: [FoundationPile],
        tableau: [[TableauCard]]
    ) -> MoveValidation {
        switch target {
        case .foundation(let idx):
            guard idx >= 0, idx < foundations.count else {
                return .invalid(reason: "Foundation index out of range.")
            }
            return canPlaceOnFoundation(card: card, foundation: foundations[idx])

        case .tableau(let idx):
            guard idx >= 0, idx < tableau.count else {
                return .invalid(reason: "Tableau index out of range.")
            }
            return canPlaceOnTableau(card: card, targetPile: tableau[idx])
        }
    }

    // ─── Group completion check ────────────────────────────────────────────

    /// Check whether the group on `foundationIndex` is complete (all cards present).
    /// Returns the groupId if complete, nil otherwise.
    static func checkGroupCompletion(
        foundationIndex: Int,
        foundations: [FoundationPile],
        deck: Deck
    ) -> String? {
        let pile = foundations[foundationIndex]
        guard let groupId = pile.groupId,
              let group = deck.group(for: groupId) else { return nil }

        // A group is complete when the foundation pile contains every card in the group.
        let expectedCount = group.cards.count
        return pile.cards.count == expectedCount ? groupId : nil
    }

    // ─── Stack identification ──────────────────────────────────────────────

    /// Returns the indices of cards that form a valid movable stack starting from `startIndex`.
    /// A valid stack consists of consecutive face-up cards from the same group that can be stacked
    /// together according to tableau placement rules.
    static func getMovableStack(from pile: [TableauCard], startIndex: Int) -> [Int] {
        print("[Rules] getMovableStack called: pile count=\(pile.count), startIndex=\(startIndex)")

        guard startIndex >= 0, startIndex < pile.count else {
            print("[Rules] ❌ Invalid index: startIndex=\(startIndex), pile.count=\(pile.count)")
            return []
        }
        guard pile[startIndex].isFaceUp else {
            print("[Rules] ❌ Card at index \(startIndex) is face down")
            return []
        }

        var stackIndices = [startIndex]
        let firstCard = pile[startIndex].card
        print("[Rules] Starting card: \(firstCard.label) (type: \(firstCard.type), group: \(firstCard.groupId))")

        // Check if subsequent cards can stack on top of each other
        for i in (startIndex + 1)..<pile.count {
            let currentCard = pile[i].card
            let previousCard = pile[i - 1].card

            print("[Rules]   Checking card at index \(i): \(currentCard.label) (type: \(currentCard.type), group: \(currentCard.groupId))")

            // Card must be face-up
            guard pile[i].isFaceUp else {
                print("[Rules]   ❌ Card is face down, stopping")
                break
            }

            // Cards must be from the same group
            guard currentCard.groupId == previousCard.groupId else {
                print("[Rules]   ❌ Different group (\(currentCard.groupId) vs \(previousCard.groupId)), stopping")
                break
            }

            // Check stacking rules: same type (base-on-base or partner-on-partner)
            guard currentCard.type == previousCard.type else {
                print("[Rules]   ❌ Different type (\(currentCard.type) vs \(previousCard.type)), stopping")
                break
            }

            print("[Rules]   ✅ Card is valid, adding to stack")
            stackIndices.append(i)
        }

        print("[Rules] Final stack: \(stackIndices.count) card(s) at indices: \(stackIndices)")
        return stackIndices
    }

    // ─── Reshuffle ─────────────────────────────────────────────────────────

    /// Reshuffle is allowed whenever the stock is empty and the waste is non-empty.
    static func canReshuffle(stock: [Card], waste: [Card]) -> Bool {
        stock.isEmpty && !waste.isEmpty
    }
}
