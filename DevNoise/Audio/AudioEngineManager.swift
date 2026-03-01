import Foundation

final class AudioEngineManager {
    enum LifecycleStatus: String {
        case ready
        case recoveringRoute
        case sleeping
        case stoppedAfterFailure
    }

    private(set) var isRunning = false
    private(set) var noiseType: NoiseType = .pink
    private(set) var depthPreset: DepthPreset = .medium
    private(set) var volume: Double = 0.6
    private(set) var lifecycleStatus: LifecycleStatus = .ready
    private(set) var lastLifecycleFailure: String?

    func start() {
        isRunning = true
        lifecycleStatus = .ready
        lastLifecycleFailure = nil
        print("[DevNoise] AudioEngineManager.start called (silent Phase 0)")
    }

    func stop() {
        performStop(
            updateLifecycleStatus: true,
            logMessage: "[DevNoise] AudioEngineManager.stop called (silent Phase 0)"
        )
    }

    func panicStop() {
        performStop(
            updateLifecycleStatus: false,
            logMessage: "[DevNoise] AudioEngineManager.panicStop called (silent Phase 0)"
        )
        lifecycleStatus = .ready
    }

    func setNoiseType(_ type: NoiseType) {
        noiseType = type
        print("[DevNoise] AudioEngineManager.setNoiseType -> \(type.rawValue)")
    }

    func setDepthPreset(_ preset: DepthPreset) {
        depthPreset = preset
        print("[DevNoise] AudioEngineManager.setDepthPreset -> \(preset.rawValue)")
    }

    func setVolume(_ newValue: Double) {
        volume = min(max(newValue, 0.0), 1.0)
        print("[DevNoise] AudioEngineManager.setVolume -> \(volume)")
    }

    func handleOutputRouteChange(_ change: RouteObserver.RouteChange) {
        guard isRunning else {
            return
        }

        lifecycleStatus = .recoveringRoute
        print("[DevNoise] AudioEngineManager.routeChange -> \(change.kind.rawValue)")

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
        performStop(
            updateLifecycleStatus: false,
            logMessage: "[DevNoise] AudioEngineManager.stop called (lifecycle transition)"
        )
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

    private func performStop(updateLifecycleStatus: Bool, logMessage: String) {
        isRunning = false
        if updateLifecycleStatus, lifecycleStatus != .stoppedAfterFailure {
            lifecycleStatus = .ready
        }
        print(logMessage)
    }
}
