import AppKit
@preconcurrency import ApplicationServices

enum AccessibilityError: LocalizedError {
    case elementUnavailable
    case valueUnavailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .elementUnavailable:
            return "Unable to identify the focused text field"
        case .valueUnavailable:
            return "Unable to read text from the focused element"
        case .permissionDenied:
            return "Accessibility permission is required"
        }
    }
}

@MainActor
final class AccessibilityTextService {
    private let systemWide = AXUIElementCreateSystemWide()

    func requestPermissionIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func hasPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func captureFocusedText() throws -> String {
        guard hasPermission() else { throw AccessibilityError.permissionDenied }
        var focusedElement: AXUIElement?
        try fetchFocusedElement(&focusedElement)
        guard let element = focusedElement else { throw AccessibilityError.elementUnavailable }

        if let selected = try copyAttribute(kAXSelectedTextAttribute, from: element) as? String,
           !selected.isEmpty {
            return selected
        }

        if let value = try copyAttribute(kAXValueAttribute, from: element) as? String,
           !value.isEmpty {
            return value
        }

        throw AccessibilityError.valueUnavailable
    }

    @discardableResult
    func replaceFocusedText(with text: String) throws -> Bool {
        guard hasPermission() else { throw AccessibilityError.permissionDenied }
        var focusedElement: AXUIElement?
        try fetchFocusedElement(&focusedElement)
        guard let element = focusedElement else { throw AccessibilityError.elementUnavailable }

        if attributeIsSettable(kAXSelectedTextAttribute, element: element) {
            let status = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
            if status == .success { return true }
        }

        if attributeIsSettable(kAXValueAttribute, element: element) {
            let status = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
            if status == .success { return true }
        }

        return false
    }

    private func fetchFocusedElement(_ target: inout AXUIElement?) throws {
        var app: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &app) == .success,
              let focusedApp = app.map({ unsafeDowncast($0, to: AXUIElement.self) }) else {
            throw AccessibilityError.elementUnavailable
        }

        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused.map({ unsafeDowncast($0, to: AXUIElement.self) }) else {
            throw AccessibilityError.elementUnavailable
        }
        target = element
    }

    private func copyAttribute(_ attribute: String, from element: AXUIElement) throws -> AnyObject? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        if status == .success {
            return value
        }
        if status == .attributeUnsupported {
            return nil
        }
        throw AccessibilityError.valueUnavailable
    }

    private func attributeIsSettable(_ attribute: String, element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        let status = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return status == .success && settable.boolValue
    }
}