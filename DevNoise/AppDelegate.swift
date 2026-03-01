import AppKit
import Foundation

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store?
    private var statusBarController: StatusBarController?
    private var audioEngineManager: AudioEngineManager?
    private var routeObserver: RouteObserver?
    private var sleepWakeObserver: SleepWakeObserver?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore()
        let model = settingsStore.load()
        let audioEngineManager = AudioEngineManager()
        self.audioEngineManager = audioEngineManager

        let environment = Environment(
            audioEngine: audioEngineManager,
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
        configureLifecycleObservers(audioEngineManager: audioEngineManager)

        store.dispatch(.appLaunched)
    }

    func applicationWillTerminate(_: Notification) {
        routeObserver?.stopObserving()
        sleepWakeObserver?.stopObserving()
    }

    private func configureLifecycleObservers(audioEngineManager: AudioEngineManager) {
        let routeObserver = RouteObserver { [weak self, weak audioEngineManager] change in
            let wasRunning = audioEngineManager?.isRunning ?? false
            audioEngineManager?.handleOutputRouteChange(change)
            guard wasRunning else {
                return
            }
            let playbackState: PlaybackState = (audioEngineManager?.isRunning ?? false) ? .playing : .stopped
            self?.store?.dispatch(.syncPlaybackState(playbackState))
        }
        routeObserver.startObserving()
        self.routeObserver = routeObserver

        let sleepWakeObserver = SleepWakeObserver(
            shouldResumeProvider: { [weak audioEngineManager] in
                audioEngineManager?.isRunning ?? false
            },
            willSleepHandler: { [weak self, weak audioEngineManager] in
                let wasRunning = audioEngineManager?.isRunning ?? false
                audioEngineManager?.handleSystemWillSleep()
                if wasRunning {
                    self?.store?.dispatch(.syncPlaybackState(.stopped))
                }
            },
            didWakeHandler: { [weak self, weak audioEngineManager] shouldResume in
                audioEngineManager?.handleSystemDidWake(shouldResume: shouldResume)
                let playbackState: PlaybackState = (audioEngineManager?.isRunning ?? false) ? .playing : .stopped
                self?.store?.dispatch(.syncPlaybackState(playbackState))
            }
        )
        sleepWakeObserver.startObserving()
        self.sleepWakeObserver = sleepWakeObserver
    }
}
