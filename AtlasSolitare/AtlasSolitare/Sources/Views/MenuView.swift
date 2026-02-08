import SwiftUI

// MARK: - MenuView

/// Main menu / splash screen.  Shown on first launch and after returning from a game.
/// Provides: New Game, settings toggles, and app title.
struct MenuView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background ──────────────────────────────────────────────────
                Color.feltGreen
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Settings button in top right ────────────────────────────
                    HStack {
                        Spacer()
                        NavigationLink(destination: SettingsView(vm: vm)) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer(minLength: 20)

                // ── Title block ─────────────────────────────────────────────
                titleBlock

                Spacer(minLength: 40)

                // ── Game buttons ────────────────────────────────────────────
                VStack(spacing: 16) {
                    // Continue button (only shown if there's a saved game)
                    if vm.hasSavedGame {
                        continueGameButton
                    }

                    newGameButton
                }

                Spacer()

                // ── Footer ──────────────────────────────────────────────────
                footerText
                }
                .padding(.horizontal, 40)
            }
            .navigationBarHidden(true)
        }
    }

    // ─── Title ──────────────────────────────────────────────────────────────
    private var titleBlock: some View {
        VStack(spacing: 8) {
            // Globe icon as a stand-in for a future logo.
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 56))
                .foregroundColor(Color.accentGold)
                .shadow(color: Color.accentGold.opacity(0.3), radius: 8)

            Text("Atlas")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            Text("Solitaire")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color.white.opacity(0.7))
                .tracking(6)
                .textCase(.uppercase)
        }
    }

    // ─── Continue Game ──────────────────────────────────────────────────────
    private var continueGameButton: some View {
        Button(action: vm.continueGame) {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                Text("Continue Game")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Color.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
        }
    }

    // ─── New Game ───────────────────────────────────────────────────────────
    private var newGameButton: some View {
        Button(action: vm.startNewGame) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("New Game")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 56)
            .padding(.vertical, 16)
            .background(
                vm.hasSavedGame
                    ? Color.white.opacity(0.15)
                    : Color.accentGold
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
        }
    }

    // ─── Footer ─────────────────────────────────────────────────────────────
    private var footerText: some View {
        Text("Geography-themed Klondike Solitaire")
            .font(.system(size: 11))
            .foregroundColor(Color.white.opacity(0.3))
            .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    MenuView(vm: GameViewModel())
}
