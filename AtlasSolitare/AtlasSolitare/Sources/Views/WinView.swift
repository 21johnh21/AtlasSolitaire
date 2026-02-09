import SwiftUI

// MARK: - WinView

/// Displayed as a full-screen overlay when the player wins.
/// Shows a congratulations message and two action buttons:
/// "Play Again" and "Return to Menu".
struct WinView: View {
    @ObservedObject var vm: GameViewModel
    private let haptic = HapticManager.shared

    /// Simple particle-like animation state.
    @State private var animationPhase: Double = 0
    @State private var trophyScale: CGFloat = 1.0
    @State private var trophyRotation: Double = 0
    @State private var displayedMoves: Int = 0
    @State private var displayedTime: TimeInterval = 0

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            Color.feltGreen
                .ignoresSafeArea()

            // ── Decorative confetti circles ─────────────────────────────────
            confetti

            // ── Content card ────────────────────────────────────────────────
            VStack(spacing: 32) {
                // Trophy icon with pulse animation
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color.accentGold)
                    .shadow(color: Color.accentGold.opacity(0.4), radius: 12)
                    .scaleEffect(trophyScale)
                    .rotationEffect(.degrees(trophyRotation))

                // Title
                Text("You Win!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                // Subtitle
                Text("All \(vm.totalGroupCount) groups completed!")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.75))

                // Stats with count-up animation
                HStack(spacing: 24) {
                    statItem(icon: "hand.tap.fill", label: "Moves", value: "\(displayedMoves)")
                    statItem(icon: "clock.fill", label: "Time", value: formatTime(displayedTime))
                }
                .padding(.top, 16)

                Spacer(minLength: 24)

                // ── Action buttons ──────────────────────────────────────────
                Button(action: {
                    haptic.light()
                    vm.startNewGame()
                }) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                }

                Button(action: {
                    haptic.light()
                    vm.returnToMenu()
                }) {
                    Text("Return to Menu")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.6))
                        .underline()
                }
            }
            .padding(.horizontal, 40)
        }
        // Kick off animations on appear.
        .onAppear {
            // Confetti continuous animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }

            // Trophy pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                trophyScale = 1.1
            }

            // Trophy subtle rotation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                trophyRotation = 5
            }

            // Count up moves animation
            let targetMoves = vm.gameState?.moveCount ?? 0
            let movesIncrement = max(1, targetMoves / 30)
            Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
                if displayedMoves < targetMoves {
                    displayedMoves = min(displayedMoves + movesIncrement, targetMoves)
                } else {
                    timer.invalidate()
                }
            }

            // Count up time animation
            let targetTime = vm.currentElapsedTime
            let timeIncrement = targetTime / 30
            Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
                if displayedTime < targetTime {
                    displayedTime = min(displayedTime + timeIncrement, targetTime)
                } else {
                    timer.invalidate()
                }
            }
        }
        .accessibilityLabel("You win! All groups completed.")
    }

    // ─── Continuous falling confetti decoration ─────────────────────────────
    private var confetti: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { i in
                    confettiParticle(index: i, screenSize: geometry.size)
                        .offset(
                            x: confettiX(i, screenWidth: geometry.size.width),
                            y: confettiY(i, animationPhase: animationPhase, screenHeight: geometry.size.height)
                        )
                        .rotationEffect(.degrees(confettiRotation(i, animationPhase: animationPhase)))
                        .opacity(0.7)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func confettiParticle(index: Int, screenSize: CGSize) -> some View {
        let size: CGFloat = CGFloat([6, 8, 10, 7, 9][index % 5])
        let color = confettiColor(index)

        switch index % 3 {
        case 0:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case 1:
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: size, height: size)
        default:
            Diamond()
                .fill(color)
                .frame(width: size, height: size)
        }
    }

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

    private func confettiX(_ i: Int, screenWidth: CGFloat) -> CGFloat {
        // Spread particles across screen width with some variation
        let baseX = (CGFloat(i) / 30.0) * screenWidth - screenWidth / 2
        let sway = sin(Double(i) * 0.5 + animationPhase * 2.0) * 20
        return baseX + CGFloat(sway)
    }

    private func confettiY(_ i: Int, animationPhase: Double, screenHeight: CGFloat) -> CGFloat {
        // Particles fall from top to bottom continuously
        let startY = -50 - CGFloat(i % 10) * 50
        let endY = screenHeight + 50
        let progress = (animationPhase + Double(i) * 0.033).truncatingRemainder(dividingBy: 1.0)
        return startY + (endY - startY) * CGFloat(progress)
    }

    private func confettiRotation(_ i: Int, animationPhase: Double) -> Double {
        // Continuous rotation at different speeds
        let rotationSpeeds: [Double] = [360, -540, 720, -360, 450]
        let speed = rotationSpeeds[i % rotationSpeeds.count]
        return speed * animationPhase
    }

    // ─── Stat item ──────────────────────────────────────────────────────────
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.accentGold)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.6))
        }
    }

    // ─── Format time ────────────────────────────────────────────────────────
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}


// MARK: - Preview

#Preview {
    WinView(vm: GameViewModel())
}
