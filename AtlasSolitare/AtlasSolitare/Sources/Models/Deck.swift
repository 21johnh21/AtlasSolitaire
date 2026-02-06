import Foundation

// MARK: - DeckDefinition

/// The on-disk JSON representation of a deck file.
struct DeckDefinition: Codable {
    let deckId: String
    let deckName: String
    /// Group IDs to include (references into the groups/ folder).
    let groups: [String]
    /// Optional seed for reproducible shuffles; nil = random each time.
    let shuffleSeed: UInt64?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case deckId     = "deck_id"
        case deckName   = "deck_name"
        case groups
        case shuffleSeed = "shuffle_seed"
        case metadata
    }
}

// MARK: - Deck (runtime)

/// A resolved, runtime deck: the concrete set of groups chosen for this round
/// together with all their cards.
struct Deck: Identifiable, Codable, Equatable {
    let id: String              /// Unique deck identifier (may be generated per round)
    let name: String            /// Display name
    let groups: [Group]         /// The resolved groups for this round
    let seed: UInt64?           /// Shuffle seed (nil if unseeded)

    /// Flat list of every card across all groups in this deck.
    var allCards: [Card] {
        groups.flatMap { $0.cards }
    }

    /// Total number of distinct groups.
    var groupCount: Int { groups.count }

    /// Look up a group by its id.
    func group(for groupId: String) -> Group? {
        groups.first(where: { $0.id == groupId })
    }
}
