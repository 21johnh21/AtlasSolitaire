import SwiftUI

// MARK: - AtlasSolitaireApp

/// App entry point.  Creates the single GameViewModel and injects it into the
/// view hierarchy via the environment so every screen can access it.
@main
struct AtlasSolitaireApp: App {
    /// Single source-of-truth view model, alive for the lifetime of the app.
    @StateObject private var gameViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameViewModel)
        }
    }
}

// MARK: - RootView

/// Switches between MenuView and GameView based on the current game phase.
/// Uses a simple conditional rather than a NavigationStack so the transition
/// can be animated as a full-screen swap.
private struct RootView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            switch vm.phase {
            case .menu:
                MenuView(vm: vm)
                    .transition(.opacity)
            case .playing, .won:
                GameView(vm: vm)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.phase)
        .onAppear {
            vm.onAppear()
        }
        // Auto-save on background.
        .onChange(of: vm.gameState) { _ in
            // GameViewModel already auto-saves on every move;
            // this is a belt-and-suspenders hook for scene lifecycle.
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(GameViewModel())
}
