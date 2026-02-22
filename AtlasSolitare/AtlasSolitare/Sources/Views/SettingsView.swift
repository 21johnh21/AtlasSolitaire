import SwiftUI

// MARK: - SettingsView

/// Dedicated settings screen accessible from the main menu.
/// Provides toggles for sound, haptics, and other game preferences.
struct SettingsView: View {
    @ObservedObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss
    private let haptic = HapticManager.shared

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color.feltGreen
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────────
                header

                Spacer(minLength: 40)

                // ── Settings list ───────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 24) {
                        // Game Settings
                        settingsCard {
                            VStack(spacing: 20) {
                                settingRow(
                                    title: "Sound",
                                    subtitle: "Game sound effects",
                                    icon: "speaker.wave.3.fill",
                                    isOn: vm.settings.soundEnabled,
                                    action: vm.toggleSound
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingRow(
                                    title: "Haptics",
                                    subtitle: "Vibration feedback",
                                    icon: "hand.raised.fill",
                                    isOn: vm.settings.hapticsEnabled,
                                    action: vm.toggleHaptics
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingRow(
                                    title: "Ads",
                                    subtitle: "Show advertisements",
                                    icon: "rectangle.stack.fill",
                                    isOn: vm.settings.adsEnabled,
                                    action: vm.toggleAds
                                )
                            }
                        }

                        // Tutorial & Info
                        settingsCard {
                            VStack(spacing: 20) {
                                NavigationLink(destination: DemoView()) {
                                    settingNavigationRow(
                                        title: "Play Tutorial",
                                        subtitle: "Interactive demo with guided hints",
                                        icon: "graduationcap.fill"
                                    )
                                }
                                .withClickSound()
                                .simultaneousGesture(TapGesture().onEnded {
                                    haptic.light()
                                })

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                NavigationLink(destination: GameInfoView()) {
                                    settingNavigationRow(
                                        title: "How to Play",
                                        subtitle: "Rules and game instructions",
                                        icon: "info.circle.fill"
                                    )
                                }
                                .withClickSound()
                                .simultaneousGesture(TapGesture().onEnded {
                                    haptic.light()
                                })
                            }
                        }

                        // Support & Help
                        settingsCard {
                            VStack(spacing: 20) {
                                NavigationLink(destination: SupportView()) {
                                    settingNavigationRow(
                                        title: "Support & Help",
                                        subtitle: "FAQs and contact information",
                                        icon: "questionmark.circle.fill"
                                    )
                                }
                                .withClickSound()
                                .simultaneousGesture(TapGesture().onEnded {
                                    haptic.light()
                                })

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                NavigationLink(destination: PrivacyPolicyView()) {
                                    settingNavigationRow(
                                        title: "Privacy Policy",
                                        subtitle: "How we handle your data",
                                        icon: "shield.fill"
                                    )
                                }
                                .withClickSound()
                                .simultaneousGesture(TapGesture().onEnded {
                                    haptic.light()
                                })
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }

                Spacer(minLength: 12)

                // ── Footer ──────────────────────────────────────────────────
                footerInfo
            }
        }
        .navigationBarHidden(true)
    }

    // ─── Header with back button ────────────────────────────────────────────
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    haptic.light()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color.accentGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.2))
                    )
                }
                .withClickSound()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Settings title with icon
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.accentGold)

                Text("Settings")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // ─── Settings card container ────────────────────────────────────────────
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
            )
    }

    // ─── Individual setting row ─────────────────────────────────────────────
    private func settingRow(
        title: String,
        subtitle: String,
        icon: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            haptic.light()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isOn ? Color.accentGold.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isOn ? Color.accentGold : Color.white.opacity(0.3))
                }

                // Title & subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                // Toggle indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? Color.accentGold : Color.white.opacity(0.2))
                        .frame(width: 51, height: 31)

                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .offset(x: isOn ? 10 : -10)
                }
                .animation(.easeInOut(duration: 0.2), value: isOn)
            }
        }
        .withClickSound()
        .buttonStyle(.plain)
    }

    // ─── Navigation row (for links to other pages) ──────────────────────────
    private func settingNavigationRow(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentGold.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGold)
            }

            // Title & subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.3))
        }
    }

    // ─── Footer ─────────────────────────────────────────────────────────────
    private var footerInfo: some View {
        VStack(spacing: 8) {
            Text("Atlas Solitaire")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.white.opacity(0.4))

            Text("Version 1.0")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(vm: GameViewModel())
    }
}
