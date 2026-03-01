struct WhiteNoiseChannelState {
    var prng: Xoroshiro128Plus
}

struct WhiteNoiseGenerator: SeedableNoiseGenerator {
    static func makeChannelState(
        seed: UInt64,
        channelIndex: Int,
        sampleRate: Float
    ) -> WhiteNoiseChannelState {
        WhiteNoiseChannelState(
            prng: Xoroshiro128Plus(seed: seed, stream: UInt64(truncatingIfNeeded: channelIndex + 1))
        )
    }

    @inline(__always)
    mutating func nextSample(state: inout WhiteNoiseChannelState) -> Float {
        state.prng.nextFloatSigned()
    }
}
