import Darwin

enum DepthShapePreset: CaseIterable {
    case normal
    case deep
    case superDeep
}

struct DepthShapeParameters {
    var dryMix: Float
    var lowBoost: Float
    var highCut: Float

    static func preset(_ preset: DepthShapePreset) -> DepthShapeParameters {
        switch preset {
        case .normal:
            return DepthShapeParameters(dryMix: 1.0, lowBoost: 0.12, highCut: 0.08)
        case .deep:
            return DepthShapeParameters(dryMix: 0.90, lowBoost: 0.33, highCut: 0.20)
        case .superDeep:
            return DepthShapeParameters(dryMix: 0.76, lowBoost: 0.58, highCut: 0.38)
        }
    }
}

struct DepthFrameParameters {
    let dryMix: Float
    let lowBoost: Float
    let highCut: Float
}

struct DepthShaperChannelState {
    var lowBand: Float = 0.0
    var highBandLowPass: Float = 0.0
}

struct RampedParameter {
    private(set) var current: Float
    private var step: Float = 0.0
    private var remainingSamples: Int = 0

    init(_ value: Float) {
        current = value
    }

    mutating func setTarget(_ target: Float, rampSamples: Int) {
        if rampSamples <= 0 {
            current = target
            step = 0.0
            remainingSamples = 0
            return
        }

        step = (target - current) / Float(rampSamples)
        remainingSamples = rampSamples
    }

    @inline(__always)
    mutating func advance() -> Float {
        if remainingSamples > 0 {
            current += step
            remainingSamples -= 1
        }
        return current
    }
}

struct DepthShaper {
    private(set) var preset: DepthShapePreset
    private var dryMix: RampedParameter
    private var lowBoost: RampedParameter
    private var highCut: RampedParameter

    private let lowBandCoefficient: Float
    private let highBandCoefficient: Float

    init(
        sampleRate: Float = 48_000,
        preset: DepthShapePreset = .normal,
        lowBandCutoffHz: Float = 190,
        highBandCutoffHz: Float = 2_900
    ) {
        self.preset = preset

        let params = DepthShapeParameters.preset(preset)
        dryMix = RampedParameter(params.dryMix)
        lowBoost = RampedParameter(params.lowBoost)
        highCut = RampedParameter(params.highCut)

        lowBandCoefficient = Self.onePoleCoefficient(cutoffHz: lowBandCutoffHz, sampleRate: sampleRate)
        highBandCoefficient = Self.onePoleCoefficient(cutoffHz: highBandCutoffHz, sampleRate: sampleRate)
    }

    mutating func setPreset(_ newPreset: DepthShapePreset, rampSamples: Int) {
        preset = newPreset
        let target = DepthShapeParameters.preset(newPreset)
        dryMix.setTarget(target.dryMix, rampSamples: rampSamples)
        lowBoost.setTarget(target.lowBoost, rampSamples: rampSamples)
        highCut.setTarget(target.highCut, rampSamples: rampSamples)
    }

    @inline(__always)
    mutating func advanceFrame() -> DepthFrameParameters {
        DepthFrameParameters(
            dryMix: dryMix.advance(),
            lowBoost: lowBoost.advance(),
            highCut: highCut.advance()
        )
    }

    @inline(__always)
    func process(
        sample: Float,
        state: inout DepthShaperChannelState,
        frame: DepthFrameParameters
    ) -> Float {
        state.lowBand += lowBandCoefficient * (sample - state.lowBand)
        state.highBandLowPass += highBandCoefficient * (sample - state.highBandLowPass)

        let highBand = sample - state.highBandLowPass
        let shaped = sample * frame.dryMix + state.lowBand * frame.lowBoost - highBand * frame.highCut
        return hardClipUnit(shaped)
    }

    mutating func processInterleaved(
        _ buffer: NoiseRenderBuffer,
        channelStates: UnsafeMutableBufferPointer<DepthShaperChannelState>
    ) {
        let channelLimit = Swift.min(buffer.channelCount, channelStates.count)
        guard channelLimit > 0 else { return }

        var sampleIndex = 0
        for _ in 0..<buffer.frameCount {
            let frameParams = advanceFrame()

            var channel = 0
            while channel < channelLimit {
                let input = buffer.samples[sampleIndex + channel]
                buffer.samples[sampleIndex + channel] = process(
                    sample: input,
                    state: &channelStates[channel],
                    frame: frameParams
                )
                channel += 1
            }

            sampleIndex += buffer.stride
        }
    }

    @inline(__always)
    private static func onePoleCoefficient(cutoffHz: Float, sampleRate: Float) -> Float {
        let nyquist = sampleRate * 0.5
        let clampedCutoff = max(1.0, min(cutoffHz, nyquist * 0.99))
        return 1.0 - expf(-2.0 * Float.pi * clampedCutoff / sampleRate)
    }
}
