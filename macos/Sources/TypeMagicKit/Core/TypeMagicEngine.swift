import Foundation

struct CorrectionRequest {
    var tone: Tone
    var bulletize: Bool
    var summarize: Bool
    var useMarkdown: Bool
}

enum CorrectionSource {
    case manualInput
    case accessibility
    case clipboard
}

struct CorrectionResult {
    let originalText: String
    let correctedText: String
    let source: CorrectionSource
}

@MainActor
final class TypeMagicEngine {
    private let settingsStore: SettingsStore
    private let promptBuilder = PromptBuilder()
    private let providerRouter = ProviderRouter()
    private let accessibility = AccessibilityTextService()
    private let clipboard = ClipboardManager()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func ensureAccessibilityPermission() -> Bool {
        if accessibility.hasPermission() { return true }
        accessibility.requestPermissionIfNeeded()
        return accessibility.hasPermission()
    }

    func correctFocusedText(request: CorrectionRequest) async throws -> CorrectionResult {
        do {
            let text = try accessibility.captureFocusedText()
            let corrected = try await correct(text: text, request: request)
            if try accessibility.replaceFocusedText(with: corrected) {
                return CorrectionResult(originalText: text, correctedText: corrected, source: .accessibility)
            }
            clipboard.write(corrected)
            return CorrectionResult(originalText: text, correctedText: corrected, source: .clipboard)
        } catch let error as AccessibilityError {
            if case .permissionDenied = error { throw error }
            let clipboardText = clipboard.readString()
            guard !clipboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw error }
            let corrected = try await correct(text: clipboardText, request: request)
            clipboard.write(corrected)
            return CorrectionResult(originalText: clipboardText, correctedText: corrected, source: .clipboard)
        }
    }

    func correctManualText(_ text: String, request: CorrectionRequest) async throws -> CorrectionResult {
        let corrected = try await correct(text: text, request: request)
        clipboard.write(corrected)
        return CorrectionResult(originalText: text, correctedText: corrected, source: .manualInput)
    }

    private func correct(text: String, request: CorrectionRequest) async throws -> String {
        let options = PromptOptions(
            tone: request.tone,
            useMarkdown: request.useMarkdown,
            customSystemPrompt: settingsStore.settings.customSystemPrompt,
            bulletize: request.bulletize,
            summarize: request.summarize
        )
        let prompt = promptBuilder.build(text: text, options: options)
        return try await providerRouter.run(prompt: prompt, settings: settingsStore.settings, secrets: settingsStore.secrets)
    }
}