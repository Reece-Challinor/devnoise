//
//  LaunchTests.swift
//  DevNoiseTests
//
//  Guards the real AppKit entry point and menu-bar-only activation policy.
//  SPDX-License-Identifier: MIT
//

import AppKit
import XCTest
@testable import DevNoise

/// Tests that run inside the launched DevNoise test host.
final class LaunchTests: XCTestCase {
    // Runs inside the real app via TEST_HOST, after applicationDidFinishLaunching.
    func testAppDelegateIsInstalledAtLaunch() {
        let delegate = NSApp.delegate
        XCTAssertNotNil(
            delegate,
            "NSApp.delegate is nil: @main wiring regressed and the app is an empty event loop"
        )
        XCTAssertTrue(
            delegate is AppDelegate,
            "NSApp.delegate is not the DevNoise AppDelegate"
        )
    }

    func testAppRunsAsMenuBarOnlyAccessory() {
        XCTAssertEqual(
            NSApp.activationPolicy(),
            .accessory,
            "App should be a menu-bar-only accessory (no Dock icon)"
        )
    }

    func testLaunchIsStoppedWithoutAStoredTimer() throws {
        let delegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)

        XCTAssertFalse(delegate.isPlaying)
        XCTAssertEqual(delegate.timerPreset, .off)
    }

    func testBundleMetadataKeepsMenuBarOnlyContractAndVersion() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool, true)
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "1.0.0"
        )
    }

    @MainActor
    func testLaunchCreatesNoVisibleApplicationWindow() {
        let visibleTitledWindows = NSApp.windows.filter {
            $0.isVisible && $0.styleMask.contains(.titled)
        }
        XCTAssertTrue(
            visibleTitledWindows.isEmpty,
            "Only AppKit's borderless status-item infrastructure may be visible"
        )
    }
}
