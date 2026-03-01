import Foundation

enum RemapCaptureState: Equatable {
    case idle
    case capturing(targetAction: HotkeyAction, startedAt: Date, timeout: TimeInterval)

    var isCapturing: Bool {
        if case .capturing = self {
            return true
        }
        return false
    }

    var currentTargetAction: HotkeyAction? {
        if case .capturing(let targetAction, _, _) = self {
            return targetAction
        }
        return nil
    }
}
