struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    @inline(__always)
    mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct Xoroshiro128Plus {
    private var s0: UInt64
    private var s1: UInt64

    init(seed: UInt64, stream: UInt64 = 0) {
        var seeder = SplitMix64(seed: seed &+ (stream &* 0x9E3779B97F4A7C15))
        s0 = seeder.nextUInt64()
        s1 = seeder.nextUInt64()

        if s0 == 0 && s1 == 0 {
            s1 = 0x9E3779B97F4A7C15
        }
    }

    @inline(__always)
    mutating func nextUInt64() -> UInt64 {
        let result = s0 &+ s1

        var nextS1 = s1 ^ s0
        let nextS0 = rotateLeft(s0, by: 55) ^ nextS1 ^ (nextS1 << 14)
        nextS1 = rotateLeft(nextS1, by: 36)

        s0 = nextS0
        s1 = nextS1
        return result
    }

    @inline(__always)
    mutating func nextFloatUnit() -> Float {
        let bits = nextUInt64() >> 40
        return Float(bits) * (1.0 / Float(1 << 24))
    }

    @inline(__always)
    mutating func nextFloatSigned() -> Float {
        (nextFloatUnit() * 2.0) - 1.0
    }
}

@inline(__always)
private func rotateLeft(_ value: UInt64, by shift: UInt64) -> UInt64 {
    (value << shift) | (value >> (64 - shift))
}
