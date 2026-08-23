import AVFoundation
import XCTest
@testable import DevNoise

final class CoreTests: XCTestCase {
    func testAppModelDefaultsAndCycles() {
        var model = AppModel.defaults

        XCTAssertFalse(model.isPlaying)
        XCTAssertEqual(model.noiseType, .pink)
        XCTAssertEqual(model.depthPreset, .deep)
        XCTAssertEqual(model.volume, 0.6, accuracy: 0.000_001)
        XCTAssertNil(model.audioError)
        XCTAssertEqual(model.unavailableHotkeyCount, 0)

        model.cycleNoise()
        model.cycleDepth()
        XCTAssertEqual(model.noiseType, .brown)
        XCTAssertEqual(model.depthPreset, .superDeep)

        for _ in 1..<NoiseType.allCases.count {
            model.cycleNoise()
        }
        for _ in 1..<DepthPreset.allCases.count {
            model.cycleDepth()
        }
        XCTAssertEqual(model.noiseType, .pink)
        XCTAssertEqual(model.depthPreset, .deep)

        XCTAssertEqual(model.adjustedVolume(by: 0.1), 0.7, accuracy: 0.000_001)
        XCTAssertEqual(model.adjustedVolume(by: 1), 1, accuracy: 0.000_001)
        XCTAssertEqual(model.adjustedVolume(by: -1), 0, accuracy: 0.000_001)
    }

    func testSettingsStoreHasExactWhitelistAndRoundTripsOnlySettings() throws {
        let expectedKeys: Set<String> = [
            "hotkeys.playStop",
            "hotkeys.panicStop",
            "hotkeys.nextNoise",
            "hotkeys.cycleDepth",
            "hotkeys.volumeUp",
            "hotkeys.volumeDown",
            "audio.noiseType",
            "audio.depthPreset",
            "audio.volume",
            "ui.tutorialDismissed"
        ]
        XCTAssertEqual(SettingsStore.allowedKeys, expectedKeys)

        let suiteName = "DevNoiseTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        var model = AppModel.defaults
        model.isPlaying = true
        model.noiseType = .green
        model.depthPreset = .superDeep
        model.volume = 0.25
        model.audioError = "transient"
        model.unavailableHotkeyCount = 3

        store.save(model)
        let loaded = store.load()

        XCTAssertFalse(loaded.isPlaying)
        XCTAssertEqual(loaded.noiseType, .green)
        XCTAssertEqual(loaded.depthPreset, .superDeep)
        XCTAssertEqual(loaded.volume, 0.25, accuracy: 0.000_001)
        XCTAssertNil(loaded.audioError)
        XCTAssertEqual(loaded.unavailableHotkeyCount, 0)

        model.depthPreset = .deep
        store.save(model)
        XCTAssertEqual(defaults.string(forKey: "audio.depthPreset"), "phase1.deep")
        XCTAssertEqual(store.load().depthPreset, .deep)

        defaults.set("deep", forKey: "audio.depthPreset")
        XCTAssertEqual(store.load().depthPreset, .superDeep)

        for key in expectedKeys {
            defaults.set("sentinel", forKey: key)
        }
        defaults.set("preserve", forKey: "outside.whitelist")
        store.reset()

        for key in expectedKeys {
            XCTAssertNil(defaults.object(forKey: key), "reset left \(key) behind")
        }
        XCTAssertEqual(defaults.string(forKey: "outside.whitelist"), "preserve")
        XCTAssertEqual(store.load(), .defaults)
    }

    func testHotkeyActionsHaveStableUniqueIdentifiersAndLabels() {
        let actions = HotkeyAction.allCases

        XCTAssertEqual(actions.map(\.rawValue), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(Set(actions.map(\.rawValue)).count, actions.count)
        XCTAssertEqual(actions.map(\.shortcut), [
            "⌃⌘N",
            "⌃⌘Esc",
            "⌃⌘]",
            "⌃⌘[",
            "⌃⌘=",
            "⌃⌘−"
        ])
    }

    @MainActor
    func testStatusBarUsesExplicitVisibleText() {
        let controller = StatusBarController(model: .defaults)

        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.statusItemTitle, "DN")

        var playing = AppModel.defaults
        playing.isPlaying = true
        controller.update(model: playing)
        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.statusItemTitle, "DN•")
    }

    func testEveryNoiseAndDepthRendersFiniteBoundedAudio() {
        for noiseType in NoiseType.allCases {
            for depthPreset in DepthPreset.allCases {
                let renderer = NoiseRenderer(
                    noiseType: noiseType,
                    depthPreset: depthPreset,
                    volume: 0.6
                )

                var stoppedSamples = render(renderer, frameCount: 256)
                XCTAssertTrue(stoppedSamples.allSatisfy { $0 == 0 })

                renderer.start(fresh: true)
                stoppedSamples = render(renderer, frameCount: 8_192)

                XCTAssertTrue(stoppedSamples.allSatisfy(\.isFinite))
                XCTAssertTrue(stoppedSamples.allSatisfy { abs($0) <= 1 })
                XCTAssertTrue(stoppedSamples.contains { abs($0) > 0.000_001 })
            }
        }
    }

    private func render(_ renderer: NoiseRenderer, frameCount: Int) -> [Float] {
        var samples = [Float](repeating: 0, count: frameCount * 2)
        samples.withUnsafeMutableBytes { bytes in
            var buffer = AudioBuffer(
                mNumberChannels: 2,
                mDataByteSize: UInt32(bytes.count),
                mData: bytes.baseAddress
            )
            withUnsafeMutablePointer(to: &buffer) { bufferPointer in
                var list = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: bufferPointer.pointee
                )
                withUnsafeMutablePointer(to: &list) { listPointer in
                    renderer.render(
                        frameCount: AVAudioFrameCount(frameCount),
                        audioBufferList: listPointer
                    )
                }
            }
        }
        return samples
    }
}
