import SwiftUI
import GameKit

// MARK: - GameCenterView

/// SwiftUI wrapper for presenting Game Center view controllers.
/// Listens for notifications from GameCenterManager to present leaderboards, achievements, etc.
struct GameCenterView: UIViewControllerRepresentable {
    @Binding var viewController: GKGameCenterViewController?

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present the Game Center view controller when it's set
        if let vc = viewController, uiViewController.presentedViewController == nil {
            // Set the delegate to handle dismissal
            vc.gameCenterDelegate = context.coordinator
            uiViewController.present(vc, animated: true)
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
                // Clear the binding after dismissal is complete
                DispatchQueue.main.async {
                    self.parent.viewController = nil
                }
            }
        }
    }
}

// MARK: - GameCenterViewModifier

/// View modifier that adds Game Center presentation capabilities to any view.
struct GameCenterViewModifier: ViewModifier {
    @State private var gameCenterViewController: GKGameCenterViewController?

    func body(content: Content) -> some View {
        content
            .background(
                GameCenterView(viewController: $gameCenterViewController)
                    .frame(width: 0, height: 0)
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowGameCenterLeaderboard"))) { notification in
                if let vc = notification.object as? GKGameCenterViewController {
                    gameCenterViewController = vc
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowGameCenterAchievements"))) { notification in
                if let vc = notification.object as? GKGameCenterViewController {
                    gameCenterViewController = vc
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowGameCenterAuthentication"))) { notification in
                if let vc = notification.object as? UIViewController {
                    // Authentication uses a regular UIViewController, not GKGameCenterViewController
                    // We'll handle this case separately if needed
                    print("[GameCenter] Authentication VC received, but not currently handled in SwiftUI")
                }
            }
    }
}

extension View {
    /// Adds Game Center presentation capabilities to this view.
    func withGameCenter() -> some View {
        modifier(GameCenterViewModifier())
    }
}
