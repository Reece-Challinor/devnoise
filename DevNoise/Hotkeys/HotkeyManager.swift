//
//  HotkeyManager.swift
//  DevNoise
//
//  Registers six fixed, permission-free Carbon global hotkeys.
//  SPDX-License-Identifier: MIT
//

import Carbon.HIToolbox
import Foundation

/// A fixed global shortcut and its stable Carbon identifier.
enum HotkeyAction: UInt32, CaseIterable {
    case playStop = 1
    case panicStop
    case nextNoise
    case cycleDepth
    case volumeUp
    case volumeDown

    /// The user-facing action name.
    var title: String {
        switch self {
        case .playStop:
            return "Play / Stop"
        case .panicStop:
            return "Panic Stop"
        case .nextNoise:
            return "Next Noise"
        case .cycleDepth:
            return "Cycle Depth"
        case .volumeUp:
            return "Volume Up"
        case .volumeDown:
            return "Volume Down"
        }
    }

    /// The compact shortcut label shown in the menu and documentation.
    var shortcut: String {
        "⌃⌘\(keyLabel)"
    }

    fileprivate var keyCode: UInt32 {
        switch self {
        case .playStop:
            return UInt32(kVK_ANSI_N)
        case .panicStop:
            return UInt32(kVK_Escape)
        case .nextNoise:
            return UInt32(kVK_ANSI_RightBracket)
        case .cycleDepth:
            return UInt32(kVK_ANSI_LeftBracket)
        case .volumeUp:
            return UInt32(kVK_ANSI_Equal)
        case .volumeDown:
            return UInt32(kVK_ANSI_Minus)
        }
    }

    private var keyLabel: String {
        switch self {
        case .playStop:
            return "N"
        case .panicStop:
            return "Esc"
        case .nextNoise:
            return "]"
        case .cycleDepth:
            return "["
        case .volumeUp:
            return "="
        case .volumeDown:
            return "−"
        }
    }
}

/// Owns exclusive Carbon registrations and dispatches recognized shortcut actions.
///
/// Carbon registered hotkeys report only the six declared chords. The manager does
/// not install an event tap, observe arbitrary keyboard input, or require permissions.
final class HotkeyManager {
    /// Receives a recognized fixed shortcut action.
    var actionHandler: ((HotkeyAction) -> Void)?

    private static let signature: OSType = 0x44564E53 // "DVNS"
    private static let modifiers = UInt32(controlKey | cmdKey)

    private var eventHandler: EventHandlerRef?
    private var registeredHotkeys: [HotkeyAction: EventHotKeyRef] = [:]

    deinit {
        unregisterAll()
    }

    /// Registers every fixed shortcut and returns any actions that were unavailable.
    @discardableResult
    func registerAll() -> [HotkeyAction] {
        unregisterAll()

        guard installEventHandler() else {
            return HotkeyAction.allCases
        }

        var failures: [HotkeyAction] = []
        for action in HotkeyAction.allCases {
            let identifier = EventHotKeyID(signature: Self.signature, id: action.rawValue)
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(
                action.keyCode,
                Self.modifiers,
                identifier,
                GetEventDispatcherTarget(),
                UInt32(kEventHotKeyExclusive),
                &reference
            )

            if status == noErr, let reference {
                registeredHotkeys[action] = reference
            } else {
                failures.append(action)
            }
        }
        return failures
    }

    /// Releases every Carbon registration and the shared dispatcher handler.
    func unregisterAll() {
        for reference in registeredHotkeys.values {
            UnregisterEventHotKey(reference)
        }
        registeredHotkeys.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func installEventHandler() -> Bool {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            Self.eventCallback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        return status == noErr
    }

    private static let eventCallback: EventHandlerUPP = { _, event, context in
        guard let event, let context else {
            return OSStatus(eventNotHandledErr)
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(context).takeUnretainedValue()
        return manager.handle(event)
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var identifier = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &identifier
        )

        guard status == noErr,
              identifier.signature == Self.signature,
              let action = HotkeyAction(rawValue: identifier.id),
              registeredHotkeys[action] != nil else {
            return OSStatus(eventNotHandledErr)
        }

        actionHandler?(action)
        return noErr
    }
}
