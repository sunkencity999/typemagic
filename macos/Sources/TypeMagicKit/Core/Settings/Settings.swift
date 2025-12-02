import Foundation

enum Tone: String, CaseIterable, Identifiable {
    case preserve
    case professional
    case casual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preserve:
            return "Keep My Voice"
        case .professional:
            return "More Professional"
        case .casual:
            return "More Casual"
        }
    }
}

enum ProviderType: String, CaseIterable, Identifiable {
    case openAI
    case gemini
    case claude
    case fastAPI
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .gemini:
            return "Google Gemini"
        case .claude:
            return "Anthropic Claude"
        case .fastAPI:
            return "FastAPI"
        case .ollama:
            return "Ollama"
        }
    }
}

struct Settings: Equatable {
    var provider: ProviderType = .openAI
    var openAIModel: String = "gpt-4o-mini"
    var geminiModel: String = "gemini-pro"
    var claudeModel: String = "claude-3-5-sonnet-20241022"
    var fastApiEndpoint: String = ""
    var ollamaEndpoint: String = "http://localhost:11434"
    var ollamaModel: String = "llama3.2"
    var useMarkdown: Bool = false
    var customSystemPrompt: String = ""

    static let `default` = Settings()
}

struct Secrets {
    var openAIKey: String = ""
    var geminiKey: String = ""
    var claudeKey: String = ""
}