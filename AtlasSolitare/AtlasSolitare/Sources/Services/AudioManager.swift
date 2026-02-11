import Foundation
import AVFoundation
import AudioToolbox

// MARK: - SoundEffect

/// All sound effects the app can play.  Each maps to a file in Assets/Sounds/.
enum SoundEffect: String, CaseIterable {
    case flip           = "flip"
    case move           = "move"
    case dropSuccess    = "drop_success"
    case invalid        = "invalid"
    case completeGroup  = "complete_group"
    case win            = "win"
    case buttonClick    = "button_click"
    case shuffle        = "shuffle"

    var filename: String { rawValue + ".wav" }
}

// MARK: - AudioManager

/// Singleton that pre-loads and plays short sound effects.
/// Respects the user's `soundEnabled` setting.
class AudioManager {
    static let shared = AudioManager()

    /// When false, all play calls are no-ops.
    var isEnabled: Bool = true

    /// Cache of loaded AVAudioPlayer instances, keyed by effect.
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        preloadSounds()
    }

    // ─── Public API ─────────────────────────────────────────────────────────

    /// Play a sound effect.  Thread-safe; silently fails if the file is missing
    /// or the manager is disabled.
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }

        // If we have a custom sound loaded, play it
        if let player = players[effect] {
            player.currentTime = 0   // rewind so rapid successive calls work
            player.play()
            return
        }

        // Fallback to system sound for button clicks if no custom sound exists
        if effect == .buttonClick {
            playSystemClickSound()
        }
    }

    /// Play a system click sound (fallback when no custom sound file exists)
    private func playSystemClickSound() {
        // System sound ID 1104 is a standard keyboard click sound
        AudioServicesPlaySystemSound(1104)
    }

    // ─── Private ────────────────────────────────────────────────────────────

    /// Attempt to load all known sound files from the app bundle.
    /// Missing files are silently skipped (sounds are optional / placeholder).
    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[effect] = player
            } catch {
                // File exists but can't be loaded — skip silently.
            }
        }
    }
}
