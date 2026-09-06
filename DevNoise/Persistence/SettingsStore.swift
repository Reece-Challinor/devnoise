//
//  SettingsStore.swift
//  DevNoise
//
//  Persists the three user-selected audio preferences and nothing else.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Loads and saves DevNoise preferences through an injected `UserDefaults` store.
///
/// Playback, errors, hotkey state, and user activity are never persisted.
final class SettingsStore {
    /// The complete persistence allowlist used by saves and Reset to Defaults.
    static let allowedKeys: Set<String> = [
        "audio.noiseType",
        "audio.depthPreset",
        "audio.volume"
    ]

    private enum Key {
        static let noiseType = "audio.noiseType"
        static let depthPreset = "audio.depthPreset"
        static let volume = "audio.volume"
    }

    private let userDefaults: UserDefaults

    /// Creates a store backed by standard defaults or an isolated test suite.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Loads validated preferences into an otherwise-default, stopped model.
    func load() -> AppModel {
        var model = AppModel.defaults

        if let rawValue = userDefaults.string(forKey: Key.noiseType),
           let noiseType = NoiseType(rawValue: rawValue) {
            model.noiseType = noiseType
        }

        if let rawValue = userDefaults.string(forKey: Key.depthPreset),
           let depthPreset = DepthPreset(rawValue: rawValue) {
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

    /// Saves only noise type, depth, and clamped volume.
    func save(_ model: AppModel) {
        userDefaults.set(model.noiseType.rawValue, forKey: Key.noiseType)
        userDefaults.set(model.depthPreset.rawValue, forKey: Key.depthPreset)
        userDefaults.set(min(max(model.volume, 0), 1), forKey: Key.volume)
    }

    /// Removes every DevNoise preference without touching unrelated defaults.
    func reset() {
        for key in Self.allowedKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
