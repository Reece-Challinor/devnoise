import AppKit
import Foundation

final class MenuActionHandler: NSObject {
    private let dispatchAction: (Action) -> Void

    init(dispatchAction: @escaping (Action) -> Void) {
        self.dispatchAction = dispatchAction
    }

    @objc func togglePlayback(_: NSMenuItem) {
        dispatchAction(.togglePlayback)
    }

    @objc func selectNoise(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let noiseType = NoiseType(rawValue: rawValue) else {
            return
        }
        dispatchAction(.setNoiseType(noiseType))
    }

    @objc func selectDepth(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let preset = DepthPreset(rawValue: rawValue) else {
            return
        }
        dispatchAction(.setDepthPreset(preset))
    }

    @objc func selectVolume(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? NSNumber else {
            return
        }
        dispatchAction(.setVolume(value.doubleValue))
    }

    @objc func beginRemap(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let action = HotkeyAction(rawValue: rawValue) else {
            return
        }
        dispatchAction(.beginRemap(action))
    }

    @objc func cancelRemap(_: NSMenuItem) {
        dispatchAction(.cancelRemap)
    }

    @objc func refreshPermissions(_: NSMenuItem) {
        dispatchAction(.refreshPermissions(promptIfNeeded: false))
    }

    @objc func openAccessibilitySettings(_: NSMenuItem) {
        dispatchAction(.openAccessibilitySettings)
    }

    @objc func resetToDefaults(_: NSMenuItem) {
        dispatchAction(.resetToDefaults)
    }

    @objc func openHelp(_: NSMenuItem) {
        dispatchAction(.openHelp)
    }

    @objc func quit(_: NSMenuItem) {
        dispatchAction(.quit)
    }
}

final class MenuBuilder {
    private let volumePresets: [Double] = [0.2, 0.4, 0.6, 0.8, 1.0]
    private let remapActions: [(action: HotkeyAction, title: String)] = [
        (.playStop, "Remap Play/Stop..."),
        (.panicStop, "Remap Panic..."),
        (.nextNoise, "Remap Next Noise..."),
        (.cycleDepth, "Remap Cycle Depth..."),
        (.volumeUp, "Remap Vol Up..."),
        (.volumeDown, "Remap Vol Down...")
    ]

    func buildMenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let menu = NSMenu()

        let statusItem = NSMenuItem(title: model.statusLine, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        let permissionsItem = NSMenuItem(title: model.permissions.menuLine, action: nil, keyEquivalent: "")
        permissionsItem.isEnabled = false
        menu.addItem(permissionsItem)

        menu.addItem(.separator())

        let playStopItem = NSMenuItem(
            title: model.playbackState.playStopTitle,
            action: #selector(MenuActionHandler.togglePlayback(_:)),
            keyEquivalent: ""
        )
        playStopItem.target = actionHandler
        menu.addItem(playStopItem)

        let noiseItem = NSMenuItem(title: "Noise", action: nil, keyEquivalent: "")
        noiseItem.submenu = noiseSubmenu(model: model, actionHandler: actionHandler)
        menu.addItem(noiseItem)

        let depthItem = NSMenuItem(title: "Depth", action: nil, keyEquivalent: "")
        depthItem.submenu = depthSubmenu(model: model, actionHandler: actionHandler)
        menu.addItem(depthItem)

        let volumeItem = NSMenuItem(title: "Volume", action: nil, keyEquivalent: "")
        volumeItem.submenu = volumeSubmenu(model: model, actionHandler: actionHandler)
        menu.addItem(volumeItem)

        let shortcutsItem = NSMenuItem(title: "Shortcuts", action: nil, keyEquivalent: "")
        shortcutsItem.submenu = shortcutsSubmenu(model: model, actionHandler: actionHandler)
        menu.addItem(shortcutsItem)

        menu.addItem(.separator())

        let resetItem = NSMenuItem(
            title: "Reset to Defaults",
            action: #selector(MenuActionHandler.resetToDefaults(_:)),
            keyEquivalent: ""
        )
        resetItem.target = actionHandler
        menu.addItem(resetItem)

        let helpItem = NSMenuItem(
            title: "Help",
            action: #selector(MenuActionHandler.openHelp(_:)),
            keyEquivalent: ""
        )
        helpItem.target = actionHandler
        menu.addItem(helpItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit DevNoise",
            action: #selector(MenuActionHandler.quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = actionHandler
        menu.addItem(quitItem)

        return menu
    }

    private func noiseSubmenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let submenu = NSMenu()
        for noiseType in NoiseType.allCases {
            let item = NSMenuItem(
                title: noiseType.title,
                action: #selector(MenuActionHandler.selectNoise(_:)),
                keyEquivalent: ""
            )
            item.target = actionHandler
            item.representedObject = noiseType.rawValue
            item.state = model.noiseType == noiseType ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func depthSubmenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let submenu = NSMenu()
        for preset in DepthPreset.allCases {
            let item = NSMenuItem(
                title: preset.title,
                action: #selector(MenuActionHandler.selectDepth(_:)),
                keyEquivalent: ""
            )
            item.target = actionHandler
            item.representedObject = preset.rawValue
            item.state = model.depthPreset == preset ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func volumeSubmenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let submenu = NSMenu()
        for preset in volumePresets {
            let item = NSMenuItem(
                title: "\(Int(preset * 100))%",
                action: #selector(MenuActionHandler.selectVolume(_:)),
                keyEquivalent: ""
            )
            item.target = actionHandler
            item.representedObject = NSNumber(value: preset)
            item.state = abs(model.volume - preset) < 0.0001 ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    private func shortcutsSubmenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let submenu = NSMenu()

        for action in HotkeyAction.allCases {
            let chord = model.hotkeyBindings.chord(for: action)
            let item = NSMenuItem(title: "\(action.title): \(chord.displayString)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            submenu.addItem(item)
        }

        submenu.addItem(.separator())

        if let remapStatusTitle = remapStatusTitle(for: model.remapState) {
            let statusItem = NSMenuItem(title: remapStatusTitle, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            submenu.addItem(statusItem)
            submenu.addItem(.separator())
        }

        if !model.permissions.accessibilityGranted {
            let permissionHint = NSMenuItem(
                title: "Remap unavailable: Accessibility not granted.",
                action: nil,
                keyEquivalent: ""
            )
            permissionHint.isEnabled = false
            submenu.addItem(permissionHint)
        }

        let remapItem = NSMenuItem(title: "Remap", action: nil, keyEquivalent: "")
        remapItem.submenu = remapSubmenu(model: model, actionHandler: actionHandler)
        submenu.addItem(remapItem)

        if model.remapState.isListening {
            let cancelItem = NSMenuItem(
                title: "Cancel Remap",
                action: #selector(MenuActionHandler.cancelRemap(_:)),
                keyEquivalent: ""
            )
            cancelItem.target = actionHandler
            submenu.addItem(cancelItem)
        }

        let openSettingsItem = NSMenuItem(
            title: "Open System Settings...",
            action: #selector(MenuActionHandler.openAccessibilitySettings(_:)),
            keyEquivalent: ""
        )
        openSettingsItem.target = actionHandler
        submenu.addItem(openSettingsItem)

        let refreshItem = NSMenuItem(
            title: "Refresh Permissions",
            action: #selector(MenuActionHandler.refreshPermissions(_:)),
            keyEquivalent: ""
        )
        refreshItem.target = actionHandler
        submenu.addItem(refreshItem)

        return submenu
    }

    private func remapSubmenu(model: AppModel, actionHandler: MenuActionHandler) -> NSMenu {
        let submenu = NSMenu()
        let canStartRemap = model.permissions.accessibilityGranted && !model.remapState.isListening

        for remapAction in remapActions {
            let item = NSMenuItem(
                title: remapAction.title,
                action: #selector(MenuActionHandler.beginRemap(_:)),
                keyEquivalent: ""
            )
            item.target = actionHandler
            item.representedObject = remapAction.action.rawValue
            item.isEnabled = canStartRemap
            submenu.addItem(item)
        }

        return submenu
    }

    private func remapStatusTitle(for remapState: RemapState) -> String? {
        switch remapState.mode {
        case .idle:
            return nil
        case .listening:
            return remapState.statusText
        case .success:
            return "Remap: \(remapState.statusText)"
        case .failure:
            return "Remap Error: \(remapState.statusText)"
        }
    }
}
