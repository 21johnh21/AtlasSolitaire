import Foundation
import GameKit
import Combine

// MARK: - GameCenterManager

/// Manages Game Center authentication, leaderboard submissions, and achievements.
/// Singleton pattern ensures consistent Game Center state across the app.
class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?

    // MARK: - Leaderboard IDs
    // These IDs must be configured in App Store Connect
    enum LeaderboardID: String {
        case fastestTime = "com.atlassolitaire.leaderboard.fastesttime"
        case fewestMoves = "com.atlassolitaire.leaderboard.fewestmoves"
    }

    // MARK: - Achievement IDs
    // These IDs must be configured in App Store Connect
    enum AchievementID: String {
        case firstWin = "com.atlassolitaire.achievement.firstwin"
        case speedDemon = "com.atlassolitaire.achievement.speeddemon"        // Win in under 2 minutes
        case efficient = "com.atlassolitaire.achievement.efficient"          // Win in under 50 moves
        case perfectGame = "com.atlassolitaire.achievement.perfectgame"      // Win in under 1 minute AND under 40 moves
        case winStreak5 = "com.atlassolitaire.achievement.winstreak5"        // Win 5 games in a row
        case winStreak10 = "com.atlassolitaire.achievement.winstreak10"      // Win 10 games in a row
        case totalWins10 = "com.atlassolitaire.achievement.totalwins10"      // Win 10 games total
        case totalWins50 = "com.atlassolitaire.achievement.totalwins50"      // Win 50 games total
        case totalWins100 = "com.atlassolitaire.achievement.totalwins100"    // Win 100 games total
    }

    private override init() {
        super.init()
    }

    // MARK: - Authentication

    /// Authenticate the local player with Game Center.
    /// Should be called once at app launch.
    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                // Present the Game Center login view controller
                // Note: This needs to be presented from a view controller
                // For SwiftUI apps, we'll handle this via a notification or published property
                self?.presentAuthenticationViewController(viewController)
                return
            }

            if let error = error {
                print("[GameCenter] Authentication error: \(error.localizedDescription)")
                self?.isAuthenticated = false
                return
            }

            // Successfully authenticated
            if GKLocalPlayer.local.isAuthenticated {
                print("[GameCenter] ✅ Player authenticated: \(GKLocalPlayer.local.displayName)")
                self?.isAuthenticated = true
                self?.loadAchievements()
            } else {
                print("[GameCenter] ⚠️ Player not authenticated")
                self?.isAuthenticated = false
            }
        }
    }

    /// Present the authentication view controller (for SwiftUI apps, this needs special handling)
    private func presentAuthenticationViewController(_ viewController: UIViewController) {
        // Post notification that authentication UI needs to be shown
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowGameCenterAuthentication"),
            object: viewController
        )
    }

    // MARK: - Leaderboards

    /// Submit a score to a leaderboard.
    func submitScore(_ score: Int, to leaderboard: LeaderboardID) {
        guard isAuthenticated else {
            print("[GameCenter] Cannot submit score - not authenticated")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboard.rawValue]
                )
                print("[GameCenter] ✅ Score submitted to \(leaderboard.rawValue): \(score)")
            } catch {
                print("[GameCenter] ❌ Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    /// Submit a game result (time and moves) to both leaderboards.
    func submitGameResult(timeInSeconds: Int, moves: Int) {
        guard isAuthenticated else { return }

        // Submit time (lower is better)
        submitScore(timeInSeconds, to: .fastestTime)

        // Submit moves (lower is better)
        submitScore(moves, to: .fewestMoves)
    }

    /// Show the Game Center leaderboard UI.
    func showLeaderboard(_ leaderboard: LeaderboardID? = nil) {
        guard isAuthenticated else {
            print("[GameCenter] Cannot show leaderboard - not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(state: .leaderboards)
        if let leaderboard = leaderboard {
            viewController.leaderboardIdentifier = leaderboard.rawValue
        }

        // Post notification to present the view controller
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowGameCenterLeaderboard"),
            object: viewController
        )
    }

    // MARK: - Achievements

    private var loadedAchievements: [GKAchievement] = []

    /// Load all achievements for the local player.
    private func loadAchievements() {
        Task {
            do {
                loadedAchievements = try await GKAchievement.loadAchievements()
                print("[GameCenter] ✅ Loaded \(loadedAchievements.count) achievements")
            } catch {
                print("[GameCenter] ❌ Failed to load achievements: \(error.localizedDescription)")
            }
        }
    }

    /// Report an achievement as completed.
    func unlockAchievement(_ achievement: AchievementID) {
        guard isAuthenticated else { return }

        let gkAchievement = GKAchievement(identifier: achievement.rawValue)
        gkAchievement.percentComplete = 100.0
        gkAchievement.showsCompletionBanner = true

        Task {
            do {
                try await GKAchievement.report([gkAchievement])
                print("[GameCenter] ✅ Achievement unlocked: \(achievement.rawValue)")
            } catch {
                print("[GameCenter] ❌ Failed to report achievement: \(error.localizedDescription)")
            }
        }
    }

    /// Check if an achievement has been completed.
    func isAchievementUnlocked(_ achievement: AchievementID) -> Bool {
        return loadedAchievements.first(where: { $0.identifier == achievement.rawValue })?.isCompleted ?? false
    }

    /// Process a game win and unlock any applicable achievements.
    func processGameWin(timeInSeconds: TimeInterval, moves: Int, isFirstWin: Bool, currentWinStreak: Int, totalWins: Int) {
        guard isAuthenticated else { return }

        // First win
        if isFirstWin {
            unlockAchievement(.firstWin)
        }

        // Speed achievements
        if timeInSeconds < 120 {  // Under 2 minutes
            unlockAchievement(.speedDemon)
        }

        // Efficiency achievements
        if moves < 50 {
            unlockAchievement(.efficient)
        }

        // Perfect game (both fast AND efficient)
        if timeInSeconds < 60 && moves < 40 {
            unlockAchievement(.perfectGame)
        }

        // Win streak achievements
        if currentWinStreak >= 5 {
            unlockAchievement(.winStreak5)
        }
        if currentWinStreak >= 10 {
            unlockAchievement(.winStreak10)
        }

        // Total wins achievements
        if totalWins >= 10 {
            unlockAchievement(.totalWins10)
        }
        if totalWins >= 50 {
            unlockAchievement(.totalWins50)
        }
        if totalWins >= 100 {
            unlockAchievement(.totalWins100)
        }
    }

    /// Show the Game Center achievements UI.
    func showAchievements() {
        guard isAuthenticated else {
            print("[GameCenter] Cannot show achievements - not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(state: .achievements)

        // Post notification to present the view controller
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowGameCenterAchievements"),
            object: viewController
        )
    }
}
