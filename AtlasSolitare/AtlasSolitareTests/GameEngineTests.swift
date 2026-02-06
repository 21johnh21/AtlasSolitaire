import XCTest

// MARK: - GameEngineTests

/// Unit tests for the GameEngine and Rules modules.
/// All tests operate on in-memory state — no file I/O or UI involved.
final class GameEngineTests: XCTestCase {

    // ─── Helpers ────────────────────────────────────────────────────────────

    /// Build a minimal deck with the given groups (base + partners already scoped).
    private func makeDeck(groups: [Group]) -> Deck {
        Deck(id: "test_deck", name: "Test", groups: groups, seed: nil)
    }

    /// A single group with 1 base + 2 partners.
    private func sampleGroup(id: String = "grp_a") -> Group {
        Group(
            id: id,
            name: "Group \(id)",
            cards: [
                Card(id: "\(id)_base", label: "Base A", type: .base,    groupId: id, imageName: nil),
                Card(id: "\(id)_p1",   label: "P1",     type: .partner, groupId: id, imageName: nil),
                Card(id: "\(id)_p2",   label: "P2",     type: .partner, groupId: id, imageName: nil)
            ],
            metadata: nil
        )
    }

    /// An engine with an empty (just-dealt) state for the given deck.
    private func freshEngine(deck: Deck) -> GameEngine {
        let engine = GameEngine(state: GameState(deck: deck))
        engine.newGame(deck: deck)
        return engine
    }

    // ─── MARK: Rules — Foundation placement ────────────────────────────────

    func test_baseCardCanBePlacedOnEmptyFoundation() {
        let grp = sampleGroup()
        let base = grp.baseCard
        let result = Rules.canPlaceOnFoundation(card: base, foundation: FoundationPile())
        XCTAssertCase(result, is: .valid)
    }

    func test_partnerCardCannotBePlacedOnEmptyFoundation() {
        let grp = sampleGroup()
        let partner = grp.partnerCards[0]
        let result = Rules.canPlaceOnFoundation(card: partner, foundation: FoundationPile())
        XCTAssertInvalid(result)
    }

    func test_partnerCardCanBePlacedOnMatchingFoundation() {
        let grp = sampleGroup()
        let pile = FoundationPile(cards: [grp.baseCard])
        let result = Rules.canPlaceOnFoundation(card: grp.partnerCards[0], foundation: pile)
        XCTAssertCase(result, is: .valid)
    }

    func test_partnerCardCannotBePlacedOnMismatchedFoundation() {
        let grpA = sampleGroup(id: "grp_a")
        let grpB = sampleGroup(id: "grp_b")
        let pile = FoundationPile(cards: [grpA.baseCard])
        let result = Rules.canPlaceOnFoundation(card: grpB.partnerCards[0], foundation: pile)
        XCTAssertInvalid(result)
    }

    func test_baseCardCannotBePlacedOnOccupiedFoundation() {
        let grpA = sampleGroup(id: "grp_a")
        let grpB = sampleGroup(id: "grp_b")
        let pile = FoundationPile(cards: [grpA.baseCard])
        let result = Rules.canPlaceOnFoundation(card: grpB.baseCard, foundation: pile)
        XCTAssertInvalid(result)
    }

    // ─── MARK: Rules — Tableau placement ────────────────────────────────────

    func test_anyCardCanBePlacedOnEmptyTableau() {
        let grp = sampleGroup()
        let resultBase    = Rules.canPlaceOnTableau(card: grp.baseCard,    targetPile: [])
        let resultPartner = Rules.canPlaceOnTableau(card: grp.partnerCards[0], targetPile: [])
        XCTAssertCase(resultBase,    is: .valid)
        XCTAssertCase(resultPartner, is: .valid)
    }

    func test_sameGroupCardCanStackOnTableau() {
        let grp = sampleGroup()
        let pile = [TableauCard(card: grp.partnerCards[0], isFaceUp: true)]
        let result = Rules.canPlaceOnTableau(card: grp.partnerCards[1], targetPile: pile)
        XCTAssertCase(result, is: .valid)
    }

    func test_differentGroupCardCannotStackOnTableau() {
        let grpA = sampleGroup(id: "grp_a")
        let grpB = sampleGroup(id: "grp_b")
        let pile = [TableauCard(card: grpA.partnerCards[0], isFaceUp: true)]
        let result = Rules.canPlaceOnTableau(card: grpB.partnerCards[0], targetPile: pile)
        XCTAssertInvalid(result)
    }

    func test_cardCannotBePlacedOnFaceDownTopCard() {
        let grp = sampleGroup()
        let pile = [TableauCard(card: grp.partnerCards[0], isFaceUp: false)]
        let result = Rules.canPlaceOnTableau(card: grp.partnerCards[1], targetPile: pile)
        XCTAssertInvalid(result)
    }

    // ─── MARK: Rules — Reshuffle ────────────────────────────────────────────

    func test_reshuffleAvailableWhenStockEmptyAndWasteNonEmpty() {
        XCTAssertTrue(Rules.canReshuffle(stock: [], waste: [sampleGroup().baseCard]))
    }

    func test_reshuffleUnavailableWhenBothEmpty() {
        XCTAssertFalse(Rules.canReshuffle(stock: [], waste: []))
    }

    func test_reshuffleUnavailableWhenStockHasCards() {
        XCTAssertFalse(Rules.canReshuffle(stock: [sampleGroup().baseCard], waste: [sampleGroup().partnerCards[0]]))
    }

    // ─── MARK: Rules — Group completion ─────────────────────────────────────

    func test_groupCompletionDetectedWhenAllCardsOnFoundation() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let foundations = [
            FoundationPile(cards: grp.cards),  // all 3 cards
            FoundationPile(), FoundationPile(), FoundationPile()
        ]
        let result = Rules.checkGroupCompletion(foundationIndex: 0, foundations: foundations, deck: deck)
        XCTAssertEqual(result, grp.id)
    }

    func test_groupCompletionNotDetectedWhenPartiallyFilled() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let foundations = [
            FoundationPile(cards: [grp.baseCard]),  // only base
            FoundationPile(), FoundationPile(), FoundationPile()
        ]
        let result = Rules.checkGroupCompletion(foundationIndex: 0, foundations: foundations, deck: deck)
        XCTAssertNil(result)
    }

    // ─── MARK: GameEngine — draw & reshuffle ────────────────────────────────

    func test_drawFromStockMovesTopCardToWaste() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let engine = GameEngine(state: GameState(
            deck: deck,
            stock: grp.cards,   // 3 cards in stock
            waste: []
        ))
        engine.drawFromStock()

        XCTAssertEqual(engine.state.stock.count, 2)
        XCTAssertEqual(engine.state.waste.count, 1)
        XCTAssertEqual(engine.state.waste.last!.id, grp.cards.last!.id)  // top of stock → waste
    }

    func test_drawFromEmptyStockIsNoOp() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let engine = GameEngine(state: GameState(deck: deck, stock: [], waste: []))
        engine.drawFromStock()
        XCTAssertTrue(engine.state.stock.isEmpty)
        XCTAssertTrue(engine.state.waste.isEmpty)
    }

    func test_reshuffleMovesWasteToStock() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let engine = GameEngine(state: GameState(deck: deck, stock: [], waste: grp.cards))
        engine.reshuffle()

        XCTAssertEqual(engine.state.stock.count, 3)
        XCTAssertTrue(engine.state.waste.isEmpty)
    }

    // ─── MARK: GameEngine — move ────────────────────────────────────────────

    func test_validMoveFromWasteToEmptyFoundation() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let engine = GameEngine(state: GameState(
            deck: deck,
            stock: [],
            waste: [grp.baseCard],
            foundations: [FoundationPile(), FoundationPile(), FoundationPile(), FoundationPile()],
            tableau: [[], [], [], []]
        ))

        let result = engine.move(card: grp.baseCard, source: .waste, target: .foundation(pileIndex: 0))
        XCTAssertCase(result, is: .valid)
        XCTAssertTrue(engine.state.waste.isEmpty)
        XCTAssertEqual(engine.state.foundations[0].cards.count, 1)
    }

    func test_invalidMoveReturnsInvalid() {
        let grpA = sampleGroup(id: "grp_a")
        let grpB = sampleGroup(id: "grp_b")
        let deck = makeDeck(groups: [grpA, grpB])
        let engine = GameEngine(state: GameState(
            deck: deck,
            stock: [],
            waste: [grpB.partnerCards[0]],
            foundations: [FoundationPile(cards: [grpA.baseCard]), FoundationPile(), FoundationPile(), FoundationPile()],
            tableau: [[], [], [], []]
        ))

        let result = engine.move(card: grpB.partnerCards[0], source: .waste, target: .foundation(pileIndex: 0))
        XCTAssertInvalid(result)
        // Card should still be in waste.
        XCTAssertEqual(engine.state.waste.count, 1)
    }

    // ─── MARK: GameEngine — win detection ──────────────────────────────────

    func test_winDetectedWhenAllGroupsCompleted() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        var winCalled = false

        let engine = GameEngine(state: GameState(
            deck: deck,
            stock: [],
            waste: [grp.partnerCards[1]],  // last partner to place
            foundations: [
                FoundationPile(cards: [grp.baseCard, grp.partnerCards[0]]),  // base + p1
                FoundationPile(), FoundationPile(), FoundationPile()
            ],
            tableau: [[], [], [], []]
        ))
        engine.onWin = { winCalled = true }

        // Place the last partner → should complete the group → win.
        let result = engine.move(card: grp.partnerCards[1], source: .waste, target: .foundation(pileIndex: 0))
        XCTAssertCase(result, is: .valid)
        XCTAssertTrue(winCalled)
        XCTAssertEqual(engine.state.phase, .won)
    }

    // ─── MARK: GameEngine — newGame deals correctly ────────────────────────

    func test_newGameDealsAllCards() {
        let grp  = sampleGroup()
        let deck = makeDeck(groups: [grp])
        let engine = freshEngine(deck: deck)

        let totalDealt = engine.state.stock.count +
                         engine.state.waste.count +
                         engine.state.foundations.reduce(0) { $0 + $1.cards.count } +
                         engine.state.tableau.reduce(0) { $0 + $1.count }

        XCTAssertEqual(totalDealt, deck.allCards.count)
    }

    func test_newGameTopCardsAreFaceUp() {
        let grpA = sampleGroup(id: "grp_a")
        let grpB = sampleGroup(id: "grp_b")
        let deck = makeDeck(groups: [grpA, grpB])
        let engine = freshEngine(deck: deck)

        for pile in engine.state.tableau where !pile.isEmpty {
            XCTAssertTrue(pile.last!.isFaceUp, "Top card of each tableau pile must be face-up")
        }
    }

    // ─── MARK: Helpers ──────────────────────────────────────────────────────

    private func XCTAssertCase(_ result: MoveValidation, is expected: MoveValidation, file: StaticString = #file, line: UInt = #line) {
        switch (result, expected) {
        case (.valid, .valid):             break
        case (.invalid, .invalid):         break
        default: XCTFail("Expected \(expected) but got \(result)", file: file, line: line)
        }
    }

    private func XCTAssertInvalid(_ result: MoveValidation, file: StaticString = #file, line: UInt = #line) {
        if case .invalid = result { return }
        XCTFail("Expected .invalid but got \(result)", file: file, line: line)
    }
}
