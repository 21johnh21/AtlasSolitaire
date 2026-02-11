import SwiftUI

// MARK: - MenuView

/// Main menu / splash screen.  Shown on first launch and after returning from a game.
/// Provides: New Game, settings toggles, and app title.
struct MenuView: View {
    @ObservedObject var vm: GameViewModel
    private let haptic = HapticManager.shared

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
                                .foregroundColor(Color.white.standard())
                                .padding(14)
                                .background(
                                    Circle()
                                        .fill(Color.black.subtle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.verySubtle(), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.subtle(), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .withClickSound()
                        .simultaneousGesture(TapGesture().onEnded {
                            haptic.light()
                        })
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
        VStack(spacing: 12) {
            // Globe icon as a stand-in for a future logo.
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.accentGold)
                .shadow(color: Color.accentGold.opacity(0.5), radius: 12, x: 0, y: 4)

            Text("Atlas")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

            Text("SOLITAIRE")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.white.strong())
                .tracking(8)
                .kerning(1.5)
        }
    }

    // ─── Continue Game ──────────────────────────────────────────────────────
    private var continueGameButton: some View {
        Button(action: {
            haptic.light()
            vm.continueGame()
        }) {
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
        .buttonStyle(ScaleButtonStyle())
        .withClickSound()
    }

    // ─── New Game ───────────────────────────────────────────────────────────
    private var newGameButton: some View {
        Button(action: {
            haptic.light()
            vm.startNewGame()
        }) {
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
                    ? Color.white.subtle()
                    : Color.accentGold
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
        .withClickSound()
    }

    // ─── Footer ─────────────────────────────────────────────────────────────
    private var footerText: some View {
        Text("Geography-themed Klondike Solitaire")
            .font(.system(size: 11))
            .foregroundColor(Color.white.subtle())
            .padding(.bottom, 24)
    }
}

// MARK: - Custom Button Style

/// Button style that scales down slightly when pressed for tactile feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    MenuView(vm: GameViewModel())
}
