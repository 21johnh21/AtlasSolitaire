import XCTest

// MARK: - DeckManagerTests

/// Unit tests for DeckManager and the GroupDataSource abstraction.
/// Uses a mock data source so no bundle / file-system access is needed.
final class DeckManagerTests: XCTestCase {

    // ─── Mock data source ───────────────────────────────────────────────────

    /// In-memory GroupDataSource for tests.
    private class MockGroupDataSource: GroupDataSource {
        let groups: [GroupDefinition]
        let decks:  [String: DeckDefinition]

        init(groups: [GroupDefinition] = [], decks: [String: DeckDefinition] = [:]) {
            self.groups = groups
            self.decks  = decks
        }

        func loadAllGroups() throws -> [GroupDefinition] { groups }
        func loadDeck(id: String) throws -> DeckDefinition? { decks[id] }
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    /// Create a minimal GroupDefinition.
    private func makeGroupDef(id: String, partnerCount: Int = 2) -> GroupDefinition {
        let partners = (0..<partnerCount).map { i in
            RawGroupCard(id: "p\(i)", label: "Partner \(i)", type: .partner, image: nil)
        }
        return GroupDefinition(
            groupId: id,
            groupName: "Group \(id)",
            baseCard: RawGroupCard(id: "base", label: "Base \(id)", type: .base, image: nil),
            partnerCards: partners,
            metadata: nil
        )
    }

    // ─── MARK: buildRandomDeck ──────────────────────────────────────────────

    func test_buildRandomDeck_returnsAllGroups_whenCountIsNil() throws {
        let defs = [makeGroupDef(id: "a"), makeGroupDef(id: "b"), makeGroupDef(id: "c")]
        let source = MockGroupDataSource(groups: defs)
        let manager = DeckManager(dataSource: source)

        let deck = try manager.buildRandomDeck(groupCount: nil)
        XCTAssertEqual(deck.groups.count, 3)
    }

    func test_buildRandomDeck_returnsRequestedSubset() throws {
        let defs = [makeGroupDef(id: "a"), makeGroupDef(id: "b"), makeGroupDef(id: "c")]
        let source = MockGroupDataSource(groups: defs)
        let manager = DeckManager(dataSource: source)

        let deck = try manager.buildRandomDeck(groupCount: 2)
        XCTAssertEqual(deck.groups.count, 2)
    }

    func test_buildRandomDeck_throwsWhenNoGroups() throws {
        let source = MockGroupDataSource(groups: [])
        let manager = DeckManager(dataSource: source)

        await XCTAssertThrowsErrorAsync {
            _ = try manager.buildRandomDeck()
        }
    }

    func test_buildRandomDeck_throwsWhenRequestedMoreThanAvailable() throws {
        let defs = [makeGroupDef(id: "a")]
        let source = MockGroupDataSource(groups: defs)
        let manager = DeckManager(dataSource: source)

        do {
            _ = try manager.buildRandomDeck(groupCount: 5)
            XCTFail("Should have thrown insufficientGroups")
        } catch DeckManagerError.insufficientGroups {
            // expected
        }
    }

    func test_buildRandomDeck_deduplicatesGroups() throws {
        // Two definitions with the same group_id.
        let defs = [makeGroupDef(id: "dup"), makeGroupDef(id: "dup"), makeGroupDef(id: "other")]
        let source = MockGroupDataSource(groups: defs)
        let manager = DeckManager(dataSource: source)

        let deck = try manager.buildRandomDeck(groupCount: nil)
        // Should deduplicate to 2 unique groups.
        XCTAssertEqual(deck.groups.count, 2)
    }

    func test_buildRandomDeck_seededShuffleIsReproducible() throws {
        let defs = (0..<10).map { makeGroupDef(id: "g\($0)") }
        let source = MockGroupDataSource(groups: defs)
        let manager = DeckManager(dataSource: source)

        let deck1 = try manager.buildRandomDeck(groupCount: 5, seed: 42)
        let deck2 = try manager.buildRandomDeck(groupCount: 5, seed: 42)

        let ids1 = deck1.groups.map { $0.id }
        let ids2 = deck2.groups.map { $0.id }
        XCTAssertEqual(ids1, ids2, "Same seed should produce same group selection order")
    }

    // ─── MARK: buildDeck(fromDefinition:) ───────────────────────────────────

    func test_buildDeck_fromDefinition_resolvesGroups() throws {
        let grpDefs = [makeGroupDef(id: "a"), makeGroupDef(id: "b"), makeGroupDef(id: "c")]
        let deckDef = DeckDefinition(
            deckId: "test_deck",
            deckName: "Test",
            groups: ["a", "c"],       // only a and c
            shuffleSeed: nil,
            metadata: nil
        )
        let source = MockGroupDataSource(groups: grpDefs, decks: ["test_deck": deckDef])
        let manager = DeckManager(dataSource: source)

        let deck = try manager.buildDeck(fromDefinition: "test_deck")
        XCTAssertEqual(deck.groups.count, 2)
        XCTAssertTrue(deck.groups.contains(where: { $0.id == "a" }))
        XCTAssertTrue(deck.groups.contains(where: { $0.id == "c" }))
    }

    func test_buildDeck_fromDefinition_throwsWhenDeckNotFound() throws {
        let source = MockGroupDataSource(groups: [], decks: [:])
        let manager = DeckManager(dataSource: source)

        do {
            _ = try manager.buildDeck(fromDefinition: "missing")
            XCTFail("Should have thrown noDeckDefinition")
        } catch DeckManagerError.noDeckDefinition {
            // expected
        }
    }

    // ─── MARK: GroupDefinition → Group conversion ──────────────────────────

    func test_groupDefinition_toCards_scopesIds() {
        let def = makeGroupDef(id: "europe_01")
        let cards = def.toCards()

        // Base card id should be "europe_01_base"
        XCTAssertEqual(cards[0].id, "europe_01_base")
        XCTAssertEqual(cards[0].type, .base)
        XCTAssertEqual(cards[0].groupId, "europe_01")

        // Partners should be "europe_01_p0", "europe_01_p1"
        XCTAssertEqual(cards[1].id, "europe_01_p0")
        XCTAssertEqual(cards[2].id, "europe_01_p1")
    }

    func test_groupDefinition_cardCount() {
        let def = makeGroupDef(id: "x", partnerCount: 5)
        XCTAssertEqual(def.cardCount, 6)  // 1 base + 5 partners
    }

    // ─── MARK: Runtime Group ────────────────────────────────────────────────

    func test_group_baseCard_returnsCorrectCard() {
        let def = makeGroupDef(id: "grp")
        let group = Group(from: def)
        XCTAssertEqual(group.baseCard.type, .base)
        XCTAssertEqual(group.baseCard.groupId, "grp")
    }

    func test_group_partnerCards_excludesBase() {
        let def = makeGroupDef(id: "grp", partnerCount: 3)
        let group = Group(from: def)
        XCTAssertEqual(group.partnerCards.count, 3)
        XCTAssertTrue(group.partnerCards.allSatisfy { $0.type == .partner })
    }

    // ─── Async helper ───────────────────────────────────────────────────────

    /// Convenience: assert that a synchronous throwing closure throws.
    private func XCTAssertThrowsErrorAsync(_ block: () throws -> Void) async {
        do {
            try block()
            XCTFail("Expected an error to be thrown")
        } catch {
            // expected
        }
    }
}
