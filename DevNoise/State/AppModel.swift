//
//  AppModel.swift
//  DevNoise
//
//  Defines the complete in-memory application state and its small state helpers.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// A procedural noise algorithm available to the renderer.
enum NoiseType: String, CaseIterable {
    case white
    case pink
    case brown
    case green

    /// The user-facing name shown in the menu.
    var title: String {
        rawValue.capitalized
    }

    /// The stable real-time-safe value published to the audio renderer.
    var audioCode: Int32 {
        Int32(Self.allCases.firstIndex(of: self) ?? 0)
    }
}

/// A fixed spectral-shaping preset applied to a noise algorithm.
enum DepthPreset: String, CaseIterable {
    case normal
    case deep
    case superDeep

    /// The user-facing name shown in the menu.
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

    /// The stable real-time-safe value published to the audio renderer.
    var audioCode: Int32 {
        Int32(Self.allCases.firstIndex(of: self) ?? 0)
    }
}

/// The complete transient state used to render the status item and its menu.
///
/// Playback and errors intentionally live only in memory. `SettingsStore` persists
/// the three audio preferences and creates a stopped model on every launch.
struct AppModel: Equatable {
    var isPlaying: Bool
    var noiseType: NoiseType
    var depthPreset: DepthPreset
    var volume: Double
    var audioError: String?
    var unavailableHotkeyCount: Int

    /// The state used for first launch and Reset to Defaults.
    static let defaults = AppModel(
        isPlaying: false,
        noiseType: .pink,
        depthPreset: .deep,
        volume: 0.6,
        audioError: nil,
        unavailableHotkeyCount: 0
    )

    /// A concise summary suitable for the menu and accessibility value.
    var statusLine: String {
        guard isPlaying else {
            return "Stopped"
        }
        return "Playing \(noiseType.title) · \(depthPreset.title) · \(Int(volume * 100))%"
    }

    /// Selects the next noise algorithm, wrapping at the end of the list.
    mutating func cycleNoise() {
        noiseType = Self.next(after: noiseType, in: NoiseType.allCases)
    }

    /// Selects the next depth preset, wrapping at the end of the list.
    mutating func cycleDepth() {
        depthPreset = Self.next(after: depthPreset, in: DepthPreset.allCases)
    }

    /// Returns the current volume adjusted by `delta` and clamped to `0...1`.
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
