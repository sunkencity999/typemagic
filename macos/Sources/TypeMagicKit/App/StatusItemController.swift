import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let viewModel: AppViewModel
    private var cancellables = Set<AnyCancellable>()
    private let dotsView: NSView = {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 16, height: 4))
        view.wantsLayer = true
        view.layer = CALayer()
        view.isHidden = true

        let dotCount = 3
        let dotDiameter: CGFloat = 3
        let spacing: CGFloat = 4
        let totalWidth = CGFloat(dotCount) * dotDiameter + CGFloat(dotCount - 1) * spacing
        var x = (16 - totalWidth) / 2
        for _ in 0..<dotCount {
            let dotLayer = CALayer()
            dotLayer.backgroundColor = NSColor.labelColor.cgColor
            dotLayer.frame = CGRect(x: x, y: 0.5, width: dotDiameter, height: dotDiameter)
            dotLayer.cornerRadius = dotDiameter / 2
            view.layer?.addSublayer(dotLayer)
            x += dotDiameter + spacing
        }

        return view
    }()

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
        installDotsViewIfNeeded(on: button)
        updateButtonAppearance(isClipboardReady: viewModel.clipboardReady)
    }

    private func installDotsViewIfNeeded(on button: NSStatusBarButton) {
        guard dotsView.superview == nil else { return }
        dotsView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(dotsView)
        NSLayoutConstraint.activate([
            dotsView.heightAnchor.constraint(equalToConstant: 4),
            dotsView.widthAnchor.constraint(equalToConstant: 16),
            dotsView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            dotsView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
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
            button.contentTintColor = NSColor.labelColor
            button.alphaValue = 1.0
            dotsView.isHidden = false
        } else {
            button.contentTintColor = NSColor.white
            button.alphaValue = 0.8
            dotsView.isHidden = true
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
    private var servicesProvider: ServicesProvider?

    public init() {
        let store = SettingsStore()
        let model = AppViewModel(settingsStore: store)
        statusController = StatusItemController(viewModel: model)
        
        servicesProvider = ServicesProvider(settingsStore: store)
        NSApp.servicesProvider = servicesProvider
        NSUpdateDynamicServices()
    }
}

@MainActor
public func startTypeMagicStatusItemApp() -> AnyObject {
    TypeMagicAppCoordinator()
}