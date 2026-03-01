import Foundation

final class AudioEngineManager {
    private let graph: EngineGraph
    private let transitionController: TransitionController

    private(set) var isRunning = false
    private(set) var noiseType: NoiseType = .pink
    private(set) var depthPreset: DepthPreset = .medium
    private(set) var volume: Double = 0.6

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
        transitionController.start()
    }

    func stop() {
        isRunning = false
        transitionController.stop()
    }

    func panicStop() {
        isRunning = false
        transitionController.panicStop()
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
}
