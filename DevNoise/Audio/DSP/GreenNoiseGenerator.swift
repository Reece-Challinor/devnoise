import Darwin

struct GreenNoiseChannelState {
    var prng: Xoroshiro128Plus
    var fastLowPass: Float = 0.0
    var slowLowPass: Float = 0.0
    var dcBlock: Float = 0.0
    var previousBand: Float = 0.0
}

struct GreenNoiseGenerator: SeedableNoiseGenerator {
    private let fastCoefficient: Float
    private let slowCoefficient: Float
    private let dcBlockCoefficient: Float
    private let gain: Float

    init(
        sampleRate: Float = 48_000,
        lowCutoffHz: Float = 320,
        highCutoffHz: Float = 2_400,
        gain: Float = 2.4
    ) {
        fastCoefficient = Self.onePoleCoefficient(cutoffHz: highCutoffHz, sampleRate: sampleRate)
        slowCoefficient = Self.onePoleCoefficient(cutoffHz: lowCutoffHz, sampleRate: sampleRate)
        dcBlockCoefficient = 0.995
        self.gain = gain
    }

    static func makeChannelState(
        seed: UInt64,
        channelIndex: Int,
        sampleRate: Float
    ) -> GreenNoiseChannelState {
        GreenNoiseChannelState(
            prng: Xoroshiro128Plus(seed: seed, stream: UInt64(truncatingIfNeeded: channelIndex + 1))
        )
    }

    @inline(__always)
    mutating func nextSample(state: inout GreenNoiseChannelState) -> Float {
        let white = state.prng.nextFloatSigned()

        state.fastLowPass += fastCoefficient * (white - state.fastLowPass)
        state.slowLowPass += slowCoefficient * (white - state.slowLowPass)
        let band = state.fastLowPass - state.slowLowPass

        let dcFree = band - state.previousBand + dcBlockCoefficient * state.dcBlock
        state.previousBand = band
        state.dcBlock = dcFree

        return hardClipUnit(dcFree * gain)
    }

    @inline(__always)
    private static func onePoleCoefficient(cutoffHz: Float, sampleRate: Float) -> Float {
        let nyquist = sampleRate * 0.5
        let clampedCutoff = max(1.0, min(cutoffHz, nyquist * 0.99))
        return 1.0 - expf(-2.0 * Float.pi * clampedCutoff / sampleRate)
    }
}
