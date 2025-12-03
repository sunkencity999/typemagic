import Cocoa

@MainActor
final class GlobalShortcutMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var handler: (() -> Void)?
    private let keyCodeT: CGKeyCode = 17

    func start(handler: @escaping () -> Void) {
        stop()
        self.handler = handler
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
        handler = nil
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
        let modifiers: NSEvent.ModifierFlags = [.command, .option]
        guard event.type == .keyDown,
              event.keyCode == keyCodeT,
              event.modifierFlags.isSuperset(of: modifiers)
        else { return }

        handler?()
    }
}