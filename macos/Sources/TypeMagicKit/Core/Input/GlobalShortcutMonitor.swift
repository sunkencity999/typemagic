import Cocoa
import Carbon

@MainActor
final class GlobalShortcutMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (() -> Void)?
    private let keyCodeT: CGKeyCode = 17
    private let signature: OSType = 0x544D484B // 'TMHK'

    func start(handler: @escaping () -> Void) {
        stop()
        self.handler = handler
        registerHotKey()
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        eventHandlerRef = nil
        handler = nil
    }

    private func registerHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard
                let userData,
                let hotKeyEvent = event
            else { return noErr }

            var hotKeyID = EventHotKeyID()
            GetEventParameter(hotKeyEvent,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)

            if hotKeyID.signature == 0x544D484B, hotKeyID.id == 1 {
                let monitor = Unmanaged<GlobalShortcutMonitor>.fromOpaque(userData).takeUnretainedValue()
                monitor.handler?()
            }

            return noErr
        }

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventType, userData, &eventHandlerRef)

        var hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(optionKey)
        RegisterEventHotKey(UInt32(keyCodeT), modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    }
}