import Foundation

// MARK: - GroupDataSource (protocol for future API migration)

/// Abstraction over where group/deck definitions come from.
/// Implement `RemoteAPIDataSource` later to swap in a network backend.
protocol GroupDataSource {
    /// Load all group definitions available from this source.
    func loadAllGroups() throws -> [GroupDefinition]

    /// Load a specific deck definition by id.
    func loadDeck(id: String) throws -> DeckDefinition?
}

// MARK: - LocalJSONDataSource

/// Reads group and deck JSON files from the app's bundle.
class LocalJSONDataSource: GroupDataSource {
    private let groupsFolder: String
    private let decksFolder: String

    init(groupsFolder: String = "groups", decksFolder: String = "decks") {
        self.groupsFolder = groupsFolder
        self.decksFolder  = decksFolder
    }

    func loadAllGroups() throws -> [GroupDefinition] {
        // List of known group IDs (hardcoded for now; could be dynamic later)
        let groupIds = [
            "europe_countries_01",
            "island_nations_01",
            "us_states_01",
            "national_capitals_01",
            "cities_in_uk_01",
            "great_lakes_01",
            "mountain_ranges_01",
            "continents_01",
            "caribbean_islands_01",
            "us_national_parks_01",
            "canadian_provinces_01",
            "seven_wonders_01",
            "african_great_lakes_01",
            "rivers_of_africa_01",
            "cities_of_mexico_01",
            "cities_of_brazil_01",
            "cities_of_south_africa_01",
            "cities_of_australia_01",
            "cities_of_china_01",
            "cities_of_india_01",
            "g7_countries_01",
            "rocky_mountains_01",
            "islands_of_hawaii_01",
            "islands_of_japan_01",
            "russian_oblasts_01",
            "former_ussr_01",
            "us_territories_01",
            "florida_keys_01",
            "cities_of_colorado_01",
            "boroughs_of_new_york_01",
            "landlocked_countries_01",
            "utc_zero_countries_01",
            "stan_countries_01",
            "deserts_of_the_world_01",
            "longest_rivers_01",
            "archipelagos_01",
            "danube_capitals_01",
            "countries_with_monarchies_01",
            "arctic_nations_01",
            "high_altitude_cities_01",
            "himalayan_countries_01",
            "seven_summits_01",
            "route_66_cities_01",
            "castles_of_england_01",
            "winter_olympic_hosts_01",
            "summer_olympic_hosts_01",
            "gulf_countries_01",
            "mediterranean_islands_01",
            "emirates_of_uae_01",
            "mountain_ranges_europe_01",
            "regions_of_spain_01",
            "famous_train_stations_01",
            "tiger_countries_01",
            "state_residences_01",
            "germany_neighbors_01",
            "drc_neighbors_01",
            "african_national_parks_01",
            "andes_countries_01"
        ]

        var definitions: [GroupDefinition] = []
        for groupId in groupIds {
            guard let url = Bundle.main.url(forResource: groupId, withExtension: "json") else {
                continue  // Skip if not found
            }
            let data = try Data(contentsOf: url)
            let definition = try JSONDecoder().decode(GroupDefinition.self, from: data)
            definitions.append(definition)
        }

        guard !definitions.isEmpty else {
            throw DeckManagerError.noGroupsFound
        }

        return definitions
    }

    func loadDeck(id: String) throws -> DeckDefinition? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "json") else {
            return nil  // Deck file not found
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DeckDefinition.self, from: data)
    }
}

// MARK: - DeckManagerError

enum DeckManagerError: Error, LocalizedError {
    case bundleNotFound
    case folderNotFound(String)
    case noDeckDefinition(String)
    case noGroupsFound
    case insufficientGroups(available: Int, requested: Int)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:                        return "App bundle resource path is nil."
        case .folderNotFound(let path):              return "Folder not found: \(path)"
        case .noDeckDefinition(let id):              return "No deck definition found for id: \(id)"
        case .noGroupsFound:                         return "No group JSON files were found."
        case .insufficientGroups(let a, let r):      return "Only \(a) groups available; \(r) requested."
        }
    }
}

// MARK: - DeckManager

/// Orchestrates loading group definitions, selecting a subset for a round,
/// and producing a fully-resolved runtime `Deck`.
class DeckManager {
    let dataSource: GroupDataSource

    init(dataSource: GroupDataSource = LocalJSONDataSource()) {
        self.dataSource = dataSource
    }

    // ─── Build a randomised deck ────────────────────────────────────────────

    /// Load all available groups and randomly select `count` of them.
    /// If `count` is nil, all available groups are used.
    /// `seed` controls the selection RNG for reproducibility.
    func buildRandomDeck(groupCount count: Int? = nil, seed: UInt64? = nil) throws -> Deck {
        let definitions = try dataSource.loadAllGroups()
        guard !definitions.isEmpty else { throw DeckManagerError.noGroupsFound }

        // Deduplicate by group_id (in case of duplicate files).
        var seen = Set<String>()
        let unique = definitions.filter { seen.insert($0.groupId).inserted }

        let requested = count ?? unique.count
        guard requested <= unique.count else {
            throw DeckManagerError.insufficientGroups(available: unique.count, requested: requested)
        }

        // Shuffle definitions with optional seed.
        var shuffled = unique
        if var rng = seed.map({ SeededRNG(seed: $0) }) {
            shuffled.shuffle(using: &rng)
        } else {
            shuffled.shuffle()
        }

        let selected = Array(shuffled.prefix(requested))
        let groups = selected.map { Group(from: $0) }

        var deck = Deck(
            id:     "round_\(Int.random(in: 100000...999999))",
            name:   "Randomized Round",
            groups: groups,
            seed:   seed
        )

        // Populate possibleGroupIds by finding cards with matching labels across groups
        deck.populatePossibleGroupIds()

        return deck
    }

    // ─── Build deck from a deck definition file ────────────────────────────

    /// Load a named deck definition and resolve it into a runtime Deck.
    func buildDeck(fromDefinition id: String) throws -> Deck {
        guard let deckDef = try dataSource.loadDeck(id: id) else {
            throw DeckManagerError.noDeckDefinition(id)
        }

        let allDefinitions = try dataSource.loadAllGroups()
        let defMap = Dictionary(uniqueKeyed: allDefinitions.map { ($0.groupId, $0) })

        let groups = deckDef.groups.compactMap { groupId -> Group? in
            guard let def = defMap[groupId] else { return nil }
            return Group(from: def)
        }

        var deck = Deck(
            id:     deckDef.deckId,
            name:   deckDef.deckName,
            groups: groups,
            seed:   deckDef.shuffleSeed
        )

        // Populate possibleGroupIds by finding cards with matching labels across groups
        deck.populatePossibleGroupIds()

        return deck
    }
}

// MARK: - Dictionary helper

private extension Dictionary {
    /// Build a dictionary from an array of (key, value) pairs, keeping the last value
    /// for duplicate keys.
    init(uniqueKeyed pairs: [(Key, Value)]) {
        self.init()
        for (k, v) in pairs { self[k] = v }
    }
}
