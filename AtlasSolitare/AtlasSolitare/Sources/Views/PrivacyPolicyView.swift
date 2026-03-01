import SwiftUI

// MARK: - PrivacyPolicyView

/// Displays the app's privacy policy.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color.feltGreen
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────────
                header

                // ── Content ─────────────────────────────────────────────────
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        policySection(
                            title: "Privacy-First Design",
                            content: """
                            Atlas Solitaire is designed with your privacy in mind. We don't collect, store, or sell your personal information. All game data stays on your device.
                            """
                        )

                        policySection(
                            title: "Data Stored Locally",
                            content: """
                            The following data is stored on your device only and never transmitted to our servers:

                            • Game progress and statistics
                            • Your settings and preferences
                            • Win counts and streaks

                            This data is deleted if you uninstall the app.
                            """
                        )

                        policySection(
                            title: "Advertising",
                            content: """
                            Atlas Solitaire displays ads through Google AdMob. We use contextual ads based on geography and game category, NOT personal tracking.

                            You can disable ads completely in Settings at any time.

                            AdMob may collect: general location (country/city), device type, and app performance metrics.
                            """
                        )

                        policySection(
                            title: "Game Center (Optional)",
                            content: """
                            If you use Game Center for leaderboards and achievements, Apple manages that data. You can enable/disable Game Center in iOS Settings.
                            """
                        )

                        policySection(
                            title: "Children's Privacy",
                            content: """
                            Atlas Solitaire is safe for all ages. We don't knowingly collect personal information from anyone, including children. Ads can be disabled in Settings.
                            """
                        )

                        policySection(
                            title: "Your Control",
                            content: """
                            • Disable ads: Settings → Toggle "Ads" off
                            • Delete all data: Uninstall the app
                            • Game Center: iOS Settings → Game Center
                            """
                        )

                        policySection(
                            title: "Contact",
                            content: """
                            Questions? Contact us at geo.gnosis.dev@gmail.com or through the Support section.

                            Last updated: February 28, 2026
                            """
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // ─── Header with back button ────────────────────────────────────────────
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Settings")
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
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Title with icon
            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.accentGold)

                Text("Privacy Policy")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 8)
    }

    // ─── Policy section ─────────────────────────────────────────────────────
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
