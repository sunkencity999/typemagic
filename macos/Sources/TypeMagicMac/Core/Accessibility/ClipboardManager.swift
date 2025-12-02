import AppKit

final class ClipboardManager {
    private let pasteboard = NSPasteboard.general

    func readString() -> String {
        pasteboard.string(forType: .string) ?? ""
    }

    func write(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}