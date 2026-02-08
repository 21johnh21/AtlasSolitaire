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
                ForEach(0..<25, id: \.self) { i in
                    confettiParticle(index: i)
                        .offset(
                            x: confettiX(i) * animationPhase,
                            y: confettiY(i) * animationPhase
                        )
                        .opacity(animationPhase > 0 ? confettiOpacity(i) : 0)
                        .rotationEffect(.degrees(confettiRotation(i) * animationPhase))
                        .scaleEffect(1.0 + (animationPhase * 0.3))
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

    @ViewBuilder
    private func confettiParticle(index: Int) -> some View {
        let size = confettiSize(index)
        let color = confettiColor(index)

        // Mix of shapes: circles, squares, and diamonds
        switch index % 4 {
        case 0:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case 1:
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: size, height: size)
        case 2:
            Diamond()
                .fill(color)
                .frame(width: size, height: size)
        default:
            Star()
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

    private func confettiSize(_ i: Int) -> CGFloat {
        // Vary sizes for more visual interest
        let sizes: [CGFloat] = [6, 8, 10, 7, 9]
        return sizes[i % sizes.count]
    }

    private func confettiOpacity(_ i: Int) -> Double {
        // Vary opacity for depth
        return i % 3 == 0 ? 0.7 : 1.0
    }

    private func confettiRotation(_ i: Int) -> Double {
        // Different rotation speeds and directions
        let rotations: [Double] = [360, -540, 720, -360, 450, -630]
        return rotations[i % rotations.count]
    }

    private func confettiX(_ i: Int) -> CGFloat {
        let angle = Double(i) * (360.0 / 25.0) * .pi / 180.0
        // Vary distance for more dynamic spread
        let distance: CGFloat = i % 2 == 0 ? CGFloat.random(in: 120...180) : CGFloat.random(in: 90...130)
        return CGFloat(cos(angle)) * distance
    }

    private func confettiY(_ i: Int) -> CGFloat {
        let angle = Double(i) * (360.0 / 25.0) * .pi / 180.0
        // Vary distance for more dynamic spread
        let distance: CGFloat = i % 2 == 0 ? CGFloat.random(in: 120...180) : CGFloat.random(in: 90...130)
        return CGFloat(sin(angle)) * distance
    }
}

// MARK: - Custom Shapes

/// Diamond shape for confetti variety
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Star shape for confetti variety
struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<5 {
            let angle = (Double(i) * 72.0 - 90.0) * .pi / 180.0
            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(angle)) * outerRadius,
                y: center.y + CGFloat(sin(angle)) * outerRadius
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }

            let innerAngle = (Double(i) * 72.0 - 90.0 + 36.0) * .pi / 180.0
            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(sin(innerAngle)) * innerRadius
            )
            path.addLine(to: innerPoint)
        }

        path.closeSubpath()
        return path
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
