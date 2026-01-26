import Foundation

struct CorrectionRequest {
    var tone: Tone
    var bulletize: Bool
    var summarize: Bool
    var useMarkdown: Bool
}

enum CorrectionSource {
    case manualInput
    case clipboard
    case service
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
    private let clipboard = ClipboardManager()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func correctClipboardText(request: CorrectionRequest) async throws -> CorrectionResult {
        let clipboardText = clipboard.readString()
        guard !clipboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TypeMagicError.emptyClipboard
        }
        let corrected = try await correct(text: clipboardText, request: request)
        clipboard.write(corrected)
        return CorrectionResult(originalText: clipboardText, correctedText: corrected, source: .clipboard)
    }

    func correctManualText(_ text: String, request: CorrectionRequest) async throws -> CorrectionResult {
        let corrected = try await correct(text: text, request: request)
        clipboard.write(corrected)
        return CorrectionResult(originalText: text, correctedText: corrected, source: .manualInput)
    }

    func correctServiceText(_ text: String, request: CorrectionRequest) async throws -> String {
        try await correct(text: text, request: request)
    }

    func correct(text: String, request: CorrectionRequest) async throws -> String {
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

enum TypeMagicError: LocalizedError {
    case emptyClipboard
    case serviceError(String)

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "Clipboard is empty. Copy some text first."
        case .serviceError(let message):
            return message
        }
    }
}