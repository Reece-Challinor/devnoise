import Foundation

struct EnvelopeRamp {
    private(set) var current: Float
    private(set) var target: Float

    private var step: Float
    private var remainingSteps: Int

    init(initialValue: Float) {
        current = initialValue
        target = initialValue
        step = 0
        remainingSteps = 0
    }

    var isRamping: Bool {
        remainingSteps > 0
    }

    mutating func setTarget(_ newTarget: Float, steps: Int) {
        target = newTarget

        guard steps > 0 else {
            current = newTarget
            step = 0
            remainingSteps = 0
            return
        }

        step = (newTarget - current) / Float(steps)
        remainingSteps = steps
    }

    mutating func snap(to value: Float) {
        current = value
        target = value
        step = 0
        remainingSteps = 0
    }

    @discardableResult
    mutating func tick() -> Float {
        guard remainingSteps > 0 else {
            return current
        }

        remainingSteps -= 1
        if remainingSteps == 0 {
            current = target
            step = 0
        } else {
            current += step
        }

        return current
    }
}
