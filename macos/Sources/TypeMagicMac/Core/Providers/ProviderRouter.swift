import Foundation

enum ProviderError: LocalizedError {
    case unsupported
    case missingCredential(String)
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Unsupported provider"
        case .missingCredential(let value):
            return "Missing credential: \(value)"
        case .invalidResponse:
            return "Provider returned an invalid response"
        case .server(let message):
            return message
        }
    }
}

actor ProviderRouter {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func run(prompt: Prompt, settings: Settings, secrets: Secrets) async throws -> String {
        switch settings.provider {
        case .openAI:
            return try await callOpenAI(prompt: prompt, model: settings.openAIModel, apiKey: secrets.openAIKey)
        case .gemini:
            return try await callGemini(prompt: prompt, model: settings.geminiModel, apiKey: secrets.geminiKey)
        case .claude:
            return try await callClaude(prompt: prompt, model: settings.claudeModel, apiKey: secrets.claudeKey)
        case .fastAPI:
            return try await callFastAPI(prompt: prompt, endpoint: settings.fastApiEndpoint)
        case .ollama:
            return try await callOllama(prompt: prompt, endpoint: settings.ollamaEndpoint, model: settings.ollamaModel)
        }
    }

    private func callOpenAI(prompt: Prompt, model: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ProviderError.missingCredential("OpenAI API key") }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        struct Message: Encodable { let role: String; let content: String }
        struct Body: Encodable {
            let model: String
            let messages: [Message]
            let temperature: Double
        }

        let body = Body(
            model: model,
            messages: [
                Message(role: "system", content: prompt.system),
                Message(role: "user", content: prompt.user)
            ],
            temperature: 0.3
        )

        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request: request)

        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let first = decoded.choices.first else { throw ProviderError.invalidResponse }
        return first.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callGemini(prompt: Prompt, model: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ProviderError.missingCredential("Gemini API key") }
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw ProviderError.unsupported
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct ContentPart: Encodable { let text: String }
        struct Content: Encodable { let parts: [ContentPart] }
        struct Body: Encodable {
            let contents: [Content]
            let generationConfig: GenerationConfig

            struct GenerationConfig: Encodable { let temperature: Double }
        }

        let text = "\(prompt.system)\n\nText to correct:\n\(prompt.user)"
        let body = Body(contents: [Content(parts: [ContentPart(text: text)])], generationConfig: .init(temperature: 0.3))
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request: request)

        struct Response: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable { let text: String? }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            throw ProviderError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callClaude(prompt: Prompt, model: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ProviderError.missingCredential("Claude API key") }
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        struct Message: Encodable { let role: String; let content: String }
        struct Body: Encodable {
            let model: String
            let max_tokens: Int
            let system: String
            let messages: [Message]
            let temperature: Double
        }

        let body = Body(
            model: model,
            max_tokens: 4096,
            system: prompt.system,
            messages: [Message(role: "user", content: prompt.user)],
            temperature: 0.3
        )

        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request: request)

        struct Response: Decodable {
            struct ContentBlock: Decodable { let text: String }
            let content: [ContentBlock]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let first = decoded.content.first else { throw ProviderError.invalidResponse }
        return first.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callFastAPI(prompt: Prompt, endpoint: String) async throws -> String {
        guard !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProviderError.missingCredential("FastAPI endpoint")
        }

        let adjustedEndpoint: String
        if endpoint.contains("/v1/chat/completions") || endpoint.contains("/correct") || endpoint.contains("/api/") {
            adjustedEndpoint = endpoint
        } else {
            let sanitized = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
            adjustedEndpoint = sanitized + "/v1/chat/completions"
        }
        guard let url = URL(string: adjustedEndpoint) else { throw ProviderError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Message: Encodable { let role: String; let content: String }
        struct Body: Encodable {
            let messages: [Message]
            let temperature: Double
            let max_tokens: Int
        }

        let body = Body(
            messages: [
                Message(role: "system", content: prompt.system),
                Message(role: "user", content: prompt.user)
            ],
            temperature: 0.3,
            max_tokens: 4096
        )
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request: request)

        if let text = try? JSONDecoder().decode(FastAPIResponse.self, from: data).bestText {
            return text
        }

        guard let raw = String(data: data, encoding: .utf8) else { throw ProviderError.invalidResponse }
        throw ProviderError.server(raw)
    }

    private func callOllama(prompt: Prompt, endpoint: String, model: String) async throws -> String {
        let sanitized = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
        guard let url = URL(string: sanitized + "/api/generate") else {
            throw ProviderError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Encodable {
            let model: String
            let prompt: String
            let stream: Bool
            let options: Options

            struct Options: Encodable { let temperature: Double }
        }

        let body = Body(
            model: model,
            prompt: "\(prompt.system)\n\nText to correct:\n\(prompt.user)",
            stream: false,
            options: .init(temperature: 0.3)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request: request)

        struct Response: Decodable { let response: String }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func perform(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw ProviderError.server(message)
        }
        return data
    }
}

private struct FastAPIResponse: Decodable {
    let corrected_text: String?
    let text: String?
    let result: String?
    let content: String?
    let response: String?
    let choices: [Choice]?

    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message?
    }

    var bestText: String? {
        corrected_text ?? text ?? result ?? choices?.first?.message?.content ?? content ?? response
    }
}