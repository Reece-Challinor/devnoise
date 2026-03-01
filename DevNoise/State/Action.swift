import Foundation

enum Action {
    case appLaunched
    case togglePlayback
    case setNoiseType(NoiseType)
    case cycleDepthPreset
    case setDepthPreset(DepthPreset)
    case setVolume(Double)
    case setHotkey(action: HotkeyAction, chord: HotkeyChord)
    case remapShortcutsRequested
    case refreshPermissions(promptIfNeeded: Bool)
    case accessibilityTrustUpdated(Bool)
    case openAccessibilitySettings
    case resetToDefaults
    case openHelp
    case quit
}

enum Effect {
    case persistSettings
    case resetPersistedSettings
    case audioStart
    case audioStop
    case audioSetNoise(NoiseType)
    case audioSetDepth(DepthPreset)
    case audioSetVolume(Double)
    case registerHotkeys(HotkeyBindings)
    case unregisterHotkeys
    case refreshPermissions(prompt: Bool)
    case openAccessibilitySettings
    case openHelp
    case quitApp
}

struct Environment {
    let audioEngine: AudioEngineManager
    let settingsStore: SettingsStore
    let hotkeyManager: HotkeyManager
    let permissionsManager: PermissionsManager
    let logger: (String) -> Void
    let terminateApp: () -> Void
}
