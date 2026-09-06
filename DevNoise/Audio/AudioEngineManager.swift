//
//  AudioEngineManager.swift
//  DevNoise
//
//  Builds the lazy AVAudioEngine graph and renders all audio procedurally.
//  SPDX-License-Identifier: MIT
//

import AVFoundation
import Darwin
import Foundation

/// Owns the on-demand audio graph, output safety handling, and real-time renderer.
///
/// Creating this object does not construct or start an `AVAudioEngine`. The graph
/// is built by the first explicit `start()` call and is reused for later playback.
final class AudioEngineManager {
    /// Called on the main thread after an active output configuration changes.
    var outputChangeHandler: (() -> Void)?

    private let renderer: NoiseRenderer
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var configurationObserver: NSObjectProtocol?
    private var pauseWorkItem: DispatchWorkItem?
    private var state = AudioEngineState()

    /// Whether the renderer is currently gated on for playback.
    var isPlaying: Bool {
        state.isPlaying
    }

    /// Creates a lazy manager with the user's current audio selections.
    init(noiseType: NoiseType, depthPreset: DepthPreset, volume: Double) {
        renderer = NoiseRenderer(
            noiseType: noiseType,
            depthPreset: depthPreset,
            volume: volume
        )
    }

    deinit {
        pauseWorkItem?.cancel()
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
        }
        engine?.stop()
    }

    /// Builds the graph if necessary and fades procedural audio in.
    func start() throws {
        pauseWorkItem?.cancel()
        pauseWorkItem = nil

        if state.configurationNeedsRepair {
            resetGraph()
        }

        if engine == nil {
            try buildGraph()
            state.didRepairConfiguration()
        }

        guard let engine else {
            throw AudioEngineError.graphUnavailable
        }

        renderer.start(fresh: !engine.isRunning)
        do {
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            state.didStart()
            observeConfigurationChanges(for: engine)
        } catch {
            renderer.stop()
            state.didFail()
            throw error
        }
    }

    /// Fades audio out, then pauses the engine after the renderer reaches silence.
    func stop() {
        guard state.isPlaying else {
            return
        }

        let stopGeneration = state.beginGracefulStop()
        renderer.stop()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state.canCompleteGracefulStop(stopGeneration) else {
                return
            }
            self.engine?.pause()
        }
        pauseWorkItem?.cancel()
        pauseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: workItem)
    }

    /// Stops the engine immediately and requires the next start to begin from silence.
    func panicStop() {
        pauseWorkItem?.cancel()
        pauseWorkItem = nil
        state.stopImmediately()
        renderer.stop()
        engine?.stop()
        renderer.requireFreshStart()
    }

    /// Publishes a new noise algorithm for a click-free renderer crossfade.
    func setNoiseType(_ noiseType: NoiseType) {
        renderer.setNoiseType(noiseType)
    }

    /// Publishes a new spectral preset for a click-free renderer crossfade.
    func setDepthPreset(_ depthPreset: DepthPreset) {
        renderer.setDepthPreset(depthPreset)
    }

    /// Publishes a clamped volume target for a smooth gain ramp.
    func setVolume(_ volume: Double) {
        renderer.setVolume(volume)
    }

    private func buildGraph() throws {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: NoiseRenderer.sampleRate,
            channels: 2
        ) else {
            throw AudioEngineError.graphUnavailable
        }

        let engine = AVAudioEngine()
        let renderer = self.renderer
        let sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            renderer.render(frameCount: frameCount, audioBufferList: audioBufferList)
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1

        self.engine = engine
        self.sourceNode = sourceNode
    }

    private func observeConfigurationChanges(for engine: AVAudioEngine) {
        guard configurationObserver == nil else {
            return
        }

        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            self?.handleConfigurationChange()
        }
    }

    private func resetGraph() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
        }
        configurationObserver = nil
        engine?.stop()
        sourceNode = nil
        engine = nil
    }

    private func handleConfigurationChange() {
        let wasPlaying = state.configurationChanged()
        pauseWorkItem?.cancel()
        pauseWorkItem = nil
        renderer.stop()
        engine?.stop()
        renderer.requireFreshStart()

        if wasPlaying {
            outputChangeHandler?()
        }
    }
}

/// Tracks playback generations and whether the audio graph must be rebuilt.
struct AudioEngineState {
    private(set) var isPlaying = false
    private(set) var configurationNeedsRepair = false
    private var generation: UInt = 0

    /// Marks a successful explicit start and invalidates old stop completions.
    mutating func didStart() {
        generation &+= 1
        isPlaying = true
    }

    /// Begins a graceful stop and returns its unique completion generation.
    mutating func beginGracefulStop() -> UInt {
        generation &+= 1
        isPlaying = false
        return generation
    }

    /// Whether a delayed graceful-stop completion still belongs to this session.
    func canCompleteGracefulStop(_ stopGeneration: UInt) -> Bool {
        !isPlaying && stopGeneration == generation
    }

    /// Invalidates delayed work and marks playback stopped immediately.
    mutating func stopImmediately() {
        generation &+= 1
        isPlaying = false
    }

    /// Records a configuration change and returns whether playback was active.
    mutating func configurationChanged() -> Bool {
        let wasPlaying = isPlaying
        stopImmediately()
        configurationNeedsRepair = true
        return wasPlaying
    }

    /// Marks a newly built graph ready for the next explicit start.
    mutating func didRepairConfiguration() {
        configurationNeedsRepair = false
    }

    /// Records a start failure so the next explicit attempt rebuilds the graph.
    mutating func didFail() {
        stopImmediately()
        configurationNeedsRepair = true
    }
}

private enum AudioEngineError: Error {
    case graphUnavailable
}

/// A deterministic, allocation-free procedural noise renderer.
///
/// The main thread publishes compact atomic targets. Once rendering begins, all
/// mutable DSP state belongs exclusively to the audio render thread.
final class NoiseRenderer {
    /// The fixed graph sample rate used to derive transition durations.
    static let sampleRate: Double = 48_000

    private static let volumeScale: Float = 100_000
    private static let gainRampFrames = Int(sampleRate * 0.12)
    private static let transitionFrames = Int(sampleRate * 0.15)

    private let targetConfiguration: AtomicInt32
    private let targetVolume: AtomicInt32
    private let targetGate = AtomicInt32(0)
    private let freshStartRequested = AtomicInt32(1)

    // These two values are only touched by the main thread and published atomically together.
    private var selectedNoiseCode: Int32
    private var selectedDepthCode: Int32

    private var voiceA: NoiseVoice
    private var voiceB: NoiseVoice
    private var activeVoiceIsA = true
    private var transitionFramesRemaining = 0

    private var currentGain: Float = 0
    private var gainTarget: Float = 0
    private var gainStep: Float = 0
    private var gainFramesRemaining = 0

    /// Creates preallocated renderer state without starting playback.
    init(noiseType: NoiseType, depthPreset: DepthPreset, volume: Double) {
        selectedNoiseCode = noiseType.audioCode
        selectedDepthCode = depthPreset.audioCode
        let configuration = Self.encode(noise: noiseType.audioCode, depth: depthPreset.audioCode)

        targetConfiguration = AtomicInt32(configuration)
        targetVolume = AtomicInt32(Self.scaledVolume(volume))
        voiceA = NoiseVoice(configuration: configuration, seed: 0x91E10DA5)
        voiceB = NoiseVoice(configuration: configuration, seed: 0x4F1BBCDC)
    }

    /// Opens the renderer gate and optionally resets the gain ramp to silence.
    func start(fresh: Bool) {
        if fresh {
            freshStartRequested.store(1)
        }
        targetGate.store(1)
    }

    /// Closes the renderer gate through the normal gain ramp.
    func stop() {
        targetGate.store(0)
    }

    /// Marks the next render block as a new silent start.
    func requireFreshStart() {
        freshStartRequested.store(1)
    }

    /// Atomically publishes a new noise selection.
    func setNoiseType(_ noiseType: NoiseType) {
        selectedNoiseCode = noiseType.audioCode
        publishConfiguration()
    }

    /// Atomically publishes a new depth selection.
    func setDepthPreset(_ depthPreset: DepthPreset) {
        selectedDepthCode = depthPreset.audioCode
        publishConfiguration()
    }

    /// Atomically publishes a clamped volume target.
    func setVolume(_ volume: Double) {
        targetVolume.store(Self.scaledVolume(volume))
    }

    /// Fills the supplied Core Audio buffers without allocation, locks, I/O,
    /// Objective-C calls, or blocking work.
    func render(
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) {
        beginRenderBlock()

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let frames = Int(frameCount)
        guard frames > 0, !buffers.isEmpty else {
            return
        }

        if buffers.count == 1 {
            renderInterleaved(buffer: buffers[0], frameCount: frames)
        } else {
            renderNonInterleaved(buffers: buffers, frameCount: frames)
        }
    }

    private func beginRenderBlock() {
        if freshStartRequested.load() != 0 {
            currentGain = 0
            gainTarget = 0
            gainStep = 0
            gainFramesRemaining = 0
            freshStartRequested.store(0)
        }

        let desiredGain: Float
        if targetGate.load() == 0 {
            desiredGain = 0
        } else {
            desiredGain = Float(targetVolume.load()) / Self.volumeScale
        }

        if desiredGain != gainTarget {
            gainTarget = desiredGain
            gainFramesRemaining = Self.gainRampFrames
            gainStep = (gainTarget - currentGain) / Float(Self.gainRampFrames)
        }

        guard transitionFramesRemaining == 0 else {
            return
        }

        let configuration = targetConfiguration.load()
        let activeConfiguration = activeVoiceIsA ? voiceA.configuration : voiceB.configuration
        guard configuration != activeConfiguration else {
            return
        }

        if activeVoiceIsA {
            voiceB.configure(configuration)
        } else {
            voiceA.configure(configuration)
        }
        transitionFramesRemaining = Self.transitionFrames
    }

    private func renderInterleaved(buffer: AudioBuffer, frameCount: Int) {
        guard let data = buffer.mData else {
            return
        }

        let channelCount = Int(buffer.mNumberChannels)
        guard channelCount > 0 else {
            return
        }

        let samples = data.assumingMemoryBound(to: Float.self)
        for frame in 0 ..< frameCount {
            let output = nextFrame()
            let base = frame * channelCount
            samples[base] = output.left

            if channelCount > 1 {
                samples[base + 1] = output.right
            }
            if channelCount > 2 {
                for channel in 2 ..< channelCount {
                    samples[base + channel] = 0
                }
            }
        }
    }

    private func renderNonInterleaved(
        buffers: UnsafeMutableAudioBufferListPointer,
        frameCount: Int
    ) {
        guard let leftData = buffers[0].mData else {
            return
        }

        let leftSamples = leftData.assumingMemoryBound(to: Float.self)
        let rightSamples = buffers.count > 1
            ? buffers[1].mData?.assumingMemoryBound(to: Float.self)
            : nil

        for frame in 0 ..< frameCount {
            let output = nextFrame()
            leftSamples[frame] = output.left
            rightSamples?[frame] = output.right
        }

        if buffers.count > 2 {
            for channel in 2 ..< buffers.count {
                guard let data = buffers[channel].mData else {
                    continue
                }
                let samples = data.assumingMemoryBound(to: Float.self)
                for frame in 0 ..< frameCount {
                    samples[frame] = 0
                }
            }
        }
    }

    @inline(__always)
    private func nextFrame() -> (left: Float, right: Float) {
        let left: Float
        let right: Float

        if transitionFramesRemaining > 0 {
            let progress = Float(Self.transitionFrames - transitionFramesRemaining)
                / Float(Self.transitionFrames)
            let oldMix = 1 - progress

            if activeVoiceIsA {
                left = voiceA.nextLeft() * oldMix + voiceB.nextLeft() * progress
                right = voiceA.nextRight() * oldMix + voiceB.nextRight() * progress
            } else {
                left = voiceB.nextLeft() * oldMix + voiceA.nextLeft() * progress
                right = voiceB.nextRight() * oldMix + voiceA.nextRight() * progress
            }

            transitionFramesRemaining -= 1
            if transitionFramesRemaining == 0 {
                activeVoiceIsA.toggle()
            }
        } else if activeVoiceIsA {
            left = voiceA.nextLeft()
            right = voiceA.nextRight()
        } else {
            left = voiceB.nextLeft()
            right = voiceB.nextRight()
        }

        let gain = advanceGain()
        return (Self.clampAudio(left * gain), Self.clampAudio(right * gain))
    }

    @inline(__always)
    private func advanceGain() -> Float {
        guard gainFramesRemaining > 0 else {
            return currentGain
        }

        gainFramesRemaining -= 1
        if gainFramesRemaining == 0 {
            currentGain = gainTarget
            gainStep = 0
        } else {
            currentGain += gainStep
        }
        return currentGain
    }

    private func publishConfiguration() {
        targetConfiguration.store(Self.encode(noise: selectedNoiseCode, depth: selectedDepthCode))
    }

    private static func encode(noise: Int32, depth: Int32) -> Int32 {
        (noise & 0xFF) | ((depth & 0xFF) << 8)
    }

    private static func scaledVolume(_ volume: Double) -> Int32 {
        let clamped = min(max(volume, 0), 1)
        return Int32((clamped * Double(volumeScale)).rounded())
    }

    @inline(__always)
    private static func clampAudio(_ sample: Float) -> Float {
        min(max(sample, -1), 1)
    }
}

/// One preallocated DSP voice used as either side of a configuration crossfade.
private struct NoiseVoice {
    private enum NoiseKind: Int32 {
        case white
        case pink
        case brown
        case green
    }

    private struct DepthParameters {
        let lowMix: Float
        let lowPassCoefficient: Float
        let toneCoefficient: Float
        let highDampen: Float
        let gain: Float

        init(code: Int32) {
            switch code {
            case 0:
                self = DepthParameters(
                    lowMix: 0.18,
                    lowPassCoefficient: 0.09,
                    toneCoefficient: 0.18,
                    highDampen: 0.12,
                    gain: 0.55
                )
            case 2:
                self = DepthParameters(
                    lowMix: 0.52,
                    lowPassCoefficient: 0.04,
                    toneCoefficient: 0.10,
                    highDampen: 0.34,
                    gain: 0.62
                )
            default:
                self = DepthParameters(
                    lowMix: 0.34,
                    lowPassCoefficient: 0.06,
                    toneCoefficient: 0.14,
                    highDampen: 0.24,
                    gain: 0.58
                )
            }
        }

        private init(
            lowMix: Float,
            lowPassCoefficient: Float,
            toneCoefficient: Float,
            highDampen: Float,
            gain: Float
        ) {
            self.lowMix = lowMix
            self.lowPassCoefficient = lowPassCoefficient
            self.toneCoefficient = toneCoefficient
            self.highDampen = highDampen
            self.gain = gain
        }
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
            return Float(value) / Float(UInt32.max) * 2 - 1
        }
    }

    private(set) var configuration: Int32
    private var noiseKind: NoiseKind
    private var depth: DepthParameters
    private var leftState = ChannelState()
    private var rightState = ChannelState()
    private var leftRandom: XorShift32
    private var rightRandom: XorShift32

    init(configuration: Int32, seed: UInt32) {
        self.configuration = configuration
        noiseKind = NoiseKind(rawValue: configuration & 0xFF) ?? .pink
        depth = DepthParameters(code: (configuration >> 8) & 0xFF)
        leftRandom = XorShift32(seed: seed)
        rightRandom = XorShift32(seed: seed ^ 0x9E3779B9)
    }

    mutating func configure(_ configuration: Int32) {
        self.configuration = configuration
        noiseKind = NoiseKind(rawValue: configuration & 0xFF) ?? .pink
        depth = DepthParameters(code: (configuration >> 8) & 0xFF)
        leftState = ChannelState()
        rightState = ChannelState()
    }

    @inline(__always)
    mutating func nextLeft() -> Float {
        Self.nextSample(kind: noiseKind, depth: depth, state: &leftState, random: &leftRandom)
    }

    @inline(__always)
    mutating func nextRight() -> Float {
        Self.nextSample(kind: noiseKind, depth: depth, state: &rightState, random: &rightRandom)
    }

    @inline(__always)
    private static func nextSample(
        kind: NoiseKind,
        depth: DepthParameters,
        state: inout ChannelState,
        random: inout XorShift32
    ) -> Float {
        let raw: Float
        switch kind {
        case .white:
            raw = random.nextSignedUnit()
        case .pink:
            raw = pinkSample(state: &state, random: &random)
        case .brown:
            let white = random.nextSignedUnit() * 0.045
            state.brown = (state.brown + white) / 1.045
            raw = state.brown * 3.6
        case .green:
            let white = random.nextSignedUnit()
            state.greenLow += 0.045 * (white - state.greenLow)
            let high = white - state.greenLow
            state.greenBand += 0.16 * (high - state.greenBand)
            raw = state.greenBand * 2.2
        }

        state.depthLow += depth.lowPassCoefficient * (raw - state.depthLow)
        let emphasized = raw * (1 - depth.lowMix) + state.depthLow * depth.lowMix
        state.depthTone += depth.toneCoefficient * (emphasized - state.depthTone)
        let high = emphasized - state.depthTone
        return (emphasized - high * depth.highDampen) * depth.gain
    }

    @inline(__always)
    private static func pinkSample(
        state: inout ChannelState,
        random: inout XorShift32
    ) -> Float {
        let white = random.nextSignedUnit()
        state.pink0 = 0.99886 * state.pink0 + 0.0555179 * white
        state.pink1 = 0.99332 * state.pink1 + 0.0750759 * white
        state.pink2 = 0.96900 * state.pink2 + 0.1538520 * white
        state.pink3 = 0.86650 * state.pink3 + 0.3104856 * white
        state.pink4 = 0.55000 * state.pink4 + 0.5329522 * white
        state.pink5 = -0.7616 * state.pink5 - 0.0168980 * white

        let output = state.pink0 + state.pink1 + state.pink2
            + state.pink3 + state.pink4 + state.pink5
            + state.pink6 + white * 0.5362
        state.pink6 = white * 0.115926
        return output * 0.11
    }
}

/// A minimal atomic `Int32` publication primitive backed by Darwin OSAtomic APIs.
///
/// Storage is allocated during renderer initialization and never during rendering.
private final class AtomicInt32 {
    private let storage: UnsafeMutablePointer<Int32>

    init(_ value: Int32) {
        storage = .allocate(capacity: 1)
        storage.initialize(to: value)
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
    func store(_ value: Int32) {
        var current = load()
        while !OSAtomicCompareAndSwap32Barrier(current, value, storage) {
            current = load()
        }
    }
}
