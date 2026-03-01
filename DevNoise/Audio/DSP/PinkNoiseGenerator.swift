struct PinkNoiseChannelState {
    var prng: Xoroshiro128Plus
    var b0: Float = 0.0
    var b1: Float = 0.0
    var b2: Float = 0.0
    var b3: Float = 0.0
    var b4: Float = 0.0
    var b5: Float = 0.0
    var b6: Float = 0.0
}

struct PinkNoiseGenerator: SeedableNoiseGenerator {
    var gain: Float

    init(gain: Float = 0.11) {
        self.gain = gain
    }

    static func makeChannelState(
        seed: UInt64,
        channelIndex: Int,
        sampleRate: Float
    ) -> PinkNoiseChannelState {
        PinkNoiseChannelState(
            prng: Xoroshiro128Plus(seed: seed, stream: UInt64(truncatingIfNeeded: channelIndex + 1))
        )
    }

    @inline(__always)
    mutating func nextSample(state: inout PinkNoiseChannelState) -> Float {
        let white = state.prng.nextFloatSigned()

        // Paul Kellet's compact pinking filter.
        state.b0 = 0.99886 * state.b0 + white * 0.0555179
        state.b1 = 0.99332 * state.b1 + white * 0.0750759
        state.b2 = 0.96900 * state.b2 + white * 0.1538520
        state.b3 = 0.86650 * state.b3 + white * 0.3104856
        state.b4 = 0.55000 * state.b4 + white * 0.5329522
        state.b5 = -0.7616 * state.b5 - white * 0.0168980

        let sample = state.b0 + state.b1 + state.b2 + state.b3 + state.b4 + state.b5 + state.b6 + white * 0.5362
        state.b6 = white * 0.115926
        return hardClipUnit(sample * gain)
    }
}
