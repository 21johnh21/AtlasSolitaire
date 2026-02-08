import SwiftUI

// MARK: - SupportView

/// Displays support information, FAQs, and game instructions.
struct SupportView: View {
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
                    VStack(spacing: 24) {
                        // How to Play
                        supportSection(
                            icon: "gamecontroller.fill",
                            title: "How to Play",
                            items: [
                                "The goal is to complete all groups by matching partner cards with their base cards.",
                                "Tap the stock pile to draw cards to the waste pile.",
                                "Drag cards between tableau piles, foundations, and the waste pile.",
                                "Build sequences in the tableau by descending rank (alternating colors).",
                                "Place base cards in foundations, then add matching partner cards.",
                                "When all partners are placed on a base card, the group is completed and cleared.",
                                "Win by completing all groups in the deck!"
                            ]
                        )

                        // Game Controls
                        supportSection(
                            icon: "hand.tap.fill",
                            title: "Game Controls",
                            items: [
                                "Tap the stock pile to draw a card to the waste pile.",
                                "Drag and drop cards to move them between piles.",
                                "Tap a card to select it, then tap a destination to move it.",
                                "Tap the reshuffle icon to return waste cards to the stock (when available).",
                                "Use the Quit button to return to the main menu and save your game."
                            ]
                        )

                        // Tips & Strategies
                        supportSection(
                            icon: "lightbulb.fill",
                            title: "Tips & Strategies",
                            items: [
                                "Focus on uncovering face-down cards in the tableau.",
                                "Build long sequences in the tableau before moving cards to foundations.",
                                "Pay attention to which groups are in play to plan your moves.",
                                "Empty tableau spaces can hold any card - use them strategically.",
                                "Use the reshuffle option wisely when you're stuck."
                            ]
                        )

                        // Frequently Asked Questions
                        faqSection

                        // Contact Support
                        contactSection
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
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.accentGold)

                Text("Support & Help")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 8)
    }

    // ─── Support section with bullet points ─────────────────────────────────
    private func supportSection(icon: String, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.accentGold)

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.accentGold)

                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    // ─── FAQ section ────────────────────────────────────────────────────────
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.accentGold)

                Text("FAQs")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 20) {
                faqItem(
                    question: "What happens when I complete a group?",
                    answer: "When you place all partner cards on their base card in a foundation pile, the group is completed. You'll see a celebration animation, and the cards will be cleared from the board."
                )

                faqItem(
                    question: "Can I undo moves?",
                    answer: "Currently, Atlas Solitaire does not support undo. Plan your moves carefully!"
                )

                faqItem(
                    question: "Is my progress saved?",
                    answer: "Yes! Your game is automatically saved when you quit. Use 'Continue Game' from the main menu to resume where you left off."
                )

                faqItem(
                    question: "What are the groups based on?",
                    answer: "Each group represents a geographic category, such as countries in Europe, states in the US, or cities in Asia. The base card names the category, and partner cards are the members."
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.accentGold)

            Text(answer)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(4)
        }
    }

    // ─── Contact section ────────────────────────────────────────────────────
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.accentGold)

                Text("Contact Support")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Need more help? Have feedback or found a bug?\n\nPlease reach out to us at:")
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.85))
                .lineSpacing(4)

            Text("support@atlassolitaire.com")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.accentGold)
                .padding(.top, 4)
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
        SupportView()
    }
}
