import Foundation

final class AudioEngineManager {
    private(set) var isRunning = false
    private(set) var noiseType: NoiseType = .pink
    private(set) var depthPreset: DepthPreset = .medium
    private(set) var volume: Double = 0.6

    func start() {
        isRunning = true
        print("[DevNoise] AudioEngineManager.start called (silent Phase 0)")
    }

    func stop() {
        isRunning = false
        print("[DevNoise] AudioEngineManager.stop called (silent Phase 0)")
    }

    func panicStop() {
        isRunning = false
        print("[DevNoise] AudioEngineManager.panicStop called (silent Phase 0)")
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
}
