import Foundation

// MARK: - GroupMetadata

/// Freeform metadata block from the JSON definition.  All fields optional so that
/// any subset of keys can be present without breaking decoding.
struct GroupMetadata: Codable, Equatable {
    var difficulty: String?
    var source: String?
    var continent: String?
    var category: String?
    var country: String?
    var notes: String?

    // Accept any unknown keys gracefully.
    private var extra: [String: String] = [:]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        difficulty  = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("difficulty"))
        source      = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("source"))
        continent   = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("continent"))
        category    = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("category"))
        country     = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("country"))
        notes       = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("notes"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(source,     forKey: .source)
        try container.encodeIfPresent(continent,  forKey: .continent)
        try container.encodeIfPresent(category,   forKey: .category)
        try container.encodeIfPresent(country,    forKey: .country)
        try container.encodeIfPresent(notes,      forKey: .notes)
    }

    enum CodingKeys: String, CodingKey {
        case difficulty, source, continent, category, country, notes
    }
}

/// A helper CodingKey that wraps an arbitrary string so we can decode unknown keys.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

// MARK: - RawGroupCard

/// The shape of a card as it appears in the group JSON file (before runtime scoping).
struct RawGroupCard: Codable {
    let id: String
    let label: String
    let type: CardType
    let image: String?
}

// MARK: - GroupDefinition

/// The full on-disk representation of a group JSON file.
/// Decoded first; then converted to runtime `Card` objects via `toCards()`.
struct GroupDefinition: Codable {
    let groupId: String
    let groupName: String
    let baseCard: RawGroupCard
    let partnerCards: [RawGroupCard]
    let metadata: GroupMetadata?

    enum CodingKeys: String, CodingKey {
        case groupId    = "group_id"
        case groupName  = "group_name"
        case baseCard   = "base_card"
        case partnerCards = "partner_cards"
        case metadata
    }

    // MARK: - Conversion to runtime Cards

    /// Convert this definition into a flat array of runtime `Card` values,
    /// with ids scoped by `groupId` to guarantee uniqueness.
    func toCards() -> [Card] {
        let base = Card(
            id:        "\(groupId)_\(baseCard.id)",
            label:     baseCard.label,
            type:      .base,
            groupId:   groupId,
            imageName: baseCard.image
        )
        let partners = partnerCards.map { raw in
            Card(
                id:        "\(groupId)_\(raw.id)",
                label:     raw.label,
                type:      .partner,
                groupId:   groupId,
                imageName: raw.image
            )
        }
        return [base] + partners
    }

    /// Total number of cards in this group (base + partners).
    var cardCount: Int { 1 + partnerCards.count }
}

// MARK: - Group (runtime)

/// A resolved group at runtime — holds the already-scoped Card objects.
struct Group: Identifiable, Codable, Equatable {
    let id: String          /// == groupId
    let name: String        /// Human-readable group name
    let cards: [Card]       /// All cards (base first, then partners)
    let metadata: GroupMetadata?

    /// The single base card for this group.
    var baseCard: Card {
        cards.first(where: { $0.isBase })!
    }

    /// All partner cards in this group.
    var partnerCards: [Card] {
        cards.filter { $0.isPartner }
    }

    /// Build a runtime Group from a decoded GroupDefinition.
    init(from definition: GroupDefinition) {
        self.id       = definition.groupId
        self.name     = definition.groupName
        self.cards    = definition.toCards()
        self.metadata = definition.metadata
    }

    // Full memberwise init (used by persistence / tests).
    init(id: String, name: String, cards: [Card], metadata: GroupMetadata?) {
        self.id       = id
        self.name     = name
        self.cards    = cards
        self.metadata = metadata
    }
}
