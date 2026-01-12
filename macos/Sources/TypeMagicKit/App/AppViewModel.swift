import SwiftUI
import AppKit

struct UndoEntry {
    let originalText: String
    let correctedText: String
    let timestamp: Date
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var manualInput: String = ""
    @Published var manualOutput: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var isProcessing: Bool = false
    @Published var selectedTone: Tone = .preserve
    @Published var useMarkdown: Bool
    @Published var showUserGuide: Bool = false
    @Published var clipboardReady: Bool = false
    @Published var canUndo: Bool = false
    
    private var undoStack: [UndoEntry] = []
    private let maxUndoHistory = 10

    let settingsStore: SettingsStore

    private let engine: TypeMagicEngine
    private let shortcutMonitor = GlobalShortcutMonitor()
    private let pasteboard = NSPasteboard.general
    private var lastClipboardChangeCount: Int

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.engine = TypeMagicEngine(settingsStore: settingsStore)
        self.useMarkdown = settingsStore.settings.useMarkdown
        self.lastClipboardChangeCount = NSPasteboard.general.changeCount
        shortcutMonitor.start { [weak self] in
            Task { await self?.handleGlobalShortcut() }
        } pasteHandler: { [weak self] in
            Task { await self?.handleClipboardPasteEvent() }
        } undoHandler: { [weak self] in
            Task { @MainActor in self?.performUndo() }
        }
    }

    func updateMarkdown(_ value: Bool) {
        useMarkdown = value
        settingsStore.updateSettings { $0.useMarkdown = value }
    }

    func runManualCorrection(bulletize: Bool = false, summarize: Bool = false) {
        Task { await self.performManualCorrection(bulletize: bulletize, summarize: summarize) }
    }

    private func performManualCorrection(bulletize: Bool, summarize: Bool) async {
        clipboardReady = false
        let trimmed = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Please enter text first"
            return
        }
        isProcessing = true
        statusMessage = "Correcting..."
        do {
            let request = CorrectionRequest(tone: selectedTone, bulletize: bulletize, summarize: summarize, useMarkdown: useMarkdown)
            let result = try await engine.correctManualText(trimmed, request: request)
            
            // Store for undo
            pushUndo(original: trimmed, corrected: result.correctedText)
            
            manualOutput = result.correctedText
            manualInput = result.correctedText
            statusMessage = "Copied to clipboard (⌘⌥Z to undo)"
            clipboardReady = true
        } catch {
            statusMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func runFocusedCorrection(bulletize: Bool = false, summarize: Bool = false) {
        Task { await self.performFocusedCorrection(bulletize: bulletize, summarize: summarize) }
    }

    private func performFocusedCorrection(bulletize: Bool, summarize: Bool) async {
        guard engine.ensureAccessibilityPermission() else {
            statusMessage = "Grant Accessibility permission"
            return
        }
        isProcessing = true
        statusMessage = "Correcting selection..."
        do {
            let request = CorrectionRequest(tone: selectedTone, bulletize: bulletize, summarize: summarize, useMarkdown: useMarkdown)
            let result = try await engine.correctFocusedText(request: request)
            manualOutput = result.correctedText
            statusMessage = result.source == .accessibility ? "Replaced selection" : "Copied to clipboard"
        } catch {
            statusMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func performClipboardCorrection() async {
        clipboardReady = false
        guard let clipboardText = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clipboardText.isEmpty else {
            statusMessage = "Copy text before pressing ⌘⌥T"
            return
        }

        isProcessing = true
        statusMessage = "Correcting clipboard..."
        do {
            let request = CorrectionRequest(tone: selectedTone, bulletize: false, summarize: false, useMarkdown: useMarkdown)
            let result = try await engine.correctManualText(clipboardText, request: request)
            
            // Store for undo
            pushUndo(original: clipboardText, corrected: result.correctedText)
            
            manualOutput = result.correctedText
            pasteboard.clearContents()
            pasteboard.setString(result.correctedText, forType: .string)
            lastClipboardChangeCount = pasteboard.changeCount
            statusMessage = "Clipboard updated (⌘⌥Z to undo)"
            clipboardReady = true
        } catch {
            statusMessage = error.localizedDescription
            clipboardReady = false
        }
        isProcessing = false
    }

    private func handleGlobalShortcut() async {
        await performClipboardCorrection()
    }

    private func handleClipboardPasteEvent() async {
        guard clipboardReady else { return }
        let currentCount = pasteboard.changeCount
        if currentCount != lastClipboardChangeCount {
            clipboardReady = false
        } else {
            clipboardReady = false
        }
    }
    
    // MARK: - Undo Support
    
    private func pushUndo(original: String, corrected: String) {
        let entry = UndoEntry(originalText: original, correctedText: corrected, timestamp: Date())
        undoStack.append(entry)
        
        // Limit history size
        if undoStack.count > maxUndoHistory {
            undoStack.removeFirst()
        }
        
        canUndo = true
    }
    
    func performUndo() {
        guard let entry = undoStack.popLast() else {
            statusMessage = "Nothing to undo"
            return
        }
        
        // Restore original text
        manualInput = entry.originalText
        manualOutput = entry.originalText
        
        // Copy to clipboard
        pasteboard.clearContents()
        pasteboard.setString(entry.originalText, forType: .string)
        lastClipboardChangeCount = pasteboard.changeCount
        
        statusMessage = "Undo successful"
        canUndo = !undoStack.isEmpty
    }
}