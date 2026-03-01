import Foundation

final class AudioEngineManager {
    enum LifecycleStatus: String {
        case ready
        case recoveringRoute
        case sleeping
        case stoppedAfterFailure
    }

    private let graph: EngineGraph
    private let transitionController: TransitionController

    private(set) var isRunning = false
    private(set) var noiseType: NoiseType = .pink
    private(set) var depthPreset: DepthPreset = .medium
    private(set) var volume: Double = 0.6
    private(set) var lifecycleStatus: LifecycleStatus = .ready
    private(set) var lastLifecycleFailure: String?

    init() {
        graph = EngineGraph(initialNoiseType: noiseType, initialDepthPreset: depthPreset)
        transitionController = TransitionController(
            graph: graph,
            initialNoiseType: noiseType,
            initialDepthPreset: depthPreset,
            initialVolume: volume
        )
    }

    func start() {
        isRunning = true
        lifecycleStatus = .ready
        lastLifecycleFailure = nil
        transitionController.start()
    }

    func stop() {
        performStop(updateLifecycleStatus: true, usePanicStop: false)
    }

    func panicStop() {
        performStop(updateLifecycleStatus: false, usePanicStop: true)
        lifecycleStatus = .ready
    }

    func setNoiseType(_ type: NoiseType) {
        noiseType = type
        transitionController.setNoiseType(type)
    }

    func setDepthPreset(_ preset: DepthPreset) {
        depthPreset = preset
        transitionController.setDepthPreset(preset)
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0.0), 1.0)
        transitionController.setVolume(volume)
    }

    func handleOutputRouteChange(_ change: RouteObserver.RouteChange) {
        guard isRunning else {
            return
        }

        lifecycleStatus = .recoveringRoute
        stopForLifecycleTransition()

        if resumeAfterLifecycleTransition(reason: "route-change-\(change.kind.rawValue)") {
            lifecycleStatus = .ready
            return
        }

        lifecycleStatus = .stoppedAfterFailure
    }

    func handleSystemWillSleep() {
        lifecycleStatus = .sleeping
        guard isRunning else {
            return
        }
        stopForLifecycleTransition()
    }

    func handleSystemDidWake(shouldResume: Bool) {
        guard shouldResume else {
            lifecycleStatus = .ready
            return
        }

        if resumeAfterLifecycleTransition(reason: "system-wake") {
            lifecycleStatus = .ready
            return
        }

        lifecycleStatus = .stoppedAfterFailure
    }

    private func stopForLifecycleTransition() {
        performStop(updateLifecycleStatus: false, usePanicStop: false)
    }

    private func resumeAfterLifecycleTransition(reason: String) -> Bool {
        start()
        guard isRunning else {
            lastLifecycleFailure = "Failed to resume after \(reason)"
            return false
        }
        lastLifecycleFailure = nil
        return true
    }

    private func performStop(updateLifecycleStatus: Bool, usePanicStop: Bool) {
        isRunning = false
        if updateLifecycleStatus, lifecycleStatus != .stoppedAfterFailure {
            lifecycleStatus = .ready
        }

        if usePanicStop {
            transitionController.panicStop()
        } else {
            transitionController.stop()
        }
    }
}
