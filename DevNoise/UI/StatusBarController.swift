//
//  StatusBarController.swift
//  DevNoise
//
//  Renders the accessible menu-bar icon and the complete command menu.
//  SPDX-License-Identifier: MIT
//

import AppKit
import Foundation

/// A user action emitted by the menu and handled by the lifecycle coordinator.
enum AppCommand {
    case togglePlayback
    case panicStop
    case setNoise(NoiseType)
    case setDepth(DepthPreset)
    case setVolume(Double)
    case setTimer(SessionTimerPreset)
    case increaseVolume
    case decreaseVolume
    case reset
    case viewLatestRelease
    case viewLinkedIn
    case quit

    /// The fixed external destination for an explicitly selected footer command.
    var externalURL: URL? {
        switch self {
        case .viewLatestRelease:
            return URL(string: "https://github.com/Reece-Challinor/devnoise/releases/latest")
        case .viewLinkedIn:
            return URL(string: "https://www.linkedin.com/in/reecechallinor/")
        default:
            return nil
        }
    }
}

/// Owns DevNoise's single status item and rebuilds its menu from `AppModel`.
///
/// The icon is a native template symbol so macOS controls its contrast in light,
/// dark, active, and inactive menu-bar appearances. A text fallback remains for
/// systems that cannot load the requested symbol.
final class StatusBarController: NSObject {
    private enum Symbol {
        static let stopped = "waveform"
        static let playing = "waveform.circle.fill"
    }

    /// Receives menu commands. Both menu items and global hotkeys eventually use
    /// the same handlers in `AppDelegate`.
    var commandHandler: ((AppCommand) -> Void)?

    private let statusItem: NSStatusItem
    private let appVersion: String
    private var model: AppModel

    /// Creates and immediately installs a visible status item.
    init(model: AppModel, bundle: Bundle = .main) {
        self.model = model
        appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        rebuildMenu()
    }

    /// The current text fallback, exposed for launch-level regression tests.
    var statusItemTitle: String? {
        statusItem.button?.title
    }

    /// The name of the SF Symbol selected for the current playback state.
    var statusItemSymbolName: String {
        model.isPlaying ? Symbol.playing : Symbol.stopped
    }

    /// Whether the status item successfully loaded its native symbol.
    var hasStatusItemImage: Bool {
        statusItem.button?.image != nil
    }

    /// Whether AppKit currently considers the status item visible.
    var isVisible: Bool {
        statusItem.isVisible
    }

    /// The rendered menu, exposed for focused menu-state regression tests.
    var statusMenu: NSMenu? {
        statusItem.menu
    }

    /// Applies a new model snapshot to the icon, tooltip, and command menu.
    func update(model: AppModel) {
        self.model = model
        configureStatusItem()
        rebuildMenu()
    }

    private func configureStatusItem() {
        statusItem.isVisible = true
        guard let button = statusItem.button else {
            return
        }

        let accessibilityDescription = model.isPlaying
            ? "DevNoise, playing"
            : "DevNoise, stopped"
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        if let symbol = NSImage(
            systemSymbolName: statusItemSymbolName,
            accessibilityDescription: accessibilityDescription
        )?.withSymbolConfiguration(symbolConfiguration) {
            symbol.isTemplate = true
            button.image = symbol
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.image = nil
            button.imagePosition = .noImage
            button.title = model.isPlaying ? "DN•" : "DN"
        }

        button.toolTip = "DevNoise — \(model.statusLine)"
        button.setAccessibilityLabel("DevNoise")
        button.setAccessibilityValue(model.statusLine)
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        menu.addItem(disabledItem(model.statusLine))

        if let audioError = model.audioError {
            menu.addItem(disabledItem(audioError))
        }

        if let safetyNotice = model.safetyNotice {
            menu.addItem(disabledItem(safetyNotice))
        }

        if model.unavailableHotkeyCount > 0 {
            menu.addItem(disabledItem("\(model.unavailableHotkeyCount) shortcut(s) unavailable"))
        }

        menu.addItem(.separator())

        let playTitle = model.isPlaying ? "Stop Noise" : "Play Noise"
        menu.addItem(actionItem(
            "\(playTitle)    \(HotkeyAction.playStop.shortcut)",
            action: #selector(togglePlayback(_:))
        ))

        let panicItem = actionItem(
            "Panic Stop    \(HotkeyAction.panicStop.shortcut)",
            action: #selector(panicStop(_:))
        )
        panicItem.isEnabled = model.isPlaying
        menu.addItem(panicItem)

        menu.addItem(.separator())
        menu.addItem(submenuItem("Noise", menu: noiseMenu()))
        menu.addItem(submenuItem("Depth", menu: depthMenu()))
        menu.addItem(submenuItem("Volume", menu: volumeMenu()))
        let timerItem = submenuItem("Timer", menu: timerMenu())
        timerItem.isEnabled = model.isPlaying
        menu.addItem(timerItem)
        menu.addItem(submenuItem("Keyboard Shortcuts", menu: shortcutsMenu()))

        menu.addItem(.separator())
        menu.addItem(actionItem("Reset to Defaults", action: #selector(reset(_:))))
        menu.addItem(.separator())

        menu.addItem(disabledItem("Version \(appVersion)"))
        menu.addItem(actionItem(
            "View Latest Release… ↗",
            action: #selector(viewLatestRelease(_:))
        ))
        menu.addItem(actionItem(
            "Made with noise by Reece ↗",
            action: #selector(viewLinkedIn(_:))
        ))
        menu.addItem(.separator())

        let quitItem = actionItem("Quit DevNoise", action: #selector(quit(_:)))
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func noiseMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for noiseType in NoiseType.allCases {
            let item = actionItem(noiseType.title, action: #selector(selectNoise(_:)))
            item.representedObject = noiseType.rawValue
            item.state = model.noiseType == noiseType ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func depthMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for depthPreset in DepthPreset.allCases {
            let item = actionItem(depthPreset.title, action: #selector(selectDepth(_:)))
            item.representedObject = depthPreset.rawValue
            item.state = model.depthPreset == depthPreset ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func volumeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        menu.addItem(actionItem(
            "Increase    \(HotkeyAction.volumeUp.shortcut)",
            action: #selector(increaseVolume(_:))
        ))
        menu.addItem(actionItem(
            "Decrease    \(HotkeyAction.volumeDown.shortcut)",
            action: #selector(decreaseVolume(_:))
        ))
        menu.addItem(.separator())

        for volume in stride(from: 0.2, through: 1.0, by: 0.2) {
            let item = actionItem("\(Int(volume * 100))%", action: #selector(selectVolume(_:)))
            item.representedObject = NSNumber(value: volume)
            item.state = abs(model.volume - volume) < 0.001 ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func timerMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for preset in SessionTimerPreset.allCases {
            let item = actionItem(preset.title, action: #selector(selectTimer(_:)))
            item.representedObject = preset.rawValue
            item.state = model.timerPreset == preset ? .on : .off
            menu.addItem(item)
        }

        if let stopDate = model.timerStopDate, model.timerPreset != .off {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            menu.addItem(.separator())
            menu.addItem(disabledItem("Stops at \(formatter.string(from: stopDate))"))
        }
        return menu
    }

    private func shortcutsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for action in HotkeyAction.allCases {
            menu.addItem(disabledItem("\(action.title)    \(action.shortcut)"))
        }
        return menu
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func submenuItem(_ title: String, menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    @objc private func togglePlayback(_: NSMenuItem) {
        commandHandler?(.togglePlayback)
    }

    @objc private func panicStop(_: NSMenuItem) {
        commandHandler?(.panicStop)
    }

    @objc private func selectNoise(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let noiseType = NoiseType(rawValue: rawValue) else {
            return
        }
        commandHandler?(.setNoise(noiseType))
    }

    @objc private func selectDepth(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let depthPreset = DepthPreset(rawValue: rawValue) else {
            return
        }
        commandHandler?(.setDepth(depthPreset))
    }

    @objc private func selectVolume(_ sender: NSMenuItem) {
        guard let volume = sender.representedObject as? NSNumber else {
            return
        }
        commandHandler?(.setVolume(volume.doubleValue))
    }

    @objc private func selectTimer(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let preset = SessionTimerPreset(rawValue: rawValue) else {
            return
        }
        commandHandler?(.setTimer(preset))
    }

    @objc private func increaseVolume(_: NSMenuItem) {
        commandHandler?(.increaseVolume)
    }

    @objc private func decreaseVolume(_: NSMenuItem) {
        commandHandler?(.decreaseVolume)
    }

    @objc private func reset(_: NSMenuItem) {
        commandHandler?(.reset)
    }

    @objc private func viewLatestRelease(_: NSMenuItem) {
        commandHandler?(.viewLatestRelease)
    }

    @objc private func viewLinkedIn(_: NSMenuItem) {
        commandHandler?(.viewLinkedIn)
    }

    @objc private func quit(_: NSMenuItem) {
        commandHandler?(.quit)
    }
}
