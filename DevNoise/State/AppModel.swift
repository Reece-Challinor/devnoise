import Foundation

enum NoiseType: String, CaseIterable, Codable {
    case white
    case pink
    case brown
    case green

    var title: String {
        rawValue.capitalized
    }

    var audioCode: Int32 {
        Int32(Self.allCases.firstIndex(of: self) ?? 0)
    }
}

enum DepthPreset: String, CaseIterable, Codable {
    case normal
    case deep
    case superDeep

    var title: String {
        switch self {
        case .normal:
            return "Normal"
        case .deep:
            return "Deep"
        case .superDeep:
            return "Super Deep"
        }
    }

    var audioCode: Int32 {
        Int32(Self.allCases.firstIndex(of: self) ?? 0)
    }
}

struct AppModel: Equatable {
    var isPlaying: Bool
    var noiseType: NoiseType
    var depthPreset: DepthPreset
    var volume: Double
    var audioError: String?
    var unavailableHotkeyCount: Int

    static let defaults = AppModel(
        isPlaying: false,
        noiseType: .pink,
        depthPreset: .deep,
        volume: 0.6,
        audioError: nil,
        unavailableHotkeyCount: 0
    )

    var statusLine: String {
        guard isPlaying else {
            return "Stopped"
        }
        return "Playing \(noiseType.title) · \(depthPreset.title) · \(Int(volume * 100))%"
    }

    mutating func cycleNoise() {
        noiseType = Self.next(after: noiseType, in: NoiseType.allCases)
    }

    mutating func cycleDepth() {
        depthPreset = Self.next(after: depthPreset, in: DepthPreset.allCases)
    }

    func adjustedVolume(by delta: Double) -> Double {
        min(max(volume + delta, 0), 1)
    }

    private static func next<Value: Equatable>(after current: Value, in values: [Value]) -> Value {
        guard let index = values.firstIndex(of: current), !values.isEmpty else {
            return current
        }
        return values[(index + 1) % values.count]
    }
}
