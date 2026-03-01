import Foundation

final class SettingsStore {
    private enum DepthPersistence {
        static let legacyLight = "light"
        static let legacyMedium = "medium"
        static let legacyDeep = "deep"
        static let currentDeep = "phase1.deep"
    }

    private enum Key {
        static let hotkeyPlayStop = "hotkeys.playStop"
        static let hotkeyPanicStop = "hotkeys.panicStop"
        static let hotkeyNextNoise = "hotkeys.nextNoise"
        static let hotkeyCycleDepth = "hotkeys.cycleDepth"
        static let hotkeyVolumeUp = "hotkeys.volumeUp"
        static let hotkeyVolumeDown = "hotkeys.volumeDown"

        static let audioNoiseType = "audio.noiseType"
        static let audioDepthPreset = "audio.depthPreset"
        static let audioVolume = "audio.volume"

        static let tutorialDismissed = "ui.tutorialDismissed"

        static let all: [String] = [
            hotkeyPlayStop,
            hotkeyPanicStop,
            hotkeyNextNoise,
            hotkeyCycleDepth,
            hotkeyVolumeUp,
            hotkeyVolumeDown,
            audioNoiseType,
            audioDepthPreset,
            audioVolume,
            tutorialDismissed
        ]
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppModel {
        var model = AppModel.defaults

        if let noiseRaw = userDefaults.string(forKey: Key.audioNoiseType),
           let noise = NoiseType(rawValue: noiseRaw) {
            model.noiseType = noise
        }

        if let depthRaw = userDefaults.string(forKey: Key.audioDepthPreset),
           let depth = decodeDepthPreset(depthRaw) {
            model.depthPreset = depth
        }

        if userDefaults.object(forKey: Key.audioVolume) != nil {
            model.volume = min(max(userDefaults.double(forKey: Key.audioVolume), 0.0), 1.0)
        }

        if userDefaults.object(forKey: Key.tutorialDismissed) != nil {
            model.tutorialDismissed = userDefaults.bool(forKey: Key.tutorialDismissed)
        }

        model.hotkeyBindings = HotkeyBindings(
            playStop: loadChord(forKey: Key.hotkeyPlayStop, fallback: HotkeyBindings.defaults.playStop),
            panicStop: loadChord(forKey: Key.hotkeyPanicStop, fallback: HotkeyBindings.defaults.panicStop),
            nextNoise: loadChord(forKey: Key.hotkeyNextNoise, fallback: HotkeyBindings.defaults.nextNoise),
            cycleDepth: loadChord(forKey: Key.hotkeyCycleDepth, fallback: HotkeyBindings.defaults.cycleDepth),
            volumeUp: loadChord(forKey: Key.hotkeyVolumeUp, fallback: HotkeyBindings.defaults.volumeUp),
            volumeDown: loadChord(forKey: Key.hotkeyVolumeDown, fallback: HotkeyBindings.defaults.volumeDown)
        )

        if !model.hotkeyBindings.validationErrors().isEmpty {
            model.hotkeyBindings = .defaults
        }

        model.playbackState = .stopped
        return model
    }

    func save(model: AppModel) {
        userDefaults.set(model.noiseType.rawValue, forKey: Key.audioNoiseType)
        userDefaults.set(encodeDepthPreset(model.depthPreset), forKey: Key.audioDepthPreset)
        userDefaults.set(model.volume, forKey: Key.audioVolume)
        userDefaults.set(model.tutorialDismissed, forKey: Key.tutorialDismissed)

        saveChord(model.hotkeyBindings.playStop, forKey: Key.hotkeyPlayStop)
        saveChord(model.hotkeyBindings.panicStop, forKey: Key.hotkeyPanicStop)
        saveChord(model.hotkeyBindings.nextNoise, forKey: Key.hotkeyNextNoise)
        saveChord(model.hotkeyBindings.cycleDepth, forKey: Key.hotkeyCycleDepth)
        saveChord(model.hotkeyBindings.volumeUp, forKey: Key.hotkeyVolumeUp)
        saveChord(model.hotkeyBindings.volumeDown, forKey: Key.hotkeyVolumeDown)
    }

    func resetToDefaults() {
        for key in Key.all {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func loadChord(forKey key: String, fallback: HotkeyChord) -> HotkeyChord {
        guard let data = userDefaults.data(forKey: key),
              let chord = try? decoder.decode(HotkeyChord.self, from: data) else {
            return fallback
        }
        return chord
    }

    private func saveChord(_ chord: HotkeyChord, forKey key: String) {
        guard let data = try? encoder.encode(chord) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }

    private func decodeDepthPreset(_ storedValue: String) -> DepthPreset? {
        switch storedValue {
        case DepthPersistence.legacyLight:
            return .normal
        case DepthPersistence.legacyMedium:
            return .deep
        case DepthPersistence.legacyDeep:
            return .superDeep
        case DepthPersistence.currentDeep:
            return .deep
        default:
            return DepthPreset(rawValue: storedValue)
        }
    }

    private func encodeDepthPreset(_ preset: DepthPreset) -> String {
        switch preset {
        case .deep:
            // Keep legacy "deep" available for one-time migration only.
            return DepthPersistence.currentDeep
        default:
            return preset.rawValue
        }
    }
}
