import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - HapticManager

/// Singleton that fires haptic feedback for game interactions.
/// Respects the user's `hapticsEnabled` setting.
/// On platforms where UIKit is unavailable (e.g. macOS Catalyst previews)
/// all methods are silent no-ops.
class HapticManager {
    static let shared = HapticManager()

    /// When false, all haptic calls are no-ops.
    var isEnabled: Bool = true

    // ─── Generators (lazily created) ────────────────────────────────────────
    #if canImport(UIKit)
    private lazy var impactLight:   UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()
    private lazy var impactMedium:  UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .medium)
    }()
    private lazy var impactHeavy:   UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .heavy)
    }()
    private lazy var impactRigid:   UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .rigid)
    }()
    private lazy var notification: UINotificationFeedbackGenerator = {
        UINotificationFeedbackGenerator()
    }()
    #endif

    private init() {}

    // ─── Public API ─────────────────────────────────────────────────────────

    /// Light impact — general purpose light haptic for UI interactions
    func light() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        impactLight.prepare()
        impactLight.impactOccurred()
        #endif
    }

    /// Light tap — fired on drag start.
    func dragStart() {
        light()
    }

    /// Medium tap — fired on successful card placement.
    func dropSuccess() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        impactMedium.prepare()
        impactMedium.impactOccurred()
        #endif
    }

    /// Error tap — fired on invalid drop.
    func dropFail() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        notification.prepare()
        notification.notificationOccurred(.error)
        #endif
    }

    /// Success notification — fired when a group is completed or the player wins.
    func success() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        notification.prepare()
        notification.notificationOccurred(.success)
        #endif
    }

    /// Group completion rumble — a series of heavy impacts creating a rumble effect
    func groupCompletionRumble() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        impactHeavy.prepare()

        // Create a rumble pattern with 4 heavy impacts
        impactHeavy.impactOccurred(intensity: 0.7)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.impactHeavy.impactOccurred(intensity: 0.9)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
            self?.impactHeavy.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.impactHeavy.impactOccurred(intensity: 0.8)
        }
        #endif
    }

    /// Win rumble — an intense series of impacts celebrating victory
    func winRumble() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        impactRigid.prepare()

        // Create an intense victory rumble with 7 impacts
        impactRigid.impactOccurred(intensity: 0.6)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 0.8)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 0.9)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 0.7)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { [weak self] in
            self?.impactRigid.impactOccurred(intensity: 0.5)
        }
        #endif
    }
}
