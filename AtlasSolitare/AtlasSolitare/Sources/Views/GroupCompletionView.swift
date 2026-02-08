import SwiftUI

// MARK: - GroupCompletionView

/// Celebration overlay shown when a foundation group is completed.
/// Displays a congratulations message with animated confetti particles.
struct GroupCompletionView: View {
    let groupName: String

    @State private var animationPhase: Double = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 16) {
            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.accentGold)
                .shadow(color: Color.accentGold.opacity(0.6), radius: 20)
                .scaleEffect(scale)

            // Congratulations text
            VStack(spacing: 8) {
                Text("Group Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(groupName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.accentGold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .shadow(color: Color.accentGold.opacity(0.3), radius: 20)
        )
        .overlay {
            // Confetti particles
            ZStack {
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(confettiColor(i))
                        .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                        .offset(
                            x: confettiX(i) * animationPhase,
                            y: confettiY(i) * animationPhase
                        )
                        .opacity(animationPhase > 0 ? Double.random(in: 0.6...1.0) : 0)
                        .rotationEffect(.degrees(Double(i) * 18 * animationPhase))
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            // Fade in and scale up
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
                scale = 1.0
            }

            // Explode confetti
            withAnimation(.easeOut(duration: 0.8)) {
                animationPhase = 1
            }

            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0
                }
            }
        }
    }

    // ─── Confetti helpers ───────────────────────────────────────────────────

    private func confettiColor(_ i: Int) -> Color {
        let colors: [Color] = [
            Color.accentGold,
            .white,
            Color(red: 0.9, green: 0.6, blue: 0.3),
            Color(red: 0.5, green: 0.8, blue: 0.9),
            Color(red: 0.9, green: 0.4, blue: 0.6),
            Color(red: 0.6, green: 0.9, blue: 0.4)
        ]
        return colors[i % colors.count]
    }

    private func confettiX(_ i: Int) -> CGFloat {
        let angle = Double(i) * (360.0 / 20.0) * .pi / 180.0
        let distance: CGFloat = CGFloat.random(in: 100...160)
        return cos(angle) * distance
    }

    private func confettiY(_ i: Int) -> CGFloat {
        let angle = Double(i) * (360.0 / 20.0) * .pi / 180.0
        let distance: CGFloat = CGFloat.random(in: 100...160)
        return sin(angle) * distance
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.feltGreen
            .ignoresSafeArea()

        GroupCompletionView(groupName: "Countries of Europe")
    }
}
