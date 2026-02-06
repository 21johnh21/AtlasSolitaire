import SwiftUI

// MARK: - MenuView

/// Main menu / splash screen.  Shown on first launch and after returning from a game.
/// Provides: New Game, settings toggles, and app title.
struct MenuView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color.feltGreen
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // ── Title block ─────────────────────────────────────────────
                titleBlock

                Spacer(minLength: 40)

                // ── New Game button ─────────────────────────────────────────
                newGameButton

                Spacer(minLength: 32)

                // ── Settings ────────────────────────────────────────────────
                settingsSection

                Spacer()

                // ── Footer ──────────────────────────────────────────────────
                footerText
            }
            .padding(.horizontal, 40)
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

    // ─── New Game ───────────────────────────────────────────────────────────
    private var newGameButton: some View {
        Button(action: vm.startNewGame) {
            Text("New Game")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 56)
                .padding(.vertical, 16)
                .background(Color.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)
        }
    }

    // ─── Settings toggles ───────────────────────────────────────────────────
    private var settingsSection: some View {
        VStack(spacing: 16) {
            settingToggle(
                title: "Sound",
                icon: vm.settings.soundEnabled ? "speaker.3.fill" : "speaker.slash.fill",
                isOn: vm.settings.soundEnabled,
                action: vm.toggleSound
            )
            settingToggle(
                title: "Haptics",
                icon: vm.settings.hapticsEnabled ? "hand.raised.fill" : "hand.raised.slash",
                isOn: vm.settings.hapticsEnabled,
                action: vm.toggleHaptics
            )
        }
    }

    private func settingToggle(title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isOn ? Color.accentGold : Color.white.opacity(0.4))
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(isOn ? Color.white : Color.white.opacity(0.4))
            }
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
