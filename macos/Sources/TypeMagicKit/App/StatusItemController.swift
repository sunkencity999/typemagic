import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let viewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configurePopover()
        configureButton()
        observeClipboardState()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(rootView: ControlPanelView(model: viewModel))
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "TypeMagic") {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        } else {
            button.title = "✨"
            button.font = .systemFont(ofSize: 15)
        }

        button.toolTip = "TypeMagic"
        button.action = #selector(togglePopover(_:))
        button.target = self
        updateButtonAppearance(isClipboardReady: viewModel.clipboardReady)
    }

    private func observeClipboardState() {
        viewModel.$clipboardReady
            .receive(on: RunLoop.main)
            .sink { [weak self] isReady in
                self?.updateButtonAppearance(isClipboardReady: isReady)
            }
            .store(in: &cancellables)
    }

    private func updateButtonAppearance(isClipboardReady: Bool) {
        guard let button = statusItem.button else { return }
        if isClipboardReady {
            button.contentTintColor = NSColor.systemYellow
            button.alphaValue = 1.0
        } else {
            button.contentTintColor = NSColor.labelColor
            button.alphaValue = 0.8
        }
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

@MainActor
public func startTypeMagicStatusItemApp() -> AnyObject {
    TypeMagicAppCoordinator()
}