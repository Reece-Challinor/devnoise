import AppKit
import Foundation

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore()
        let model = settingsStore.load()

        let environment = Environment(
            audioEngine: AudioEngineManager(),
            settingsStore: settingsStore,
            hotkeyManager: HotkeyManager(),
            permissionsManager: PermissionsManager(),
            logger: { message in
                NSLog("[DevNoise] %@", message)
            },
            terminateApp: {
                NSApp.terminate(nil)
            }
        )

        let store = Store(initialModel: model, environment: environment)
        self.store = store
        statusBarController = StatusBarController(store: store)

        store.dispatch(.appLaunched)
    }
}
