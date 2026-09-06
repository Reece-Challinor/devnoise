//
//  CoreTests.swift
//  DevNoiseTests
//
//  Covers state, timers, persistence, fixed hotkeys, menu presentation, and DSP output.
//  SPDX-License-Identifier: MIT
//

import AVFoundation
import XCTest
@testable import DevNoise

/// Fast regression tests for the complete non-device-dependent application core.
final class CoreTests: XCTestCase {
    func testAppModelDefaultsAndCycles() {
        var model = AppModel.defaults

        XCTAssertFalse(model.isPlaying)
        XCTAssertEqual(model.noiseType, .pink)
        XCTAssertEqual(model.depthPreset, .deep)
        XCTAssertEqual(model.volume, 0.6, accuracy: 0.000_001)
        XCTAssertEqual(model.timerPreset, .off)
        XCTAssertNil(model.timerStopDate)
        XCTAssertNil(model.audioError)
        XCTAssertNil(model.safetyNotice)
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
            "audio.noiseType",
            "audio.depthPreset",
            "audio.volume"
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
        model.timerPreset = .sixtyMinutes
        model.timerStopDate = Date(timeIntervalSince1970: 100)
        model.audioError = "transient"
        model.safetyNotice = "transient notice"
        model.unavailableHotkeyCount = 3

        store.save(model)
        let loaded = store.load()

        XCTAssertFalse(loaded.isPlaying)
        XCTAssertEqual(loaded.noiseType, .green)
        XCTAssertEqual(loaded.depthPreset, .superDeep)
        XCTAssertEqual(loaded.volume, 0.25, accuracy: 0.000_001)
        XCTAssertEqual(loaded.timerPreset, .off)
        XCTAssertNil(loaded.timerStopDate)
        XCTAssertNil(loaded.audioError)
        XCTAssertNil(loaded.safetyNotice)
        XCTAssertEqual(loaded.unavailableHotkeyCount, 0)

        model.depthPreset = .deep
        store.save(model)
        XCTAssertEqual(defaults.string(forKey: "audio.depthPreset"), "deep")
        XCTAssertEqual(store.load().depthPreset, .deep)

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

    func testAudioPreferenceChangesLeaveTransientTimerStateIntact() {
        var model = AppModel.defaults
        let stopDate = Date(timeIntervalSince1970: 2_000)
        model.isPlaying = true
        model.timerPreset = .fifteenMinutes
        model.timerStopDate = stopDate

        model.cycleNoise()
        model.cycleDepth()
        model.volume = model.adjustedVolume(by: 0.05)

        XCTAssertEqual(model.timerPreset, .fifteenMinutes)
        XCTAssertEqual(model.timerStopDate, stopDate)
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
    func testStatusBarUsesNativeSymbolWithTextFallback() {
        let controller = StatusBarController(model: .defaults)

        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.statusItemSymbolName, "waveform")
        XCTAssertTrue(controller.hasStatusItemImage)
        XCTAssertEqual(controller.statusItemTitle, "")

        var playing = AppModel.defaults
        playing.isPlaying = true
        controller.update(model: playing)
        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.statusItemSymbolName, "waveform.circle.fill")
        XCTAssertTrue(controller.hasStatusItemImage)
        XCTAssertEqual(controller.statusItemTitle, "")
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

    func testRendererTransitionsStayFiniteAndGracefulStopReachesSilence() {
        let renderer = NoiseRenderer(noiseType: .pink, depthPreset: .deep, volume: 0.8)
        renderer.start(fresh: true)

        let startedSamples = render(renderer, frameCount: 6_000)
        XCTAssertTrue(startedSamples.allSatisfy(\.isFinite))
        XCTAssertTrue(startedSamples.allSatisfy { abs($0) <= 1 })
        XCTAssertTrue(startedSamples.contains { abs($0) > 0.000_001 })

        renderer.setVolume(0.25)
        renderer.setNoiseType(.brown)
        renderer.setDepthPreset(.superDeep)
        let transitionSamples = render(renderer, frameCount: 8_000)
        XCTAssertTrue(transitionSamples.allSatisfy(\.isFinite))
        XCTAssertTrue(transitionSamples.allSatisfy { abs($0) <= 1 })

        renderer.stop()
        let stoppingSamples = render(renderer, frameCount: 6_000)
        XCTAssertTrue(stoppingSamples.prefix(1_000).contains { abs($0) > 0.000_001 })
        XCTAssertTrue(stoppingSamples.suffix(256).allSatisfy { $0 == 0 })
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

/// Deterministic tests for the session-only one-shot timer.
final class SessionTimerTests: XCTestCase {
    func testPresetsHaveExactTitlesAndDurationsAndDefaultIsOff() {
        XCTAssertEqual(SessionTimerPreset.allCases.map(\.title), [
            "Off",
            "15 Minutes",
            "25 Minutes",
            "45 Minutes",
            "60 Minutes"
        ])
        let expectedDurations: [TimeInterval?] = [
            nil,
            15 * 60,
            25 * 60,
            45 * 60,
            60 * 60
        ]
        XCTAssertEqual(SessionTimerPreset.allCases.map(\.duration), expectedDurations)

        let timer = SessionTimer(schedule: { _, _ in {} })
        XCTAssertEqual(timer.selectedPreset, .off)
        XCTAssertNil(timer.stopDate)
    }

    func testTimerCannotScheduleOrStartAnythingWhileStopped() {
        let scheduler = TestTimerScheduler()
        let timer = SessionTimer(schedule: scheduler.schedule)
        var expiryCount = 0
        timer.expiryHandler = { expiryCount += 1 }

        XCTAssertFalse(timer.select(.twentyFiveMinutes, isPlaying: false))
        XCTAssertEqual(timer.selectedPreset, .off)
        XCTAssertNil(timer.stopDate)
        XCTAssertTrue(scheduler.entries.isEmpty)
        XCTAssertEqual(expiryCount, 0)
    }

    func testReplacingTimerRejectsStaleCallbackAndExpiresCurrentTimerOnce() {
        let startDate = Date(timeIntervalSince1970: 1_000)
        let scheduler = TestTimerScheduler()
        let timer = SessionTimer(now: { startDate }, schedule: scheduler.schedule)
        var expiryCount = 0
        timer.expiryHandler = { expiryCount += 1 }

        XCTAssertTrue(timer.select(.twentyFiveMinutes, isPlaying: true))
        XCTAssertTrue(timer.select(.fifteenMinutes, isPlaying: true))

        XCTAssertEqual(scheduler.entries.map(\.delay), [25 * 60, 15 * 60])
        XCTAssertTrue(scheduler.entries[0].isCancelled)
        XCTAssertEqual(timer.selectedPreset, .fifteenMinutes)
        XCTAssertEqual(timer.stopDate, startDate.addingTimeInterval(15 * 60))

        scheduler.fire(0)
        XCTAssertEqual(expiryCount, 0)
        XCTAssertEqual(timer.selectedPreset, .fifteenMinutes)

        scheduler.fire(1)
        scheduler.fire(1)
        XCTAssertEqual(expiryCount, 1)
        XCTAssertEqual(timer.selectedPreset, .off)
        XCTAssertNil(timer.stopDate)
    }

    func testOffAndEveryPlaybackStopPathCancelWithoutInvokingExpiry() {
        let cancellationReasons = [
            "Off",
            "manual Stop",
            "Panic Stop",
            "Reset",
            "audio failure",
            "output-device change",
            "application termination"
        ]

        for reason in cancellationReasons {
            let scheduler = TestTimerScheduler()
            let timer = SessionTimer(schedule: scheduler.schedule)
            var playbackIsActive = true
            var expiryCount = 0
            timer.expiryHandler = {
                expiryCount += 1
                playbackIsActive = false
            }

            XCTAssertTrue(timer.select(.fortyFiveMinutes, isPlaying: true), reason)
            if reason == "Off" {
                XCTAssertTrue(timer.select(.off, isPlaying: true), reason)
            } else {
                timer.cancel()
            }
            scheduler.fire(0)

            XCTAssertTrue(playbackIsActive, reason)
            XCTAssertEqual(expiryCount, 0, reason)
            XCTAssertEqual(timer.selectedPreset, .off, reason)
            XCTAssertNil(timer.stopDate, reason)
            XCTAssertTrue(scheduler.entries[0].isCancelled, reason)
        }
    }
}

/// Tests audio lifecycle generations without requiring a physical output device.
final class AudioLifecycleTests: XCTestCase {
    func testRapidStopThenPlayRejectsOldGracefulPauseCompletion() {
        var state = AudioEngineState()
        state.didStart()
        let oldStop = state.beginGracefulStop()
        XCTAssertTrue(state.canCompleteGracefulStop(oldStop))

        state.didStart()
        XCTAssertTrue(state.isPlaying)
        XCTAssertFalse(state.canCompleteGracefulStop(oldStop))
    }

    func testPanicStopInvalidatesPendingGracefulCompletion() {
        var state = AudioEngineState()
        state.didStart()
        let oldStop = state.beginGracefulStop()

        state.stopImmediately()
        XCTAssertFalse(state.isPlaying)
        XCTAssertFalse(state.canCompleteGracefulStop(oldStop))
    }

    func testDeviceChangeInvalidatesPendingGracefulCompletion() {
        var state = AudioEngineState()
        state.didStart()
        let oldStop = state.beginGracefulStop()

        XCTAssertFalse(state.configurationChanged())
        XCTAssertTrue(state.configurationNeedsRepair)
        XCTAssertFalse(state.canCompleteGracefulStop(oldStop))
    }

    func testDeviceChangeStopsWithoutRecoveryAndExplicitStartCanFollowRepair() {
        var state = AudioEngineState()
        state.didStart()

        XCTAssertTrue(state.configurationChanged())
        XCTAssertFalse(state.isPlaying)
        XCTAssertTrue(state.configurationNeedsRepair)
        XCTAssertFalse(state.configurationChanged(), "Stopped sessions must not request recovery")

        state.didRepairConfiguration()
        XCTAssertFalse(state.configurationNeedsRepair)
        XCTAssertFalse(state.isPlaying, "Repair alone must never resume playback")

        state.didStart()
        XCTAssertTrue(state.isPlaying, "A later explicit Play can start the repaired graph")
    }

    func testAudioFailureRequiresRepairAndNeverLeavesPlaybackActive() {
        var state = AudioEngineState()
        state.didStart()
        state.didFail()

        XCTAssertFalse(state.isPlaying)
        XCTAssertTrue(state.configurationNeedsRepair)
    }
}

/// Menu-level tests for timer state, transient notices, and release metadata.
final class MenuTests: XCTestCase {
    @MainActor
    func testTimerMenuIsDisabledWhileStoppedAndTracksActivePreset() throws {
        let controller = StatusBarController(model: .defaults)
        var menu = try XCTUnwrap(controller.statusMenu)
        var timerItem = try XCTUnwrap(menu.items.first { $0.title == "Timer" })

        XCTAssertFalse(timerItem.isEnabled)
        XCTAssertEqual(timerItem.submenu?.items.prefix(5).map(\.title), [
            "Off",
            "15 Minutes",
            "25 Minutes",
            "45 Minutes",
            "60 Minutes"
        ])
        XCTAssertEqual(timerItem.submenu?.items.first?.state, .on)

        var playing = AppModel.defaults
        playing.isPlaying = true
        playing.timerPreset = .twentyFiveMinutes
        playing.timerStopDate = Date(timeIntervalSince1970: 1_800_000_000)
        controller.update(model: playing)

        menu = try XCTUnwrap(controller.statusMenu)
        timerItem = try XCTUnwrap(menu.items.first { $0.title == "Timer" })
        XCTAssertTrue(timerItem.isEnabled)
        XCTAssertEqual(timerItem.submenu?.items.first { $0.title == "25 Minutes" }?.state, .on)
        XCTAssertTrue(timerItem.submenu?.items.contains { $0.title.hasPrefix("Stops at ") } == true)
    }

    @MainActor
    func testFooterUsesBundleVersionAndContainsRequiredCommands() throws {
        let controller = StatusBarController(model: .defaults)
        let menu = try XCTUnwrap(controller.statusMenu)
        let version = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )

        let versionItem = try XCTUnwrap(menu.items.first { $0.title == "Version \(version)" })
        XCTAssertFalse(versionItem.isEnabled)
        XCTAssertNotNil(menu.items.first { $0.title == "View Latest Release… ↗" }?.action)
        XCTAssertNotNil(menu.items.first { $0.title == "Made with noise by Reece ↗" }?.action)
        XCTAssertNotNil(menu.items.first { $0.title == "Quit DevNoise" }?.action)
    }

    @MainActor
    func testOutputChangeNoticeRendersAsQuietDisabledMenuText() throws {
        var model = AppModel.defaults
        model.safetyNotice = "Audio stopped — output device changed"
        let controller = StatusBarController(model: model)
        let item = try XCTUnwrap(controller.statusMenu?.items.first {
            $0.title == "Audio stopped — output device changed"
        })

        XCTAssertFalse(item.isEnabled)
    }

    func testFooterCommandsMapToFixedValidatedURLs() {
        XCTAssertEqual(
            AppCommand.viewLatestRelease.externalURL?.absoluteString,
            "https://github.com/Reece-Challinor/devnoise/releases/latest"
        )
        XCTAssertEqual(
            AppCommand.viewLinkedIn.externalURL?.absoluteString,
            "https://www.linkedin.com/in/reecechallinor/"
        )
        XCTAssertNil(AppCommand.quit.externalURL)
    }
}

private final class TestTimerScheduler {
    struct Entry {
        let delay: TimeInterval
        let action: () -> Void
        var isCancelled = false
    }

    private(set) var entries: [Entry] = []

    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> (() -> Void) {
        let index = entries.count
        entries.append(Entry(delay: delay, action: action))
        return { [weak self] in
            guard let self, self.entries.indices.contains(index) else {
                return
            }
            self.entries[index].isCancelled = true
        }
    }

    func fire(_ index: Int) {
        entries[index].action()
    }
}
