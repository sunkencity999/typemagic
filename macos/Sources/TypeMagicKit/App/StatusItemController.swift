import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let viewModel: AppViewModel

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configurePopover()
        configureButton()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(rootView: ControlPanelView(model: viewModel))
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "TypeMagic")
        button.imagePosition = .imageOnly
        button.action = #selector(togglePopover(_:))
        button.target = self
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@MainActor
public final class TypeMagicAppCoordinator {
    private var statusController: StatusItemController?

    public init() {
        let store = SettingsStore()
        let model = AppViewModel(settingsStore: store)
        statusController = StatusItemController(viewModel: model)
    }
}