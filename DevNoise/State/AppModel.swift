import Foundation

enum PlaybackState: String, Codable, Equatable {
    case stopped
    case playing

    var playStopTitle: String {
        switch self {
        case .stopped:
            return "Play"
        case .playing:
            return "Stop"
        }
    }
}

enum NoiseType: String, CaseIterable, Codable, Equatable {
    case white
    case pink
    case brown

    var title: String {
        switch self {
        case .white:
            return "White"
        case .pink:
            return "Pink"
        case .brown:
            return "Brown"
        }
    }
}

enum DepthPreset: String, CaseIterable, Codable, Equatable {
    case normal
    case deep
    case superDeep

    // Phase 0 compatibility aliases for code paths not yet migrated.
    static var light: DepthPreset { .normal }
    static var medium: DepthPreset { .deep }

    var title: String {
        switch self {
        case .normal:
            return "Normal"
        case .deep:
            return "Deep"
        case .superDeep:
            return "Super Deep"
        }
    }
}

struct PermissionsState: Equatable {
    var accessibilityGranted: Bool

    static let `default` = PermissionsState(accessibilityGranted: false)

    var menuLine: String {
        "Permissions: \(accessibilityGranted ? "Granted" : "Not Granted")"
    }
}

enum RemapMode: Equatable {
    case idle
    case listening(action: HotkeyAction)
    case success
    case failure
}

struct RemapState: Equatable {
    var mode: RemapMode
    var statusText: String

    static let idle = RemapState(mode: .idle, statusText: "Remap idle.")

    var isListening: Bool {
        if case .listening = mode {
            return true
        }
        return false
    }
}

struct AppModel: Equatable {
    var playbackState: PlaybackState
    var noiseType: NoiseType
    var depthPreset: DepthPreset
    var volume: Double
    var permissions: PermissionsState
    var remapState: RemapState
    var hotkeyBindings: HotkeyBindings
    var tutorialDismissed: Bool

    static let defaults = AppModel(
        playbackState: .stopped,
        noiseType: .pink,
        depthPreset: .deep,
        volume: 0.6,
        permissions: .default,
        remapState: .idle,
        hotkeyBindings: .defaults,
        tutorialDismissed: false
    )

    var statusLine: String {
        if playbackState == .playing {
            return "Status: Playing \(noiseType.title) / \(depthPreset.title) / \(Int(volume * 100))%"
        }
        return "Status: Stopped"
    }
}
