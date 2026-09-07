// Coordinates the transient, one-shot timer for the current playback session.
// SPDX-License-Identifier: MIT

import Foundation

/// A fixed timer choice available from the menu.
enum SessionTimerPreset: String, CaseIterable {
    case off
    case fifteenMinutes
    case twentyFiveMinutes
    case fortyFiveMinutes
    case sixtyMinutes

    /// The user-facing menu title.
    var title: String {
        switch self {
        case .off:
            return "Off"
        case .fifteenMinutes:
            return "15 Minutes"
        case .twentyFiveMinutes:
            return "25 Minutes"
        case .fortyFiveMinutes:
            return "45 Minutes"
        case .sixtyMinutes:
            return "60 Minutes"
        }
    }

    /// The preset duration, or `nil` when the timer is off.
    var duration: TimeInterval? {
        switch self {
        case .off:
            return nil
        case .fifteenMinutes:
            return 15 * 60
        case .twentyFiveMinutes:
            return 25 * 60
        case .fortyFiveMinutes:
            return 45 * 60
        case .sixtyMinutes:
            return 60 * 60
        }
    }

    /// The next choice in the fixed Off → 15 → 25 → 45 → 60 → Off cycle.
    var next: SessionTimerPreset {
        switch self {
        case .off:
            return .fifteenMinutes
        case .fifteenMinutes:
            return .twentyFiveMinutes
        case .twentyFiveMinutes:
            return .fortyFiveMinutes
        case .fortyFiveMinutes:
            return .sixtyMinutes
        case .sixtyMinutes:
            return .off
        }
    }
}

/// Owns one cancellable main-thread timer without persisting session state.
final class SessionTimer {
    typealias Schedule = (TimeInterval, @escaping () -> Void) -> (() -> Void)

    /// Called once when the current timer expires.
    var expiryHandler: (() -> Void)?

    private let now: () -> Date
    private let schedule: Schedule
    private var cancelScheduledAction: (() -> Void)?
    private var generation: UInt = 0

    /// The currently selected preset.
    private(set) var selectedPreset: SessionTimerPreset = .off

    /// The fixed local stop date shown while a timer is active.
    private(set) var stopDate: Date?

    /// Creates a timer using the main queue, or injected deterministic test hooks.
    init(
        now: @escaping () -> Date = Date.init,
        schedule: @escaping Schedule = SessionTimer.mainQueueSchedule
    ) {
        self.now = now
        self.schedule = schedule
    }

    deinit {
        cancelScheduledAction?()
    }

    /// Selects or clears a preset, returning false if playback is required first.
    @discardableResult
    func select(_ preset: SessionTimerPreset, isPlaying: Bool) -> Bool {
        if preset == .off {
            cancel()
            return true
        }

        guard isPlaying, let duration = preset.duration else {
            return false
        }

        invalidateScheduledAction()
        selectedPreset = preset
        stopDate = now().addingTimeInterval(duration)

        let scheduledGeneration = generation
        cancelScheduledAction = schedule(duration) { [weak self] in
            self?.expire(ifCurrent: scheduledGeneration)
        }
        return true
    }

    /// Advances the fixed timer cycle while playback is active.
    @discardableResult
    func cycle(isPlaying: Bool) -> Bool {
        guard isPlaying else {
            return false
        }
        return select(selectedPreset.next, isPlaying: true)
    }

    /// Cancels the current timer without affecting audio playback.
    func cancel() {
        invalidateScheduledAction()
        selectedPreset = .off
        stopDate = nil
    }

    private func invalidateScheduledAction() {
        generation &+= 1
        cancelScheduledAction?()
        cancelScheduledAction = nil
    }

    private func expire(ifCurrent scheduledGeneration: UInt) {
        guard scheduledGeneration == generation, selectedPreset != .off else {
            return
        }

        cancelScheduledAction = nil
        selectedPreset = .off
        stopDate = nil
        generation &+= 1
        expiryHandler?()
    }

    private static func mainQueueSchedule(
        after delay: TimeInterval,
        action: @escaping () -> Void
    ) -> (() -> Void) {
        let workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return { workItem.cancel() }
    }
}
