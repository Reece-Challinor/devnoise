import AppKit
import ApplicationServices
import Foundation

final class PermissionsManager {
    func isTrustedForRemapCapture() -> Bool {
        isAccessibilityTrusted()
    }

    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrustedWithOptions(trustOptions(prompt: false))
    }

    func requestAccessibilityIfNeeded() -> Bool {
        AXIsProcessTrustedWithOptions(trustOptions(prompt: true))
    }

    @discardableResult
    func openAccessibilitySettings() -> Bool {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    @discardableResult
    func openInputMonitoringSettings() -> Bool {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    private func trustOptions(prompt: Bool) -> CFDictionary {
        [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
    }
}
