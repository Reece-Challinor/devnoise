import ApplicationServices
import Carbon.HIToolbox
import Foundation

final class RemapCaptureManager {
    typealias CaptureCompletion = (Result<HotkeyChord, RemapCaptureError>) -> Void

    private static let eventMask: CGEventMask = CGEventMask(1) << CGEventType.keyDown.rawValue

    private let permissionsManager: PermissionsManager

    private var state: RemapCaptureState = .idle
    private var completion: CaptureCompletion?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var timeoutTimer: Timer?

    init(permissionsManager: PermissionsManager) {
        self.permissionsManager = permissionsManager
    }

    deinit {
        teardownCapture()
    }

    var isCapturing: Bool {
        state.isCapturing
    }

    var currentTargetAction: HotkeyAction? {
        state.currentTargetAction
    }

    func beginCapture(
        for action: HotkeyAction,
        timeout: TimeInterval = 5.0,
        completion: @escaping CaptureCompletion
    ) {
        executeOnMain {
            guard !self.state.isCapturing else {
                completion(.failure(.alreadyCapturing))
                return
            }

            guard timeout > 0 else {
                completion(.failure(.timedOut))
                return
            }

            guard self.permissionsManager.isTrustedForRemapCapture() else {
                completion(.failure(.permissionDenied))
                return
            }

            guard self.configureEventTap() else {
                completion(.failure(.eventTapUnavailable))
                return
            }

            self.state = .capturing(targetAction: action, startedAt: Date(), timeout: timeout)
            self.completion = completion
            self.startTimeoutTimer(seconds: timeout)
        }
    }

    func cancelCapture() {
        executeOnMain {
            guard self.state.isCapturing else {
                return
            }
            self.finish(with: .failure(.cancelled))
        }
    }

    private func executeOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
            return
        }
        DispatchQueue.main.async(execute: work)
    }

    private func configureEventTap() -> Bool {
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<RemapCaptureManager>.fromOpaque(userInfo).takeUnretainedValue()
            return manager.handleTapEvent(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(Self.eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source else {
            return false
        }

        eventTap = tap
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if state.isCapturing {
                finish(with: .failure(.eventTapUnavailable))
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown, state.isCapturing else {
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.keyboardEventAutorepeat) == 1 {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = modifierSet(from: event.flags)

        if keyCode == CGKeyCode(kVK_Escape), modifiers.isEmpty {
            finish(with: .failure(.cancelled))
            return Unmanaged.passUnretained(event)
        }

        guard let key = Self.keyName(for: keyCode) else {
            finish(with: .failure(.invalidChord))
            return Unmanaged.passUnretained(event)
        }

        let chord = HotkeyChord(modifiers: modifiers, key: key)
        guard chord.isValid else {
            finish(with: .failure(.invalidChord))
            return Unmanaged.passUnretained(event)
        }

        finish(with: .success(chord))
        return Unmanaged.passUnretained(event)
    }

    private func modifierSet(from flags: CGEventFlags) -> Set<HotkeyModifier> {
        var modifiers: Set<HotkeyModifier> = []

        if flags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        if flags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if flags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if flags.contains(.maskShift) {
            modifiers.insert(.shift)
        }

        return modifiers
    }

    private func startTimeoutTimer(seconds: TimeInterval) {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self, self.state.isCapturing else {
                return
            }
            self.finish(with: .failure(.timedOut))
        }

        if let timeoutTimer {
            RunLoop.main.add(timeoutTimer, forMode: .common)
        }
    }

    private func finish(with result: Result<HotkeyChord, RemapCaptureError>) {
        guard let completion else {
            teardownCapture()
            return
        }

        teardownCapture()
        completion(result)
    }

    private func teardownCapture() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        completion = nil
        state = .idle
    }

    private static func keyName(for keyCode: CGKeyCode) -> String? {
        keyMap[keyCode]
    }

    private static let keyMap: [CGKeyCode: String] = [
        CGKeyCode(kVK_ANSI_A): "A",
        CGKeyCode(kVK_ANSI_B): "B",
        CGKeyCode(kVK_ANSI_C): "C",
        CGKeyCode(kVK_ANSI_D): "D",
        CGKeyCode(kVK_ANSI_E): "E",
        CGKeyCode(kVK_ANSI_F): "F",
        CGKeyCode(kVK_ANSI_G): "G",
        CGKeyCode(kVK_ANSI_H): "H",
        CGKeyCode(kVK_ANSI_I): "I",
        CGKeyCode(kVK_ANSI_J): "J",
        CGKeyCode(kVK_ANSI_K): "K",
        CGKeyCode(kVK_ANSI_L): "L",
        CGKeyCode(kVK_ANSI_M): "M",
        CGKeyCode(kVK_ANSI_N): "N",
        CGKeyCode(kVK_ANSI_O): "O",
        CGKeyCode(kVK_ANSI_P): "P",
        CGKeyCode(kVK_ANSI_Q): "Q",
        CGKeyCode(kVK_ANSI_R): "R",
        CGKeyCode(kVK_ANSI_S): "S",
        CGKeyCode(kVK_ANSI_T): "T",
        CGKeyCode(kVK_ANSI_U): "U",
        CGKeyCode(kVK_ANSI_V): "V",
        CGKeyCode(kVK_ANSI_W): "W",
        CGKeyCode(kVK_ANSI_X): "X",
        CGKeyCode(kVK_ANSI_Y): "Y",
        CGKeyCode(kVK_ANSI_Z): "Z",
        CGKeyCode(kVK_ANSI_0): "0",
        CGKeyCode(kVK_ANSI_1): "1",
        CGKeyCode(kVK_ANSI_2): "2",
        CGKeyCode(kVK_ANSI_3): "3",
        CGKeyCode(kVK_ANSI_4): "4",
        CGKeyCode(kVK_ANSI_5): "5",
        CGKeyCode(kVK_ANSI_6): "6",
        CGKeyCode(kVK_ANSI_7): "7",
        CGKeyCode(kVK_ANSI_8): "8",
        CGKeyCode(kVK_ANSI_9): "9",
        CGKeyCode(kVK_ANSI_Minus): "-",
        CGKeyCode(kVK_ANSI_Equal): "=",
        CGKeyCode(kVK_ANSI_LeftBracket): "[",
        CGKeyCode(kVK_ANSI_RightBracket): "]",
        CGKeyCode(kVK_ANSI_Semicolon): ";",
        CGKeyCode(kVK_ANSI_Quote): "'",
        CGKeyCode(kVK_ANSI_Comma): ",",
        CGKeyCode(kVK_ANSI_Period): ".",
        CGKeyCode(kVK_ANSI_Slash): "/",
        CGKeyCode(kVK_ANSI_Backslash): "\\",
        CGKeyCode(kVK_ANSI_Grave): "`",
        CGKeyCode(kVK_Escape): "Esc",
        CGKeyCode(kVK_Return): "Return",
        CGKeyCode(kVK_Tab): "Tab",
        CGKeyCode(kVK_Space): "Space",
        CGKeyCode(kVK_Delete): "Delete",
        CGKeyCode(kVK_ForwardDelete): "ForwardDelete",
        CGKeyCode(kVK_Home): "Home",
        CGKeyCode(kVK_End): "End",
        CGKeyCode(kVK_PageUp): "PageUp",
        CGKeyCode(kVK_PageDown): "PageDown",
        CGKeyCode(kVK_LeftArrow): "Left",
        CGKeyCode(kVK_RightArrow): "Right",
        CGKeyCode(kVK_DownArrow): "Down",
        CGKeyCode(kVK_UpArrow): "Up",
        CGKeyCode(kVK_F1): "F1",
        CGKeyCode(kVK_F2): "F2",
        CGKeyCode(kVK_F3): "F3",
        CGKeyCode(kVK_F4): "F4",
        CGKeyCode(kVK_F5): "F5",
        CGKeyCode(kVK_F6): "F6",
        CGKeyCode(kVK_F7): "F7",
        CGKeyCode(kVK_F8): "F8",
        CGKeyCode(kVK_F9): "F9",
        CGKeyCode(kVK_F10): "F10",
        CGKeyCode(kVK_F11): "F11",
        CGKeyCode(kVK_F12): "F12",
        CGKeyCode(kVK_F13): "F13",
        CGKeyCode(kVK_F14): "F14",
        CGKeyCode(kVK_F15): "F15",
        CGKeyCode(kVK_F16): "F16",
        CGKeyCode(kVK_F17): "F17",
        CGKeyCode(kVK_F18): "F18",
        CGKeyCode(kVK_F19): "F19",
        CGKeyCode(kVK_F20): "F20"
    ]
}
