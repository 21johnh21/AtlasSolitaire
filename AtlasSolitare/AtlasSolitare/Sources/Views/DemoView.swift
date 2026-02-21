import SwiftUI

// MARK: - DemoView

/// Interactive demo/tutorial mode that guides users through game mechanics
/// with hints and step-by-step instructions while they actually play.
struct DemoView: View {
    @StateObject private var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: DemoStep = .welcome
    @State private var showHint = true
    @State private var hasDrawnCard = false
    @State private var hasMovedToTableau = false
    @State private var hasMovedToFoundation = false
    @State private var completedSets = 0

    private let haptic = HapticManager.shared

    init() {
        let vm = GameViewModel()
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            // Main game view (fully playable)
            if vm.phase == .playing {
                GameView(vm: vm)
            } else if vm.phase == .won {
                // Show win screen with tutorial complete message
                VStack(spacing: 30) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.accentGold)

                    Text("Tutorial Complete!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("You've learned all the basics.\nReady to play the full game?")
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    Button(action: {
                        haptic.light()
                        dismiss()
                    }) {
                        Text("Start Playing")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentGold)
                            )
                    }
                    .withClickSound()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.feltGreen.ignoresSafeArea())
            } else {
                // Fallback background
                Color.feltGreen
                    .ignoresSafeArea()
            }

            // Overlay hint system (only during play)
            if vm.phase == .playing {
                VStack {
                    Spacer()

                    // Hint card
                    if showHint {
                        hintCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        // Show hint button when minimized
                        showHintButton
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startDemo()
        }
        .onChange(of: vm.gameState?.stock.count) { _, _ in
            updateProgress()
        }
        .onChange(of: vm.completedGroupCount) { _, newCount in
            if newCount > completedSets {
                completedSets = newCount
                updateProgress()
            }
        }
        .onChange(of: vm.phase) { _, newPhase in
            // If user pressed back button, exit demo
            if newPhase == .menu {
                dismiss()
            }
        }
    }

    // ─── Show Hint Button ───────────────────────────────────────────────────
    private var showHintButton: some View {
        Button(action: {
            haptic.light()
            withAnimation(.spring(response: 0.3)) {
                showHint = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGold)

                Text("Show Hint")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
            )
        }
        .withClickSound()
    }

    // ─── Hint Card ──────────────────────────────────────────────────────────
    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hint header
            HStack(spacing: 10) {
                Image(systemName: currentStep.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.accentGold)

                Text(currentStep.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Minimize button
                Button(action: {
                    haptic.light()
                    withAnimation(.spring(response: 0.3)) {
                        showHint.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                }
                .withClickSound()
            }

            // Hint content
            Text(currentStep.message)
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.9))
                .lineSpacing(4)

            // Navigation buttons
            HStack(spacing: 12) {
                // Previous button
                if currentStep != .welcome {
                    Button(action: {
                        haptic.light()
                        goToPreviousStep()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Previous")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .withClickSound()
                }

                // Next button
                if let buttonText = currentStep.buttonText {
                    Button(action: {
                        haptic.light()
                        advanceStep()
                    }) {
                        HStack(spacing: 6) {
                            Text(buttonText)
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentGold)
                        )
                    }
                    .withClickSound()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
        )
    }

    // ─── Demo Logic ─────────────────────────────────────────────────────────
    private func startDemo() {
        // Start the demo game using the demo deck
        vm.startDemoGame()
        currentStep = .welcome
        hasDrawnCard = false
        hasMovedToTableau = false
        hasMovedToFoundation = false
        completedSets = 0
    }

    private func updateProgress() {
        // Track player actions and advance hints contextually
        if !hasDrawnCard && vm.wasteTopCard != nil {
            hasDrawnCard = true
            if currentStep == .drawCard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    advanceStep()
                }
            }
        }

        // Advance when player completes their first set
        if completedSets == 1 && currentStep == .buildingSets {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                advanceStep()
            }
        }
    }

    private func advanceStep() {
        withAnimation(.spring(response: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .drawCard
            case .drawCard:
                currentStep = .tableauExplained
            case .tableauExplained:
                currentStep = .foundationExplained
            case .foundationExplained:
                currentStep = .dragAndDrop
            case .dragAndDrop:
                currentStep = .buildingSets
            case .buildingSets:
                currentStep = .keepPlaying
            case .keepPlaying:
                // Just let them play - hint will tell them to complete all sets
                showHint = false
            }
        }
    }

    private func goToPreviousStep() {
        withAnimation(.spring(response: 0.3)) {
            switch currentStep {
            case .welcome:
                break // Can't go back from welcome
            case .drawCard:
                currentStep = .welcome
            case .tableauExplained:
                currentStep = .drawCard
            case .foundationExplained:
                currentStep = .tableauExplained
            case .dragAndDrop:
                currentStep = .foundationExplained
            case .buildingSets:
                currentStep = .dragAndDrop
            case .keepPlaying:
                currentStep = .buildingSets
                showHint = true
            }
        }
    }
}

// MARK: - DemoStep

enum DemoStep {
    case welcome
    case drawCard
    case tableauExplained
    case foundationExplained
    case dragAndDrop
    case buildingSets
    case keepPlaying

    var title: String {
        switch self {
        case .welcome: return "Welcome to Atlas Solitaire!"
        case .drawCard: return "Drawing Cards"
        case .tableauExplained: return "The Tableau"
        case .foundationExplained: return "Foundations"
        case .dragAndDrop: return "Moving Cards"
        case .buildingSets: return "Building Sets"
        case .keepPlaying: return "Keep Playing!"
        }
    }

    var message: String {
        switch self {
        case .welcome:
            return "This tutorial lets you play a real game with just 3 geography sets. Follow along with the hints to learn all the key features!"
        case .drawCard:
            return "Tap the deck in the top-right corner to draw cards. These cards go to the waste pile on the left, where you can use them to build sequences or complete sets. Try drawing a card now!"
        case .tableauExplained:
            return "The 7 columns in the middle are the tableau. Here you can build sequences in descending order, alternating between red and black cards. This helps you organize cards and reveal hidden ones."
        case .foundationExplained:
            return "The 4 slots at the top are foundations. Each foundation holds one complete set. Start by dragging a base card (like \"UK Countries\", \"East Coast States\", or \"Indian Cities\") to a foundation, then add matching partner cards."
        case .dragAndDrop:
            return "Drag cards from the waste pile or tableau to move them. You can move single cards or entire sequences. Try moving some cards around to get a feel for it!"
        case .buildingSets:
            return "Your goal is to complete all 3 geography sets! Each set needs its base card plus all matching partner cards. When you complete a set, it celebrates! Try completing your first set now."
        case .keepPlaying:
            return "Great job! Now finish the game by completing the remaining sets. You can minimize this hint and bring it back anytime by tapping \"Show Hint\" below. When the stock is empty, tap it to reshuffle!"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .drawCard: return "square.stack.fill"
        case .tableauExplained: return "square.grid.3x3.fill"
        case .foundationExplained: return "square.stack.3d.up.fill"
        case .dragAndDrop: return "hand.point.up.left.fill"
        case .buildingSets: return "checkmark.seal.fill"
        case .keepPlaying: return "gamecontroller.fill"
        }
    }

    var buttonText: String? {
        switch self {
        case .keepPlaying: return "Got it!"
        default: return "Next"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DemoView()
    }
}
