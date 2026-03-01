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

    case .beginRemap(let action):
        guard model.permissions.accessibilityGranted else {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Accessibility permission is required before remapping."
            )
            return [.refreshPermissions(prompt: true)]
        }

        model.remapState = RemapState(
            mode: .listening(action: action),
            statusText: "Listening for \(action.title)... Press a new shortcut (Esc cancels)."
        )
        return []

    case .cancelRemap:
        guard model.remapState.isListening else {
            return []
        }
        model.remapState = RemapState(mode: .failure, statusText: "Remap canceled.")
        return []

    case .remapResult(let action, let chord):
        guard case .listening(let listeningAction) = model.remapState.mode,
              listeningAction == action else {
            return []
        }

        guard model.permissions.accessibilityGranted else {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Accessibility permission is not granted."
            )
            return []
        }

        guard chord.isValid else {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Invalid shortcut. Include Command or Control and avoid single-key, Option-only, and Shift-only shortcuts."
            )
            return []
        }

        if let collisionAction = collidingHotkeyAction(
            for: action,
            chord: chord,
            in: model.hotkeyBindings
        ) {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Shortcut conflicts with \(collisionAction.title)."
            )
            return []
        }

        guard model.hotkeyBindings.chord(for: action) != chord else {
            model.remapState = RemapState(
                mode: .success,
                statusText: "\(action.title) remains \(chord.displayString)."
            )
            return []
        }

        var nextBindings = model.hotkeyBindings
        nextBindings.set(chord: chord, for: action)
        guard nextBindings.validationErrors().isEmpty else {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Shortcut could not be applied."
            )
            return []
        }

        model.hotkeyBindings = nextBindings
        model.remapState = RemapState(
            mode: .success,
            statusText: "\(action.title) set to \(chord.displayString)."
        )
        return [.persistSettings, .unregisterHotkeys, .registerHotkeys(nextBindings)]

    case .remapTimeout:
        guard model.remapState.isListening else {
            return []
        }
        model.remapState = RemapState(mode: .failure, statusText: "Remap timed out after 5 seconds.")
        return []

    case .refreshPermissions(let promptIfNeeded):
        return [.refreshPermissions(prompt: promptIfNeeded)]

    case .accessibilityTrustUpdated(let isTrusted):
        model.permissions.accessibilityGranted = isTrusted
        if !isTrusted, model.remapState.isListening {
            model.remapState = RemapState(
                mode: .failure,
                statusText: "Remap stopped because accessibility permission is not granted."
            )
        }
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

private func collidingHotkeyAction(
    for actionToReplace: HotkeyAction,
    chord: HotkeyChord,
    in bindings: HotkeyBindings
) -> HotkeyAction? {
    for action in HotkeyAction.allCases where action != actionToReplace {
        if bindings.chord(for: action) == chord {
            return action
        }
    }
    return nil
}
