import Foundation

final class TransitionController {
    private enum Timing {
        static let playFadeIn: TimeInterval = 0.12
        static let stopFadeOut: TimeInterval = 0.12
        static let noiseCrossfade: TimeInterval = 0.15
        static let depthCrossfade: TimeInterval = 0.1
        static let volumeRamp: TimeInterval = 0.05
        static let tickInterval: TimeInterval = 1.0 / 240.0
        static let stopGuardDelay: TimeInterval = 0.03
    }

    private let graph: EngineGraph
    private let queue = DispatchQueue(label: "com.devnoise.audio.transitions", qos: .userInitiated)

    private var timer: DispatchSourceTimer?

    private var voiceEnvelopes: [EnvelopeRamp] = [
        EnvelopeRamp(initialValue: 1),
        EnvelopeRamp(initialValue: 0)
    ]
    private var masterEnvelope = EnvelopeRamp(initialValue: 0)

    private var desiredNoiseType: NoiseType
    private var desiredDepthPreset: DepthPreset
    private var desiredVolume: Float

    private var isPlaying = false
    private var stopGeneration: UInt64 = 0

    init(
        graph: EngineGraph,
        initialNoiseType: NoiseType,
        initialDepthPreset: DepthPreset,
        initialVolume: Double
    ) {
        self.graph = graph
        desiredNoiseType = initialNoiseType
        desiredDepthPreset = initialDepthPreset
        desiredVolume = Self.clampedUnit(Float(initialVolume))

        graph.configureVoice(index: 0, noiseType: initialNoiseType, depthPreset: initialDepthPreset)
        graph.configureVoice(index: 1, noiseType: initialNoiseType, depthPreset: initialDepthPreset)
        graph.setVoiceGain(index: 0, gain: 1)
        graph.setVoiceGain(index: 1, gain: 0)
        graph.setMasterGain(0)
    }

    func start() {
        queue.async { [weak self] in
            self?.startLocked()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.stopLocked()
        }
    }

    func panicStop() {
        queue.async { [weak self] in
            self?.panicStopLocked()
        }
    }

    func setNoiseType(_ type: NoiseType) {
        queue.async { [weak self] in
            self?.setNoiseTypeLocked(type)
        }
    }

    func setDepthPreset(_ preset: DepthPreset) {
        queue.async { [weak self] in
            self?.setDepthPresetLocked(preset)
        }
    }

    func setVolume(_ volume: Double) {
        queue.async { [weak self] in
            self?.setVolumeLocked(volume)
        }
    }

    private func startLocked() {
        stopGeneration &+= 1

        let dominant = dominantVoiceIndex()
        let secondary = 1 - dominant

        graph.configureVoice(index: dominant, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)
        graph.configureVoice(index: secondary, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)

        voiceEnvelopes[dominant].snap(to: 1)
        voiceEnvelopes[secondary].snap(to: 0)
        applyCurrentVoiceGains()

        do {
            try graph.startEngineIfNeeded()
        } catch {
            isPlaying = false
            return
        }

        isPlaying = true
        masterEnvelope.setTarget(desiredVolume, steps: steps(for: Timing.playFadeIn))
        ensureTimerRunning()
    }

    private func stopLocked() {
        guard graph.isEngineRunning else {
            isPlaying = false
            masterEnvelope.snap(to: 0)
            return
        }

        isPlaying = false
        stopGeneration &+= 1
        let generation = stopGeneration

        masterEnvelope.setTarget(0, steps: steps(for: Timing.stopFadeOut))
        ensureTimerRunning()

        let delay = DispatchTimeInterval.milliseconds(Int((Timing.stopFadeOut + Timing.stopGuardDelay) * 1000))
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else {
                return
            }

            guard self.stopGeneration == generation, !self.isPlaying else {
                return
            }

            self.masterEnvelope.snap(to: 0)
            self.graph.setMasterGain(0)
            self.graph.pauseEngine()
            self.stopTimerIfIdle()
        }
    }

    private func panicStopLocked() {
        isPlaying = false
        stopGeneration &+= 1

        voiceEnvelopes[0].snap(to: 0)
        voiceEnvelopes[1].snap(to: 0)
        masterEnvelope.snap(to: 0)

        applyCurrentVoiceGains()
        graph.setMasterGain(0)
        graph.stopEngineImmediately()
        stopTimerIfIdle(force: true)
    }

    private func setNoiseTypeLocked(_ type: NoiseType) {
        desiredNoiseType = type

        guard isPlaying, graph.isEngineRunning else {
            let dominant = dominantVoiceIndex()
            let secondary = 1 - dominant
            graph.configureVoice(index: dominant, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)
            graph.configureVoice(index: secondary, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)
            return
        }

        performTimbreCrossfade(duration: Timing.noiseCrossfade)
    }

    private func setDepthPresetLocked(_ preset: DepthPreset) {
        desiredDepthPreset = preset

        guard isPlaying, graph.isEngineRunning else {
            let dominant = dominantVoiceIndex()
            let secondary = 1 - dominant
            graph.configureVoice(index: dominant, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)
            graph.configureVoice(index: secondary, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)
            return
        }

        performTimbreCrossfade(duration: Timing.depthCrossfade)
    }

    private func setVolumeLocked(_ volume: Double) {
        desiredVolume = Self.clampedUnit(Float(volume))
        let target = isPlaying ? desiredVolume : 0

        masterEnvelope.setTarget(target, steps: steps(for: Timing.volumeRamp))
        if graph.isEngineRunning {
            ensureTimerRunning()
        }
    }

    private func performTimbreCrossfade(duration: TimeInterval) {
        let source = dominantVoiceIndex()
        let destination = 1 - source

        graph.configureVoice(index: destination, noiseType: desiredNoiseType, depthPreset: desiredDepthPreset)

        let rampSteps = steps(for: duration)
        voiceEnvelopes[source].setTarget(0, steps: rampSteps)
        voiceEnvelopes[destination].setTarget(1, steps: rampSteps)

        ensureTimerRunning()
    }

    private func ensureTimerRunning() {
        guard timer == nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: Timing.tickInterval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.timer = timer
        timer.resume()
    }

    private func stopTimerIfIdle(force: Bool = false) {
        guard let timer else {
            return
        }

        let shouldStop = force || (!voiceEnvelopes[0].isRamping && !voiceEnvelopes[1].isRamping && !masterEnvelope.isRamping)
        guard shouldStop else {
            return
        }

        timer.setEventHandler {}
        timer.cancel()
        self.timer = nil
    }

    private func tick() {
        var voiceChanged = false
        var masterChanged = false

        if voiceEnvelopes[0].isRamping {
            _ = voiceEnvelopes[0].tick()
            voiceChanged = true
        }

        if voiceEnvelopes[1].isRamping {
            _ = voiceEnvelopes[1].tick()
            voiceChanged = true
        }

        if masterEnvelope.isRamping {
            _ = masterEnvelope.tick()
            masterChanged = true
        }

        if voiceChanged {
            applyCurrentVoiceGains()
        }

        if masterChanged {
            graph.setMasterGain(masterEnvelope.current)
        }

        stopTimerIfIdle()
    }

    private func applyCurrentVoiceGains() {
        graph.setVoiceGain(index: 0, gain: voiceEnvelopes[0].current)
        graph.setVoiceGain(index: 1, gain: voiceEnvelopes[1].current)
    }

    private func dominantVoiceIndex() -> Int {
        voiceEnvelopes[0].current >= voiceEnvelopes[1].current ? 0 : 1
    }

    private func steps(for duration: TimeInterval) -> Int {
        let raw = Int(round(duration / Timing.tickInterval))
        return max(1, raw)
    }

    private static func clampedUnit(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}
