import SwiftUI
import GameKit

// MARK: - GameCenterViewModifier

/// View modifier that adds Game Center presentation capabilities to any view.
struct GameCenterViewModifier: ViewModifier {
    @State private var gameCenterState: GameCenterState?

    enum GameCenterState {
        case leaderboard(String?)
        case achievements
    }

    func body(content: Content) -> some View {
        content
            .background(
                GameCenterView(state: $gameCenterState)
                    .frame(width: 0, height: 0)
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowGameCenterLeaderboard"))) { notification in
                let leaderboardID = notification.object as? String
                gameCenterState = .leaderboard(leaderboardID)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowGameCenterAchievements"))) { _ in
                gameCenterState = .achievements
            }
    }
}

// MARK: - GameCenterView

/// UIViewControllerRepresentable for presenting Game Center UI
/// Note: GKGameCenterViewController is deprecated in iOS 26.0, but there's no official SwiftUI replacement yet.
/// This implementation will need to be updated when Apple releases the new API.
struct GameCenterView: UIViewControllerRepresentable {
    @Binding var state: GameCenterViewModifier.GameCenterState?

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let state = state, uiViewController.presentedViewController == nil else {
            return
        }

        // Present Game Center VC on main thread
        DispatchQueue.main.async {
            let viewController: GKGameCenterViewController

            switch state {
            case .leaderboard:
                // Use the iOS 14+ initializer
                // Note: Specific leaderboard selection is deprecated, shows all leaderboards
                viewController = GKGameCenterViewController(state: .leaderboards)

            case .achievements:
                viewController = GKGameCenterViewController(state: .achievements)
            }

            viewController.gameCenterDelegate = context.coordinator
            uiViewController.present(viewController, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView

        init(_ parent: GameCenterView) {
            self.parent = parent
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true) {
                DispatchQueue.main.async {
                    self.parent.state = nil
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds Game Center presentation capabilities to this view.
    func withGameCenter() -> some View {
        modifier(GameCenterViewModifier())
    }
}
