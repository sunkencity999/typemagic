import Cocoa

@MainActor
final class GlobalShortcutMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handler: (() -> Void)?
    private let keyCodeT: CGKeyCode = 17

    func start(handler: @escaping () -> Void) {
        stop()
        self.handler = handler
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                           place: .headInsertEventTap,
                                           options: .defaultTap,
                                           eventsOfInterest: mask,
                                           callback: { proxy, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<GlobalShortcutMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            monitor.handle(event: event)
            return Unmanaged.passUnretained(event)
        },
                                           userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        handler = nil
    }

    private func handle(event: CGEvent) {
        guard event.type == .keyDown else { return }
        let flags = event.flags
        let isCommand = flags.contains(.maskCommand)
        let isOption = flags.contains(.maskAlternate)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if isCommand && isOption && keyCode == keyCodeT {
            handler?()
        }
    }
}