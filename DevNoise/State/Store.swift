import Combine
import Foundation

final class Store: ObservableObject {
    @Published private(set) var model: AppModel

    private let environment: Environment

    init(initialModel: AppModel, environment: Environment) {
        self.model = initialModel
        self.environment = environment
    }

    func dispatch(_ action: Action) {
        var draft = model
        let effects = reduce(model: &draft, action: action)
        if draft != model {
            model = draft
        }
        run(effects)
    }

    private func run(_ effects: [Effect]) {
        for effect in effects {
            run(effect)
        }
    }

    private func run(_ effect: Effect) {
        switch effect {
        case .persistSettings:
            environment.settingsStore.save(model: model)

        case .resetPersistedSettings:
            environment.settingsStore.resetToDefaults()

        case .audioStart:
            environment.audioEngine.start()

        case .audioStop:
            environment.audioEngine.stop()

        case .audioPanicStop:
            environment.audioEngine.panicStop()

        case .audioSetNoise(let noiseType):
            environment.audioEngine.setNoiseType(noiseType)

        case .audioSetDepth(let depthPreset):
            environment.audioEngine.setDepthPreset(depthPreset)

        case .audioSetVolume(let volume):
            environment.audioEngine.setVolume(volume)

        case .registerHotkeys(let bindings):
            environment.hotkeyManager.registerAll(bindings: bindings)

        case .unregisterHotkeys:
            environment.hotkeyManager.unregisterAll()

        case .refreshPermissions(let prompt):
            let trusted = prompt
                ? environment.permissionsManager.requestAccessibilityIfNeeded()
                : environment.permissionsManager.isAccessibilityTrusted()
            dispatch(.accessibilityTrustUpdated(trusted))

        case .openAccessibilitySettings:
            _ = environment.permissionsManager.openAccessibilitySettings()

        case .openHelp:
            environment.logger("Help requested (Phase 0 placeholder).")

        case .quitApp:
            environment.terminateApp()
        }
    }
}
