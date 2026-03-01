import Foundation

func reduce(model: inout AppModel, action: Action) -> [Effect] {
    switch action {
    case .appLaunched:
        return [
            .persistSettings,
            .refreshPermissions(prompt: false),
            .registerHotkeys(model.hotkeyBindings),
            .audioSetNoise(model.noiseType),
            .audioSetDepth(model.depthPreset),
            .audioSetVolume(model.volume)
        ]

    case .togglePlayback:
        if model.playbackState == .playing {
            model.playbackState = .stopped
            return [.audioStop]
        }
        model.playbackState = .playing
        return [.audioStart]

    case .panicStop:
        model.playbackState = .stopped
        return [.audioPanicStop]

    case .setNoiseType(let type):
        guard model.noiseType != type else {
            return []
        }
        model.noiseType = type
        return [.persistSettings, .audioSetNoise(type)]

    case .cycleDepthPreset:
        let presets = DepthPreset.allCases
        guard let currentIndex = presets.firstIndex(of: model.depthPreset) else {
            return []
        }
        let next = presets[(currentIndex + 1) % presets.count]
        model.depthPreset = next
        return [.persistSettings, .audioSetDepth(next)]

    case .setDepthPreset(let preset):
        guard model.depthPreset != preset else {
            return []
        }
        model.depthPreset = preset
        return [.persistSettings, .audioSetDepth(preset)]

    case .setVolume(let volume):
        let clamped = min(max(volume, 0.0), 1.0)
        guard model.volume != clamped else {
            return []
        }
        model.volume = clamped
        return [.persistSettings, .audioSetVolume(clamped)]

    case .setHotkey(let action, let chord):
        var nextBindings = model.hotkeyBindings
        nextBindings.set(chord: chord, for: action)
        guard nextBindings.validationErrors().isEmpty else {
            return []
        }
        model.hotkeyBindings = nextBindings
        return [.persistSettings, .unregisterHotkeys, .registerHotkeys(nextBindings)]

    case .remapShortcutsRequested:
        return [.refreshPermissions(prompt: true)]

    case .refreshPermissions(let promptIfNeeded):
        return [.refreshPermissions(prompt: promptIfNeeded)]

    case .accessibilityTrustUpdated(let isTrusted):
        model.permissions.accessibilityGranted = isTrusted
        return []

    case .openAccessibilitySettings:
        return [.openAccessibilitySettings]

    case .resetToDefaults:
        model = .defaults
        return [
            .resetPersistedSettings,
            .persistSettings,
            .audioStop,
            .audioSetNoise(model.noiseType),
            .audioSetDepth(model.depthPreset),
            .audioSetVolume(model.volume),
            .unregisterHotkeys,
            .registerHotkeys(model.hotkeyBindings),
            .refreshPermissions(prompt: false)
        ]

    case .openHelp:
        return [.openHelp]

    case .quit:
        return [.quitApp]
    }
}
