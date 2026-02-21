import SwiftUI

// MARK: - GameInfoView

/// Displays game rules, instructions, and information about how to play.
struct GameInfoView: View {
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

                Spacer(minLength: 20)

                // ── Content ─────────────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 24) {
                        // How to Play
                        infoCard(
                            title: "How to Play",
                            icon: "gamecontroller.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 16) {
                                infoText(
                                    "Atlas Solitaire is a geography-themed solitaire game. Build complete sets by matching cards from the same category."
                                )

                                infoText(
                                    "Each game features 5 different categories (like countries, cities, or landmarks). Your goal is to build all sets to win!"
                                )
                            }
                        }

                        // Game Rules
                        infoCard(
                            title: "Rules",
                            icon: "list.bullet.clipboard.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                ruleItem(
                                    number: "1",
                                    text: "Draw cards from the stock pile at the top right"
                                )

                                ruleItem(
                                    number: "2",
                                    text: "Build sequences in the tableau (descending order, alternating colors)"
                                )

                                ruleItem(
                                    number: "3",
                                    text: "Move cards to foundations to complete sets"
                                )

                                ruleItem(
                                    number: "4",
                                    text: "A foundation is complete when it has all matching cards from a category"
                                )

                                ruleItem(
                                    number: "5",
                                    text: "Complete all 5 sets to win the game!"
                                )
                            }
                        }

                        // Tableau Rules
                        infoCard(
                            title: "Tableau Building",
                            icon: "square.stack.3d.down.right.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                infoText(
                                    "In the tableau (the 7 columns), you can:"
                                )

                                bulletPoint("Build sequences in descending order")
                                bulletPoint("Alternate between red and black cards")
                                bulletPoint("Move sequences of cards together")
                                bulletPoint("Place any card on an empty tableau pile")
                            }
                        }

                        // Foundation Rules
                        infoCard(
                            title: "Foundation Building",
                            icon: "square.stack.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                infoText(
                                    "Foundations are built with matching sets:"
                                )

                                bulletPoint("Start a foundation with a base card")
                                bulletPoint("Add partner cards that belong to the same category")
                                bulletPoint("Complete the set to score points")
                                bulletPoint("Once complete, the foundation celebrates!")
                            }
                        }

                        // Tips & Strategy
                        infoCard(
                            title: "Tips & Strategy",
                            icon: "lightbulb.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                bulletPoint("Always try to reveal face-down cards in the tableau")
                                bulletPoint("Keep tableau piles organized to maintain flexibility")
                                bulletPoint("Don't rush to move cards to foundations - sometimes they're more useful in the tableau")
                                bulletPoint("When stuck, reshuffle the waste pile back into the stock")
                            }
                        }

                        // About Decks
                        infoCard(
                            title: "About the Decks",
                            icon: "globe.americas.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                infoText(
                                    "Atlas Solitaire features over 100 different geography-themed categories including:"
                                )

                                bulletPoint("Countries, capitals, and cities")
                                bulletPoint("Islands, mountains, and rivers")
                                bulletPoint("Historical sites and landmarks")
                                bulletPoint("National parks and natural wonders")

                                infoText(
                                    "Each game randomly selects 5 categories to keep things fresh and challenging!"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                Spacer(minLength: 12)
            }
        }
        .navigationBarHidden(true)
    }

    // ─── Header ─────────────────────────────────────────────────────────────
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

            // Title
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.accentGold)

                Text("Game Info")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // ─── Info card container ────────────────────────────────────────────────
    @ViewBuilder
    private func infoCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card title with icon
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGold)

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
        )
    }

    // ─── Info text ──────────────────────────────────────────────────────────
    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(Color.white.opacity(0.85))
            .lineSpacing(4)
    }

    // ─── Numbered rule item ─────────────────────────────────────────────────
    private func ruleItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentGold.opacity(0.2))
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.accentGold)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(4)
        }
    }

    // ─── Bullet point ───────────────────────────────────────────────────────
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.accentGold)
                .frame(width: 12)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameInfoView()
    }
}
