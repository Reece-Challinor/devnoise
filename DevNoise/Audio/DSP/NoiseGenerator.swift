struct NoiseRenderBuffer {
    let samples: UnsafeMutablePointer<Float>
    let frameCount: Int
    let channelCount: Int
    let stride: Int

    init(
        samples: UnsafeMutablePointer<Float>,
        frameCount: Int,
        channelCount: Int,
        stride: Int
    ) {
        self.samples = samples
        self.frameCount = frameCount
        self.channelCount = channelCount
        self.stride = stride
    }
}

protocol NoiseGeneratorKernel {
    associatedtype ChannelState

    mutating func nextSample(state: inout ChannelState) -> Float
}

protocol SeedableNoiseGenerator: NoiseGeneratorKernel {
    static func makeChannelState(seed: UInt64, channelIndex: Int, sampleRate: Float) -> ChannelState
}

extension NoiseGeneratorKernel {
    @inline(__always)
    mutating func render(
        _ buffer: NoiseRenderBuffer,
        channelStates: UnsafeMutableBufferPointer<ChannelState>
    ) {
        let channelLimit = Swift.min(buffer.channelCount, channelStates.count)
        guard channelLimit > 0 else { return }

        var sampleIndex = 0
        for _ in 0..<buffer.frameCount {
            var channel = 0
            while channel < channelLimit {
                buffer.samples[sampleIndex + channel] = nextSample(state: &channelStates[channel])
                channel += 1
            }

            if channelLimit < buffer.channelCount {
                while channel < buffer.channelCount {
                    buffer.samples[sampleIndex + channel] = 0.0
                    channel += 1
                }
            }

            sampleIndex += buffer.stride
        }
    }
}

@inline(__always)
func hardClipUnit(_ sample: Float) -> Float {
    if sample > 1.0 {
        return 1.0
    }
    if sample < -1.0 {
        return -1.0
    }
    return sample
}
