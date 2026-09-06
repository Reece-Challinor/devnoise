//
//  AppDelegate.swift
//  DevNoise
//
//  Coordinates the menu-bar lifecycle, commands, persistence, hotkeys, and lazy audio.
//  SPDX-License-Identifier: MIT
//

import AppKit
import Foundation

/// The application lifecycle coordinator and single owner of runtime services.
///
/// Startup order is intentional: the status item is installed before preferences
/// or hotkeys are loaded, and the audio engine is not created until Play is chosen.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    // NSApplication does not retain its delegate, and no nib assigns one in
    // this app, so main() must create, retain, and install it explicitly.
    private static var sharedDelegate: AppDelegate?

    /// Installs and retains the AppKit delegate before entering the event loop.
    static func main() {
        let delegate = AppDelegate()
        sharedDelegate = delegate
        NSApplication.shared.delegate = delegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }

    private var model = AppModel.defaults
    private let settingsStore = SettingsStore()
    private let sessionTimer = SessionTimer()

    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?
    private var audioEngine: AudioEngineManager?

    /// Whether the application model currently reports active playback.
    var isPlaying: Bool {
        model.isPlaying
    }

    /// The current transient timer choice.
    var timerPreset: SessionTimerPreset {
        model.timerPreset
    }

    /// Builds the menu-bar UI, restores preferences, and registers fixed hotkeys.
    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        sessionTimer.expiryHandler = { [weak self] in
            self?.timerExpired()
        }

        // Install visible UI first. Audio is not constructed until an explicit Play.
        let statusBarController = StatusBarController(model: model)
        self.statusBarController = statusBarController
        statusBarController.commandHandler = { [weak self] command in
            self?.handle(command)
        }

        model = settingsStore.load()

        let hotkeyManager = HotkeyManager()
        self.hotkeyManager = hotkeyManager
        hotkeyManager.actionHandler = { [weak self] action in
            guard let self else {
                return
            }
            if Thread.isMainThread {
                self.handle(action)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.handle(action)
                }
            }
        }

        model.unavailableHotkeyCount = hotkeyManager.registerAll().count
        refreshMenu()
    }

    /// Unregisters global hotkeys and immediately silences any active renderer.
    func applicationWillTerminate(_: Notification) {
        sessionTimer.cancel()
        hotkeyManager?.unregisterAll()
        audioEngine?.panicStop()
    }

    private func handle(_ command: AppCommand) {
        switch command {
        case .togglePlayback:
            togglePlayback()
        case .panicStop:
            stopImmediately()
        case .setNoise(let noiseType):
            setNoise(noiseType)
        case .setDepth(let depthPreset):
            setDepth(depthPreset)
        case .setVolume(let volume):
            setVolume(volume)
        case .setTimer(let preset):
            setTimer(preset)
        case .increaseVolume:
            setVolume(model.adjustedVolume(by: 0.05))
        case .decreaseVolume:
            setVolume(model.adjustedVolume(by: -0.05))
        case .reset:
            reset()
        case .viewLatestRelease, .viewLinkedIn:
            if let url = command.externalURL {
                NSWorkspace.shared.open(url)
            }
        case .quit:
            NSApp.terminate(nil)
        }
    }

    private func handle(_ action: HotkeyAction) {
        switch action {
        case .playStop:
            togglePlayback()
        case .panicStop:
            stopImmediately()
        case .nextNoise:
            model.cycleNoise()
            applyNoiseSelection()
        case .cycleDepth:
            model.cycleDepth()
            applyDepthSelection()
        case .volumeUp:
            setVolume(model.adjustedVolume(by: 0.05))
        case .volumeDown:
            setVolume(model.adjustedVolume(by: -0.05))
        }
    }

    private func togglePlayback() {
        if model.isPlaying {
            stopGracefully()
            return
        }

        cancelSessionTimer()
        model.safetyNotice = nil
        let engine = makeAudioEngineIfNeeded()
        do {
            try engine.start()
            model.isPlaying = true
            model.audioError = nil
        } catch {
            model.isPlaying = false
            model.audioError = "Audio unavailable — check your output device"
        }
        refreshMenu()
    }

    private func stopImmediately() {
        cancelSessionTimer()
        audioEngine?.panicStop()
        model.isPlaying = false
        model.audioError = nil
        refreshMenu()
    }

    private func stopGracefully() {
        cancelSessionTimer()
        audioEngine?.stop()
        model.isPlaying = false
        model.audioError = nil
        refreshMenu()
    }

    private func setNoise(_ noiseType: NoiseType) {
        guard model.noiseType != noiseType else {
            return
        }
        model.noiseType = noiseType
        applyNoiseSelection()
    }

    private func applyNoiseSelection() {
        audioEngine?.setNoiseType(model.noiseType)
        saveAndRefresh()
    }

    private func setDepth(_ depthPreset: DepthPreset) {
        guard model.depthPreset != depthPreset else {
            return
        }
        model.depthPreset = depthPreset
        applyDepthSelection()
    }

    private func applyDepthSelection() {
        audioEngine?.setDepthPreset(model.depthPreset)
        saveAndRefresh()
    }

    private func setVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 1)
        guard model.volume != clamped else {
            return
        }
        model.volume = clamped
        audioEngine?.setVolume(clamped)
        saveAndRefresh()
    }

    private func setTimer(_ preset: SessionTimerPreset) {
        guard sessionTimer.select(preset, isPlaying: model.isPlaying) else {
            return
        }
        syncSessionTimerState()
        refreshMenu()
    }

    private func timerExpired() {
        stopGracefully()
    }

    private func reset() {
        cancelSessionTimer()
        audioEngine?.stop()
        settingsStore.reset()

        let unavailableHotkeyCount = model.unavailableHotkeyCount
        model = .defaults
        model.unavailableHotkeyCount = unavailableHotkeyCount

        audioEngine?.setNoiseType(model.noiseType)
        audioEngine?.setDepthPreset(model.depthPreset)
        audioEngine?.setVolume(model.volume)
        refreshMenu()
    }

    private func makeAudioEngineIfNeeded() -> AudioEngineManager {
        if let audioEngine {
            return audioEngine
        }

        let audioEngine = AudioEngineManager(
            noiseType: model.noiseType,
            depthPreset: model.depthPreset,
            volume: model.volume
        )
        audioEngine.outputChangeHandler = { [weak self] in
            guard let self else {
                return
            }
            if Thread.isMainThread {
                self.stopForOutputChange()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.stopForOutputChange()
                }
            }
        }
        self.audioEngine = audioEngine
        return audioEngine
    }

    private func stopForOutputChange() {
        cancelSessionTimer()
        model.isPlaying = false
        model.audioError = nil
        model.safetyNotice = "Audio stopped — output device changed"
        refreshMenu()
    }

    private func cancelSessionTimer() {
        sessionTimer.cancel()
        syncSessionTimerState()
    }

    private func syncSessionTimerState() {
        model.timerPreset = sessionTimer.selectedPreset
        model.timerStopDate = sessionTimer.stopDate
    }

    private func saveAndRefresh() {
        settingsStore.save(model)
        refreshMenu()
    }

    private func refreshMenu() {
        statusBarController?.update(model: model)
    }
}
