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
                            title: "Information We Collect",
                            content: """
                            Atlas Solitaire is a privacy-first application. We do not collect, store, or transmit any personal information or user data to external servers.

                            All game data, including your progress and settings, is stored locally on your device only.
                            """
                        )

                        policySection(
                            title: "Data Storage",
                            content: """
                            Your game preferences and saved games are stored locally on your device using iOS secure storage mechanisms. This data never leaves your device and is not accessible to us or any third parties.
                            """
                        )

                        policySection(
                            title: "No Analytics or Tracking",
                            content: """
                            We do not use any analytics, tracking, or advertising services. Your gameplay is completely private.
                            """
                        )

                        policySection(
                            title: "Third-Party Services",
                            content: """
                            Atlas Solitaire does not integrate with any third-party services, social networks, or advertising platforms.
                            """
                        )

                        policySection(
                            title: "Children's Privacy",
                            content: """
                            Our app does not knowingly collect any information from children. The app is safe for users of all ages.
                            """
                        )

                        policySection(
                            title: "Changes to This Policy",
                            content: """
                            If we make any changes to our privacy practices, we will update this policy and the effective date below.

                            Last updated: February 8, 2026
                            """
                        )

                        policySection(
                            title: "Contact",
                            content: """
                            If you have any questions about this Privacy Policy, please contact us through the Support & Help section.
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
