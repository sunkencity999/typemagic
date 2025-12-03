import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var manualInput: String = ""
    @Published var manualOutput: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var isProcessing: Bool = false
    @Published var selectedTone: Tone = .preserve
    @Published var useMarkdown: Bool
    @Published var showUserGuide: Bool = false

    let settingsStore: SettingsStore

    private let engine: TypeMagicEngine
    private let shortcutMonitor = GlobalShortcutMonitor()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.engine = TypeMagicEngine(settingsStore: settingsStore)
        self.useMarkdown = settingsStore.settings.useMarkdown
        shortcutMonitor.start { [weak self] in
            Task { await self?.handleGlobalShortcut() }
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
            manualOutput = result.correctedText
            manualInput = result.correctedText
            statusMessage = "Copied to clipboard"
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
        guard let clipboardText = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clipboardText.isEmpty else {
            statusMessage = "Copy text before pressing ⌘⌥T"
            return
        }

        isProcessing = true
        statusMessage = "Correcting clipboard..."
        do {
            let request = CorrectionRequest(tone: selectedTone, bulletize: false, summarize: false, useMarkdown: useMarkdown)
            let result = try await engine.correctManualText(clipboardText, request: request)
            manualOutput = result.correctedText
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.correctedText, forType: .string)
            statusMessage = "Clipboard updated"
        } catch {
            statusMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func handleGlobalShortcut() async {
        await performClipboardCorrection()
    }
}