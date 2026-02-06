import Foundation

// MARK: - PersistenceManager

/// Handles saving and loading GameState and AppSettings to / from disk.
/// Writes a single JSON file into the app's Application Support directory.
class PersistenceManager {

    // ─── File paths ─────────────────────────────────────────────────────────
    private static let appSupportDir: URL = {
        FileManager.default.applicationSupportDirectory
    }()

    private static let gameStateURL = appSupportDir.appendingPathComponent("atlas_game_state.json")
    private static let settingsURL  = appSupportDir.appendingPathComponent("atlas_settings.json")

    // ─── Game State ─────────────────────────────────────────────────────────

    /// Persist the current GameState to disk.
    func saveGameState(_ state: GameState) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: PersistenceManager.gameStateURL)
    }

    /// Load a previously saved GameState, or nil if none exists.
    func loadGameState() throws -> GameState? {
        let url = PersistenceManager.gameStateURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GameState.self, from: data)
    }

    /// Delete the saved game state file (e.g. after a win / new game).
    func clearGameState() throws {
        let url = PersistenceManager.gameStateURL
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // ─── Settings ───────────────────────────────────────────────────────────

    /// Persist AppSettings to disk.
    func saveSettings(_ settings: AppSettings) throws {
        let data = try JSONEncoder().encode(settings)
        try data.write(to: PersistenceManager.settingsURL)
    }

    /// Load saved AppSettings, or return defaults if none exist.
    func loadSettings() throws -> AppSettings {
        let url = PersistenceManager.settingsURL
        guard FileManager.default.fileExists(atPath: url.path) else { return AppSettings() }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }
}

// MARK: - FileManager extension

private extension FileManager {
    /// The Application Support directory for this app (created if needed).
    var applicationSupportDirectory: URL {
        let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
