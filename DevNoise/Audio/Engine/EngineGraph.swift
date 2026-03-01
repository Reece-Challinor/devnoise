import AVFoundation
import Darwin
import Foundation

final class EngineGraph {
    private enum Constants {
        static let fallbackSampleRate: Double = 48_000
        static let channelCount: AVAudioChannelCount = 2
    }

    private let engine = AVAudioEngine()
    private let mixerA = AVAudioMixerNode()
    private let mixerB = AVAudioMixerNode()
    private let masterMixer = AVAudioMixerNode()

    private let rendererA: NoiseVoiceRenderer
    private let rendererB: NoiseVoiceRenderer

    private let sourceA: AVAudioSourceNode
    private let sourceB: AVAudioSourceNode

    private let renderFormat: AVAudioFormat

    let sampleRate: Double

    init(initialNoiseType: NoiseType, initialDepthPreset: DepthPreset) {
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let outputSampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : Constants.fallbackSampleRate
        let format = AVAudioFormat(
            standardFormatWithSampleRate: outputSampleRate,
            channels: Constants.channelCount
        ) ?? AVAudioFormat(
            standardFormatWithSampleRate: Constants.fallbackSampleRate,
            channels: Constants.channelCount
        )!

        renderFormat = format
        sampleRate = format.sampleRate

        let rendererA = NoiseVoiceRenderer(seedBase: 0x91E10DA5)
        let rendererB = NoiseVoiceRenderer(seedBase: 0x4F1BBCDC)
        self.rendererA = rendererA
        self.rendererB = rendererB

        sourceA = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            rendererA.render(frameCount: frameCount, audioBufferList: audioBufferList)
            return noErr
        }

        sourceB = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            rendererB.render(frameCount: frameCount, audioBufferList: audioBufferList)
            return noErr
        }

        engine.attach(sourceA)
        engine.attach(sourceB)
        engine.attach(mixerA)
        engine.attach(mixerB)
        engine.attach(masterMixer)

        engine.connect(sourceA, to: mixerA, format: format)
        engine.connect(sourceB, to: mixerB, format: format)
        engine.connect(mixerA, to: masterMixer, format: format)
        engine.connect(mixerB, to: masterMixer, format: format)
        engine.connect(masterMixer, to: engine.mainMixerNode, format: format)

        configureVoice(index: 0, noiseType: initialNoiseType, depthPreset: initialDepthPreset)
        configureVoice(index: 1, noiseType: initialNoiseType, depthPreset: initialDepthPreset)

        mixerA.outputVolume = 1
        mixerB.outputVolume = 0
        masterMixer.outputVolume = 0
    }

    var isEngineRunning: Bool {
        engine.isRunning
    }

    func startEngineIfNeeded() throws {
        guard !engine.isRunning else {
            return
        }

        engine.prepare()
        try engine.start()
    }

    func pauseEngine() {
        guard engine.isRunning else {
            return
        }

        engine.pause()
    }

    func stopEngineImmediately() {
        guard engine.isRunning else {
            return
        }

        engine.stop()
    }

    func configureVoice(index: Int, noiseType: NoiseType, depthPreset: DepthPreset) {
        renderer(for: index).setNoiseType(noiseType)
        renderer(for: index).setDepthPreset(depthPreset)
    }

    func setVoiceGain(index: Int, gain: Float) {
        mixer(for: index).outputVolume = gain.clampedUnit
    }

    func setMasterGain(_ gain: Float) {
        masterMixer.outputVolume = gain.clampedUnit
    }

    private func mixer(for index: Int) -> AVAudioMixerNode {
        index == 0 ? mixerA : mixerB
    }

    private func renderer(for index: Int) -> NoiseVoiceRenderer {
        index == 0 ? rendererA : rendererB
    }
}

private final class NoiseVoiceRenderer {
    private enum NoiseKind: Int32 {
        case white
        case pink
        case brown
        case green

        init(_ type: NoiseType) {
            switch type {
            case .white:
                self = .white
            case .pink:
                self = .pink
            case .brown:
                self = .brown
            }
        }
    }

    private enum DepthKind: Int32 {
        case light
        case medium
        case deep

        init(_ preset: DepthPreset) {
            switch preset {
            case .light:
                self = .light
            case .medium:
                self = .medium
            case .deep:
                self = .deep
            }
        }

        var parameters: DepthParameters {
            switch self {
            case .light:
                return DepthParameters(lowMix: 0.18, lowpassCoeff: 0.09, toneCoeff: 0.18, highDampen: 0.12, makeupGain: 1.0)
            case .medium:
                return DepthParameters(lowMix: 0.34, lowpassCoeff: 0.06, toneCoeff: 0.14, highDampen: 0.24, makeupGain: 1.06)
            case .deep:
                return DepthParameters(lowMix: 0.52, lowpassCoeff: 0.04, toneCoeff: 0.10, highDampen: 0.34, makeupGain: 1.12)
            }
        }
    }

    private struct DepthParameters {
        let lowMix: Float
        let lowpassCoeff: Float
        let toneCoeff: Float
        let highDampen: Float
        let makeupGain: Float
    }

    private struct ChannelState {
        var pink0: Float = 0
        var pink1: Float = 0
        var pink2: Float = 0
        var pink3: Float = 0
        var pink4: Float = 0
        var pink5: Float = 0
        var pink6: Float = 0

        var brown: Float = 0

        var greenLow: Float = 0
        var greenBand: Float = 0

        var depthLow: Float = 0
        var depthTone: Float = 0
    }

    private struct XorShift32 {
        private var state: UInt32

        init(seed: UInt32) {
            state = seed == 0 ? 0xA341316C : seed
        }

        @inline(__always)
        mutating func nextSignedUnit() -> Float {
            var value = state
            value ^= value << 13
            value ^= value >> 17
            value ^= value << 5
            state = value == 0 ? 0xA341316C : value

            let normalized = Float(value) / Float(UInt32.max)
            return (normalized * 2) - 1
        }
    }

    private let noiseKindRaw = AtomicInt32(NoiseKind.pink.rawValue)
    private let depthKindRaw = AtomicInt32(DepthKind.medium.rawValue)

    private var leftPRNG: XorShift32
    private var rightPRNG: XorShift32

    private var leftState = ChannelState()
    private var rightState = ChannelState()

    init(seedBase: UInt32) {
        leftPRNG = XorShift32(seed: seedBase)
        rightPRNG = XorShift32(seed: seedBase ^ 0x9E3779B9)
    }

    func setNoiseType(_ type: NoiseType) {
        noiseKindRaw.store(NoiseKind(type).rawValue)
    }

    func setDepthPreset(_ preset: DepthPreset) {
        depthKindRaw.store(DepthKind(preset).rawValue)
    }

    func render(frameCount: AVAudioFrameCount, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        let noise = NoiseKind(rawValue: noiseKindRaw.load()) ?? .pink
        let depth = DepthKind(rawValue: depthKindRaw.load()) ?? .medium

        let frameCountInt = Int(frameCount)
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

        guard !buffers.isEmpty else {
            return
        }

        if buffers.count == 1 {
            guard let data = buffers[0].mData else {
                return
            }

            let channels = Int(buffers[0].mNumberChannels)
            guard channels > 0 else {
                return
            }

            let samples = data.assumingMemoryBound(to: Float.self)
            for frame in 0 ..< frameCountInt {
                let left = nextSample(noise: noise, depth: depth, state: &leftState, prng: &leftPRNG)
                if channels == 1 {
                    samples[frame] = left
                } else {
                    let right = nextSample(noise: noise, depth: depth, state: &rightState, prng: &rightPRNG)
                    let base = frame * channels
                    samples[base] = left
                    samples[base + 1] = right
                    if channels > 2 {
                        for channel in 2 ..< channels {
                            samples[base + channel] = 0
                        }
                    }
                }
            }
            return
        }

        guard let leftData = buffers[0].mData,
              let rightData = buffers.count > 1 ? buffers[1].mData : nil else {
            return
        }

        let leftSamples = leftData.assumingMemoryBound(to: Float.self)
        let rightSamples = rightData.assumingMemoryBound(to: Float.self)

        for frame in 0 ..< frameCountInt {
            leftSamples[frame] = nextSample(noise: noise, depth: depth, state: &leftState, prng: &leftPRNG)
            rightSamples[frame] = nextSample(noise: noise, depth: depth, state: &rightState, prng: &rightPRNG)
        }

        if buffers.count > 2 {
            for channel in 2 ..< buffers.count {
                guard let data = buffers[channel].mData else {
                    continue
                }

                let channelSamples = data.assumingMemoryBound(to: Float.self)
                for frame in 0 ..< frameCountInt {
                    channelSamples[frame] = 0
                }
            }
        }
    }

    @inline(__always)
    private func nextSample(
        noise: NoiseKind,
        depth: DepthKind,
        state: inout ChannelState,
        prng: inout XorShift32
    ) -> Float {
        let raw: Float
        switch noise {
        case .white:
            raw = prng.nextSignedUnit()
        case .pink:
            raw = pinkSample(state: &state, prng: &prng)
        case .brown:
            raw = brownSample(state: &state, prng: &prng)
        case .green:
            raw = greenSample(state: &state, prng: &prng)
        }

        let shaped = applyDepth(raw, depth: depth, state: &state)
        return shaped.clampedAudio
    }

    @inline(__always)
    private func pinkSample(state: inout ChannelState, prng: inout XorShift32) -> Float {
        let white = prng.nextSignedUnit()

        state.pink0 = 0.99886 * state.pink0 + 0.0555179 * white
        state.pink1 = 0.99332 * state.pink1 + 0.0750759 * white
        state.pink2 = 0.96900 * state.pink2 + 0.1538520 * white
        state.pink3 = 0.86650 * state.pink3 + 0.3104856 * white
        state.pink4 = 0.55000 * state.pink4 + 0.5329522 * white
        state.pink5 = -0.7616 * state.pink5 - 0.0168980 * white

        let output = state.pink0
            + state.pink1
            + state.pink2
            + state.pink3
            + state.pink4
            + state.pink5
            + state.pink6
            + white * 0.5362

        state.pink6 = white * 0.115926
        return output * 0.11
    }

    @inline(__always)
    private func brownSample(state: inout ChannelState, prng: inout XorShift32) -> Float {
        let white = prng.nextSignedUnit() * 0.045
        state.brown = (state.brown + white) / 1.045
        return state.brown * 3.6
    }

    @inline(__always)
    private func greenSample(state: inout ChannelState, prng: inout XorShift32) -> Float {
        let white = prng.nextSignedUnit()
        state.greenLow += 0.045 * (white - state.greenLow)
        let high = white - state.greenLow
        state.greenBand += 0.16 * (high - state.greenBand)
        return state.greenBand * 2.2
    }

    @inline(__always)
    private func applyDepth(_ sample: Float, depth: DepthKind, state: inout ChannelState) -> Float {
        let parameters = depth.parameters

        state.depthLow += parameters.lowpassCoeff * (sample - state.depthLow)
        let emphasized = sample * (1 - parameters.lowMix) + state.depthLow * parameters.lowMix

        state.depthTone += parameters.toneCoeff * (emphasized - state.depthTone)
        let high = emphasized - state.depthTone

        let dampedHigh = emphasized - high * parameters.highDampen
        return dampedHigh * parameters.makeupGain * 0.55
    }
}

private final class AtomicInt32 {
    private let storage: UnsafeMutablePointer<Int32>

    init(_ initialValue: Int32) {
        storage = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        storage.initialize(to: initialValue)
    }

    deinit {
        storage.deinitialize(count: 1)
        storage.deallocate()
    }

    @inline(__always)
    func load() -> Int32 {
        OSAtomicAdd32Barrier(0, storage)
    }

    @inline(__always)
    func store(_ newValue: Int32) {
        var currentValue = load()
        while !OSAtomicCompareAndSwap32Barrier(currentValue, newValue, storage) {
            currentValue = load()
        }
    }
}

private extension Float {
    var clampedUnit: Float {
        min(max(self, 0), 1)
    }

    var clampedAudio: Float {
        min(max(self, -1), 1)
    }
}
