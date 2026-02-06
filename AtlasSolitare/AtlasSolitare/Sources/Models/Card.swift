import Foundation

// MARK: - CardType

/// The role a card plays within its group.
enum CardType: String, Codable, CaseIterable {
    case base    /// The "header" card for a group — must be placed on an empty foundation.
    case partner /// A member card — placed onto the matching base in foundation or same-group cards in tableau.
}

// MARK: - Card

/// A single playable card.  `id` is guaranteed unique at runtime (scoped by groupId
/// in DeckManager) even though the raw JSON id may collide across groups.
struct Card: Identifiable, Codable, Equatable, Hashable {
    /// Runtime-unique identifier (format: `<groupId>_<rawId>`).
    let id: String

    /// Human-readable display label (e.g. "France").
    let label: String

    /// Whether this card is the group base or a partner.
    let type: CardType

    /// The group this card belongs to.  Used for all rule checks.
    let groupId: String

    /// Optional path/name of an image asset (nil until images are added).
    let imageName: String?

    // MARK: - Codable

    /// Keys that appear in the on-disk JSON (raw, before scoping).
    private enum RawCodingKeys: String, CodingKey {
        case id, label, type, image
    }

    /// Keys used when the card is serialised as part of persisted game state
    /// (already-scoped id, plus groupId).
    enum CodingKeys: String, CodingKey {
        case id, label, type, groupId, imageName
    }

    // MARK: - Helpers

    /// Whether this card is a base card.
    var isBase: Bool { type == .base }

    /// Whether this card is a partner card.
    var isPartner: Bool { type == .partner }
}

// MARK: - TableauCard

/// A card together with its face-up / face-down state as it sits in a tableau pile.
struct TableauCard: Identifiable, Codable, Equatable {
    let card: Card
    var isFaceUp: Bool

    var id: String { card.id }
}
