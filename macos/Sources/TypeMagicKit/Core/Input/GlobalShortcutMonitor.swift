import Cocoa

@MainActor
final class GlobalShortcutMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var shortcutHandler: (() -> Void)?
    private var pasteHandler: (() -> Void)?
    private let keyCodeT: CGKeyCode = 17
    private let keyCodeV: CGKeyCode = 9

    func start(shortcutHandler: @escaping () -> Void, pasteHandler: (() -> Void)? = nil) {
        stop()
        self.shortcutHandler = shortcutHandler
        self.pasteHandler = pasteHandler
        registerMonitors()
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        globalMonitor = nil

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
        shortcutHandler = nil
        pasteHandler = nil
    }

    private func registerMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
            return event
        }
    }

    private func handle(event: NSEvent) {
        guard event.type == .keyDown else { return }
        let flags = event.modifierFlags
        let keyCode = event.keyCode

        if flags.isSuperset(of: [.command, .option]), keyCode == keyCodeT {
            shortcutHandler?()
        } else if flags.contains(.command) && !flags.contains(.option) && keyCode == keyCodeV {
            pasteHandler?()
        }
    }
}