import SwiftUI

// MARK: - LaunchScreenView

/// Launch screen shown while the app is loading.
/// Matches the main menu's visual style for a seamless transition.
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background
            Color.feltGreen
                .ignoresSafeArea()

            // Centered logo and title
            VStack(spacing: 12) {
                // Globe icon (matches MenuView)
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 180))
                    .foregroundColor(Color.accentGold)
                    .shadow(color: Color.accentGold.opacity(0.5), radius: 12, x: 0, y: 4)

                Text("Atlas")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                Text("SOLITAIRE")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.strong())
                    .tracking(8)
                    .kerning(1.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
