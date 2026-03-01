struct BrownNoiseChannelState {
    var prng: Xoroshiro128Plus
    var integrator: Float = 0.0
}

struct BrownNoiseGenerator: SeedableNoiseGenerator {
    var integrationStep: Float
    var leak: Float
    var gain: Float

    init(
        integrationStep: Float = 0.02,
        leak: Float = 0.9992,
        gain: Float = 3.2
    ) {
        self.integrationStep = integrationStep
        self.leak = leak
        self.gain = gain
    }

    static func makeChannelState(
        seed: UInt64,
        channelIndex: Int,
        sampleRate: Float
    ) -> BrownNoiseChannelState {
        BrownNoiseChannelState(
            prng: Xoroshiro128Plus(seed: seed, stream: UInt64(truncatingIfNeeded: channelIndex + 1))
        )
    }

    @inline(__always)
    mutating func nextSample(state: inout BrownNoiseChannelState) -> Float {
        let white = state.prng.nextFloatSigned()
        state.integrator = (state.integrator + white * integrationStep) * leak
        return hardClipUnit(state.integrator * gain)
    }
}
