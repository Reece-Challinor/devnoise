import Carbon.HIToolbox
import Foundation

final class HotkeyManager {
    typealias ActionHandler = (HotkeyAction) -> Void

    var actionHandler: ActionHandler?
    private(set) var currentBindings: HotkeyBindings?

    private enum Constants {
        static let signature: OSType = 0x44564E53 // "DVNS"
    }

    private var eventHandlerRef: EventHandlerRef?
    private var activeHotkeys: [HotkeyAction: EventHotKeyRef] = [:]
    private var actionByIdentifier: [UInt32: HotkeyAction] = [:]

    deinit {
        unregisterAll()
    }

    func registerAll(bindings: HotkeyBindings) {
        unregisterAll()
        currentBindings = bindings

        guard installEventHandlerIfNeeded() else {
            return
        }

        for action in HotkeyAction.allCases {
            let chord = bindings.chord(for: action)
            guard let keyCode = KeyCodeMapper.keyCode(for: chord.key) else {
                debugLog("Skipped registration for \(action.rawValue): unsupported key '\(chord.key)'")
                continue
            }

            let hotKeyID = EventHotKeyID(
                signature: Constants.signature,
                id: identifier(for: action)
            )
            var hotKeyRef: EventHotKeyRef?

            let status = RegisterEventHotKey(
                keyCode,
                carbonModifiers(from: chord.modifiers),
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            guard status == noErr, let hotKeyRef else {
                debugLog("Failed to register \(action.rawValue) (status \(status))")
                continue
            }

            activeHotkeys[action] = hotKeyRef
            actionByIdentifier[hotKeyID.id] = action
        }
    }

    func unregisterAll() {
        for hotKeyRef in activeHotkeys.values {
            UnregisterEventHotKey(hotKeyRef)
        }

        activeHotkeys.removeAll()
        actionByIdentifier.removeAll()
        currentBindings = nil
        uninstallEventHandlerIfNeeded()
    }

    private func installEventHandlerIfNeeded() -> Bool {
        guard eventHandlerRef == nil else {
            return true
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            Self.hotKeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard status == noErr else {
            eventHandlerRef = nil
            debugLog("Failed to install event handler (status \(status))")
            return false
        }

        return true
    }

    private func uninstallEventHandlerIfNeeded() {
        guard let eventHandlerRef else {
            return
        }
        RemoveEventHandler(eventHandlerRef)
        self.eventHandlerRef = nil
    }

    private static let hotKeyEventHandler: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else {
            return noErr
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        return manager.handleHotKeyEvent(eventRef)
    }

    private func handleHotKeyEvent(_ eventRef: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard hotKeyID.signature == Constants.signature,
              let action = actionByIdentifier[hotKeyID.id] else {
            return noErr
        }

        debugLog("Triggered action: \(action.rawValue)")
        actionHandler?(action)
        return noErr
    }

    private func identifier(for action: HotkeyAction) -> UInt32 {
        switch action {
        case .playStop:
            return 1
        case .panicStop:
            return 2
        case .nextNoise:
            return 3
        case .cycleDepth:
            return 4
        case .volumeUp:
            return 5
        case .volumeDown:
            return 6
        }
    }

    private func carbonModifiers(from modifiers: Set<HotkeyModifier>) -> UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if modifiers.contains(.control) {
            flags |= UInt32(controlKey)
        }
        if modifiers.contains(.option) {
            flags |= UInt32(optionKey)
        }
        if modifiers.contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        return flags
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        NSLog("[DevNoise] %@", message)
        #endif
    }
}

private enum KeyCodeMapper {
    private static let keyCodes: [String: UInt32] = [
        "A": UInt32(kVK_ANSI_A),
        "B": UInt32(kVK_ANSI_B),
        "C": UInt32(kVK_ANSI_C),
        "D": UInt32(kVK_ANSI_D),
        "E": UInt32(kVK_ANSI_E),
        "F": UInt32(kVK_ANSI_F),
        "G": UInt32(kVK_ANSI_G),
        "H": UInt32(kVK_ANSI_H),
        "I": UInt32(kVK_ANSI_I),
        "J": UInt32(kVK_ANSI_J),
        "K": UInt32(kVK_ANSI_K),
        "L": UInt32(kVK_ANSI_L),
        "M": UInt32(kVK_ANSI_M),
        "N": UInt32(kVK_ANSI_N),
        "O": UInt32(kVK_ANSI_O),
        "P": UInt32(kVK_ANSI_P),
        "Q": UInt32(kVK_ANSI_Q),
        "R": UInt32(kVK_ANSI_R),
        "S": UInt32(kVK_ANSI_S),
        "T": UInt32(kVK_ANSI_T),
        "U": UInt32(kVK_ANSI_U),
        "V": UInt32(kVK_ANSI_V),
        "W": UInt32(kVK_ANSI_W),
        "X": UInt32(kVK_ANSI_X),
        "Y": UInt32(kVK_ANSI_Y),
        "Z": UInt32(kVK_ANSI_Z),
        "0": UInt32(kVK_ANSI_0),
        "1": UInt32(kVK_ANSI_1),
        "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3),
        "4": UInt32(kVK_ANSI_4),
        "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6),
        "7": UInt32(kVK_ANSI_7),
        "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9),
        "-": UInt32(kVK_ANSI_Minus),
        "=": UInt32(kVK_ANSI_Equal),
        "[": UInt32(kVK_ANSI_LeftBracket),
        "]": UInt32(kVK_ANSI_RightBracket),
        "\\": UInt32(kVK_ANSI_Backslash),
        ";": UInt32(kVK_ANSI_Semicolon),
        "'": UInt32(kVK_ANSI_Quote),
        ",": UInt32(kVK_ANSI_Comma),
        ".": UInt32(kVK_ANSI_Period),
        "/": UInt32(kVK_ANSI_Slash),
        "`": UInt32(kVK_ANSI_Grave),
        "SPACE": UInt32(kVK_Space),
        "TAB": UInt32(kVK_Tab),
        "RETURN": UInt32(kVK_Return),
        "ENTER": UInt32(kVK_Return),
        "ESC": UInt32(kVK_Escape),
        "ESCAPE": UInt32(kVK_Escape),
        "DELETE": UInt32(kVK_Delete),
        "FORWARDDELETE": UInt32(kVK_ForwardDelete),
        "UP": UInt32(kVK_UpArrow),
        "DOWN": UInt32(kVK_DownArrow),
        "LEFT": UInt32(kVK_LeftArrow),
        "RIGHT": UInt32(kVK_RightArrow),
        "HOME": UInt32(kVK_Home),
        "END": UInt32(kVK_End),
        "PAGEUP": UInt32(kVK_PageUp),
        "PAGEDOWN": UInt32(kVK_PageDown),
        "F1": UInt32(kVK_F1),
        "F2": UInt32(kVK_F2),
        "F3": UInt32(kVK_F3),
        "F4": UInt32(kVK_F4),
        "F5": UInt32(kVK_F5),
        "F6": UInt32(kVK_F6),
        "F7": UInt32(kVK_F7),
        "F8": UInt32(kVK_F8),
        "F9": UInt32(kVK_F9),
        "F10": UInt32(kVK_F10),
        "F11": UInt32(kVK_F11),
        "F12": UInt32(kVK_F12),
        "F13": UInt32(kVK_F13),
        "F14": UInt32(kVK_F14),
        "F15": UInt32(kVK_F15),
        "F16": UInt32(kVK_F16),
        "F17": UInt32(kVK_F17),
        "F18": UInt32(kVK_F18),
        "F19": UInt32(kVK_F19),
        "F20": UInt32(kVK_F20)
    ]

    static func keyCode(for rawKey: String) -> UInt32? {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let normalized = trimmed.count == 1
            ? trimmed.uppercased()
            : trimmed.replacingOccurrences(of: " ", with: "").uppercased()
        return keyCodes[normalized]
    }
}
