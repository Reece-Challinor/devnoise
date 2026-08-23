import Foundation

final class SettingsStore {
    static let allowedKeys: Set<String> = [
        "hotkeys.playStop",
        "hotkeys.panicStop",
        "hotkeys.nextNoise",
        "hotkeys.cycleDepth",
        "hotkeys.volumeUp",
        "hotkeys.volumeDown",
        "audio.noiseType",
        "audio.depthPreset",
        "audio.volume",
        "ui.tutorialDismissed"
    ]

    private enum Key {
        static let noiseType = "audio.noiseType"
        static let depthPreset = "audio.depthPreset"
        static let volume = "audio.volume"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppModel {
        var model = AppModel.defaults

        if let rawValue = userDefaults.string(forKey: Key.noiseType),
           let noiseType = NoiseType(rawValue: rawValue) {
            model.noiseType = noiseType
        }

        if let rawValue = userDefaults.string(forKey: Key.depthPreset),
           let depthPreset = Self.decodeDepth(rawValue) {
            model.depthPreset = depthPreset
        }

        if userDefaults.object(forKey: Key.volume) != nil {
            let volume = userDefaults.double(forKey: Key.volume)
            if volume.isFinite {
                model.volume = min(max(volume, 0), 1)
            }
        }

        // Playback and transient errors are intentionally never restored.
        model.isPlaying = false
        model.audioError = nil
        model.unavailableHotkeyCount = 0
        return model
    }

    func save(_ model: AppModel) {
        userDefaults.set(model.noiseType.rawValue, forKey: Key.noiseType)
        userDefaults.set(Self.encodeDepth(model.depthPreset), forKey: Key.depthPreset)
        userDefaults.set(min(max(model.volume, 0), 1), forKey: Key.volume)
    }

    func reset() {
        for key in Self.allowedKeys {
            userDefaults.removeObject(forKey: key)
        }
    }

    private static func decodeDepth(_ rawValue: String) -> DepthPreset? {
        switch rawValue {
        case "light":
            return .normal
        case "medium", "phase1.deep":
            return .deep
        case "deep":
            // Phase 0 used "deep" for the preset now named Super Deep.
            return .superDeep
        default:
            return DepthPreset(rawValue: rawValue)
        }
    }

    private static func encodeDepth(_ preset: DepthPreset) -> String {
        preset == .deep ? "phase1.deep" : preset.rawValue
    }
}
