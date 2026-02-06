import SwiftUI

// MARK: - WinView

/// Displayed as a full-screen overlay when the player wins.
/// Shows a congratulations message and two action buttons:
/// "Play Again" and "Return to Menu".
struct WinView: View {
    @ObservedObject var vm: GameViewModel

    /// Simple particle-like animation state.
    @State private var animationPhase: Double = 0

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color.feltGreen
                .ignoresSafeArea()

            // ── Decorative confetti circles ─────────────────────────────────
            confetti

            // ── Content card ────────────────────────────────────────────────
            VStack(spacing: 32) {
                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color.accentGold)
                    .shadow(color: Color.accentGold.opacity(0.4), radius: 12)

                // Title
                Text("You Win!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                // Subtitle
                Text("All \(vm.totalGroupCount) groups completed!")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.75))

                Spacer(minLength: 24)

                // ── Action buttons ──────────────────────────────────────────
                Button(action: vm.startNewGame) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                }

                Button(action: vm.returnToMenu) {
                    Text("Return to Menu")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.6))
                        .underline()
                }
            }
            .padding(.horizontal, 40)
        }
        // Kick off the confetti animation on appear.
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animationPhase = 1
            }
        }
        .accessibilityLabel("You win! All groups completed.")
    }

    // ─── Simple confetti decoration ─────────────────────────────────────────
    private var confetti: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(confettiColor(i))
                    .frame(width: 10, height: 10)
                    .offset(
                        x: confettiX(i) * animationPhase,
                        y: confettiY(i) * animationPhase
                    )
                    .opacity(animationPhase > 0 ? 0.8 : 0)
            }
        }
    }

    private func confettiColor(_ i: Int) -> Color {
        let colors: [Color] = [Color.accentGold, .white, Color(red: 0.9, green: 0.6, blue: 0.3), Color(red: 0.5, green: 0.8, blue: 0.9)]
        return colors[i % colors.count]
    }

    private func confettiX(_ i: Int) -> CGFloat {
        let xs: [CGFloat] = [-120, -80, -40, 0, 40, 80, 120, -100, -50, 50, 100, 0]
        return xs[i % xs.count]
    }

    private func confettiY(_ i: Int) -> CGFloat {
        let ys: [CGFloat] = [-180, -150, -200, -160, -170, -190, -155, -175, -185, -145, -195, -210]
        return ys[i % ys.count]
    }
}

// MARK: - Preview

#Preview {
    WinView(vm: GameViewModel())
}
