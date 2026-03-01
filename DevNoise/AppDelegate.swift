import AppKit
import Combine
import Foundation

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store?
    private var statusBarController: StatusBarController?
    private var remapStateObserver: AnyCancellable?

    private var activeRemapAction: HotkeyAction?
    private var localRemapMonitor: Any?
    private var globalRemapMonitor: Any?
    private var remapTimeoutTimer: Timer?

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
        bindRemapCapture(store: store)

        store.dispatch(.appLaunched)
    }

    func applicationWillTerminate(_: Notification) {
        stopRemapCapture()
    }

    private func bindRemapCapture(store: Store) {
        remapStateObserver = store.$model
            .map(\.remapState)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self, weak store] remapState in
                guard let self else {
                    return
                }

                switch remapState.mode {
                case .listening(let action):
                    self.startRemapCapture(for: action, store: store)
                case .idle, .success, .failure:
                    self.stopRemapCapture()
                }
            }
    }

    private func startRemapCapture(for action: HotkeyAction, store: Store?) {
        guard activeRemapAction != action else {
            return
        }

        stopRemapCapture()
        activeRemapAction = action

        localRemapMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak store] event in
            guard let self, self.activeRemapAction != nil else {
                return event
            }
            self.handleCapturedRemapEvent(event, store: store)
            return nil
        }

        globalRemapMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self, weak store] event in
            self?.handleCapturedRemapEvent(event, store: store)
        }

        remapTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak store] _ in
            store?.dispatch(.remapTimeout)
        }
    }

    private func stopRemapCapture() {
        if let localRemapMonitor {
            NSEvent.removeMonitor(localRemapMonitor)
            self.localRemapMonitor = nil
        }

        if let globalRemapMonitor {
            NSEvent.removeMonitor(globalRemapMonitor)
            self.globalRemapMonitor = nil
        }

        remapTimeoutTimer?.invalidate()
        remapTimeoutTimer = nil
        activeRemapAction = nil
    }

    private func handleCapturedRemapEvent(_ event: NSEvent, store: Store?) {
        guard let action = activeRemapAction else {
            return
        }

        if event.isARepeat {
            return
        }

        if isEscape(event) {
            store?.dispatch(.cancelRemap)
            return
        }

        let chord = HotkeyChord(
            modifiers: mapModifiers(from: event.modifierFlags),
            key: mapKey(from: event)
        )
        store?.dispatch(.remapResult(action: action, chord: chord))
    }

    private func isEscape(_ event: NSEvent) -> Bool {
        event.keyCode == 53 || event.charactersIgnoringModifiers == "\u{1B}"
    }

    private func mapModifiers(from flags: NSEvent.ModifierFlags) -> Set<HotkeyModifier> {
        let normalized = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers = Set<HotkeyModifier>()

        if normalized.contains(.command) {
            modifiers.insert(.command)
        }
        if normalized.contains(.control) {
            modifiers.insert(.control)
        }
        if normalized.contains(.option) {
            modifiers.insert(.option)
        }
        if normalized.contains(.shift) {
            modifiers.insert(.shift)
        }

        return modifiers
    }

    private func mapKey(from event: NSEvent) -> String {
        switch Int(event.keyCode) {
        case 36:
            return "Return"
        case 48:
            return "Tab"
        case 49:
            return "Space"
        case 51:
            return "Delete"
        case 117:
            return "ForwardDelete"
        case 123:
            return "Left"
        case 124:
            return "Right"
        case 125:
            return "Down"
        case 126:
            return "Up"
        default:
            break
        }

        guard let characters = event.charactersIgnoringModifiers,
              !characters.isEmpty else {
            return "KeyCode\(event.keyCode)"
        }

        if characters.count == 1 {
            return characters.uppercased()
        }
        return characters
    }
}
