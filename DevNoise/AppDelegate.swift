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
        let hotkeyManager = HotkeyManager()

        let environment = Environment(
            audioEngine: AudioEngineManager(),
            settingsStore: settingsStore,
            hotkeyManager: hotkeyManager,
            permissionsManager: PermissionsManager(),
            logger: { message in
                NSLog("[DevNoise] %@", message)
            },
            terminateApp: {
                NSApp.terminate(nil)
            }
        )

        let store = Store(initialModel: model, environment: environment)
        store.bindHotkeyHandler(to: hotkeyManager)
        self.store = store
        statusBarController = StatusBarController(store: store)

        store.dispatch(.appLaunched)
    }
}
