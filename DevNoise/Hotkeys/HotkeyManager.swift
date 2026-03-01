import Foundation

final class HotkeyManager {
    private(set) var currentBindings: HotkeyBindings?

    func registerAll(bindings: HotkeyBindings) {
        currentBindings = bindings
        print("[DevNoise] HotkeyManager.registerAll called (Phase 0 skeleton)")
    }

    func unregisterAll() {
        currentBindings = nil
        print("[DevNoise] HotkeyManager.unregisterAll called (Phase 0 skeleton)")
    }
}
