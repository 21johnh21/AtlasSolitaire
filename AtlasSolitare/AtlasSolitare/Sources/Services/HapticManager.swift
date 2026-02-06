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
    private lazy var notification: UINotificationFeedbackGenerator = {
        UINotificationFeedbackGenerator()
    }()
    #endif

    private init() {}

    // ─── Public API ─────────────────────────────────────────────────────────

    /// Light tap — fired on drag start.
    func dragStart() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        impactLight.prepare()
        impactLight.impactOccurred()
        #endif
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
}
