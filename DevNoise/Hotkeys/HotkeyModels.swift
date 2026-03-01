import Foundation

enum HotkeyAction: String, CaseIterable, Codable {
    case playStop
    case panicStop
    case nextNoise
    case cycleDepth
    case volumeUp
    case volumeDown

    var title: String {
        switch self {
        case .playStop:
            return "Play/Stop"
        case .panicStop:
            return "Panic"
        case .nextNoise:
            return "Next Noise"
        case .cycleDepth:
            return "Cycle Depth"
        case .volumeUp:
            return "Vol Up"
        case .volumeDown:
            return "Vol Down"
        }
    }
}

enum HotkeyModifier: String, Codable, CaseIterable, Hashable {
    case command
    case control
    case option
    case shift

    var symbol: String {
        switch self {
        case .command:
            return "⌘"
        case .control:
            return "⌃"
        case .option:
            return "⌥"
        case .shift:
            return "⇧"
        }
    }
}

struct HotkeyChord: Codable, Hashable, Equatable {
    var modifiers: Set<HotkeyModifier>
    var key: String

    init(modifiers: Set<HotkeyModifier>, key: String) {
        self.modifiers = modifiers
        self.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayString: String {
        let order: [HotkeyModifier] = [.control, .option, .shift, .command]
        let modifierPart = order.filter { modifiers.contains($0) }.map(\.symbol).joined()
        return "\(modifierPart)\(key)"
    }

    var includesCommandOrControl: Bool {
        modifiers.contains(.command) || modifiers.contains(.control)
    }

    var isSingleKey: Bool {
        modifiers.isEmpty
    }

    var isOptionOnly: Bool {
        modifiers == [.option]
    }

    var isShiftOnly: Bool {
        modifiers == [.shift]
    }

    var isValid: Bool {
        guard !key.isEmpty else {
            return false
        }
        guard !isSingleKey else {
            return false
        }
        guard includesCommandOrControl else {
            return false
        }
        guard !isOptionOnly, !isShiftOnly else {
            return false
        }
        return true
    }
}

struct HotkeyBindings: Codable, Equatable {
    var playStop: HotkeyChord
    var panicStop: HotkeyChord
    var nextNoise: HotkeyChord
    var cycleDepth: HotkeyChord
    var volumeUp: HotkeyChord
    var volumeDown: HotkeyChord

    static let defaults = HotkeyBindings(
        playStop: HotkeyChord(modifiers: [.control, .command], key: "N"),
        panicStop: HotkeyChord(modifiers: [.control, .command], key: "Esc"),
        nextNoise: HotkeyChord(modifiers: [.control, .command], key: "]"),
        cycleDepth: HotkeyChord(modifiers: [.control, .command], key: "["),
        volumeUp: HotkeyChord(modifiers: [.control, .command], key: "="),
        volumeDown: HotkeyChord(modifiers: [.control, .command], key: "-")
    )

    func chord(for action: HotkeyAction) -> HotkeyChord {
        switch action {
        case .playStop:
            return playStop
        case .panicStop:
            return panicStop
        case .nextNoise:
            return nextNoise
        case .cycleDepth:
            return cycleDepth
        case .volumeUp:
            return volumeUp
        case .volumeDown:
            return volumeDown
        }
    }

    mutating func set(chord: HotkeyChord, for action: HotkeyAction) {
        switch action {
        case .playStop:
            playStop = chord
        case .panicStop:
            panicStop = chord
        case .nextNoise:
            nextNoise = chord
        case .cycleDepth:
            cycleDepth = chord
        case .volumeUp:
            volumeUp = chord
        case .volumeDown:
            volumeDown = chord
        }
    }

    func validationErrors() -> [String] {
        var errors: [String] = []

        for (action, chord) in allPairs {
            if !chord.isValid {
                errors.append("Invalid chord for \(action.rawValue)")
            }
        }

        var seen: [HotkeyChord: HotkeyAction] = [:]
        for (action, chord) in allPairs {
            if let existing = seen[chord] {
                errors.append("Collision between \(existing.rawValue) and \(action.rawValue)")
            } else {
                seen[chord] = action
            }
        }

        return errors
    }

    private var allPairs: [(HotkeyAction, HotkeyChord)] {
        [
            (.playStop, playStop),
            (.panicStop, panicStop),
            (.nextNoise, nextNoise),
            (.cycleDepth, cycleDepth),
            (.volumeUp, volumeUp),
            (.volumeDown, volumeDown)
        ]
    }
}
