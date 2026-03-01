import AppKit
import Combine
import Foundation

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menuBuilder = MenuBuilder()
    private let actionHandler: MenuActionHandler
    private var modelObserver: AnyCancellable?

    init(store: Store) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        actionHandler = MenuActionHandler(dispatchAction: { [weak store] action in
            store?.dispatch(action)
        })

        configureStatusItem()
        bindStore(store)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "DevNoise") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "DN"
        }
    }

    private func bindStore(_ store: Store) {
        statusItem.menu = menuBuilder.buildMenu(model: store.model, actionHandler: actionHandler)
        statusItem.button?.toolTip = store.model.statusLine

        modelObserver = store.$model.receive(on: RunLoop.main).sink { [weak self] model in
            guard let self else {
                return
            }
            self.statusItem.menu = self.menuBuilder.buildMenu(model: model, actionHandler: self.actionHandler)
            self.statusItem.button?.toolTip = model.statusLine
        }
    }
}
