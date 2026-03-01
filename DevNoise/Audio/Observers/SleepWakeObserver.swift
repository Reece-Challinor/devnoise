import AppKit
import Foundation

final class SleepWakeObserver {
    typealias ShouldResumeProvider = () -> Bool
    typealias SleepHandler = () -> Void
    typealias WakeHandler = (_ shouldResume: Bool) -> Void

    private let notificationCenter: NotificationCenter
    private let shouldResumeProvider: ShouldResumeProvider
    private let willSleepHandler: SleepHandler
    private let didWakeHandler: WakeHandler

    private var willSleepToken: NSObjectProtocol?
    private var didWakeToken: NSObjectProtocol?
    private var wasPlayingBeforeSleep = false
    private var isObserving = false

    init(
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        shouldResumeProvider: @escaping ShouldResumeProvider,
        willSleepHandler: @escaping SleepHandler,
        didWakeHandler: @escaping WakeHandler
    ) {
        self.notificationCenter = notificationCenter
        self.shouldResumeProvider = shouldResumeProvider
        self.willSleepHandler = willSleepHandler
        self.didWakeHandler = didWakeHandler
    }

    deinit {
        stopObserving()
    }

    func startObserving() {
        guard !isObserving else {
            return
        }

        willSleepToken = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }
            wasPlayingBeforeSleep = shouldResumeProvider()
            willSleepHandler()
        }

        didWakeToken = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }
            let shouldResume = wasPlayingBeforeSleep
            wasPlayingBeforeSleep = false
            didWakeHandler(shouldResume)
        }

        isObserving = true
    }

    func stopObserving() {
        guard isObserving else {
            return
        }

        if let willSleepToken {
            notificationCenter.removeObserver(willSleepToken)
            self.willSleepToken = nil
        }

        if let didWakeToken {
            notificationCenter.removeObserver(didWakeToken)
            self.didWakeToken = nil
        }

        wasPlayingBeforeSleep = false
        isObserving = false
    }
}
