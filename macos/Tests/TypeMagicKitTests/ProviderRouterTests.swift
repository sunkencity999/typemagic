#if canImport(XCTest)
import XCTest
@testable import TypeMagicKit

final class ProviderRouterTests: XCTestCase {
    
    // MARK: - Mock URLSession
    
    class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let handler = MockURLProtocol.requestHandler else {
                XCTFail("No request handler set")
                return
            }
            
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {}
    }
    
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - OpenAI Tests
    
    func testOpenAISuccessfulResponse() async throws {
        let expectedText = "Corrected text here"
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "\(expectedText)"
                    }
                }
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.host, "api.openai.com")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.allHTTPHeaderFields?["Authorization"]?.starts(with: "Bearer ") ?? false)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test system", user: "Test user")
        let settings = Settings(provider: .openAI, openAIModel: "gpt-4o-mini")
        let secrets = Secrets(openAIKey: "test-key")
        
        let result = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
        XCTAssertEqual(result, expectedText)
    }
    
    func testOpenAIMissingAPIKey() async {
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .openAI)
        let secrets = Secrets(openAIKey: "")
        
        do {
            _ = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
            XCTFail("Expected error for missing API key")
        } catch let error as ProviderError {
            if case .missingCredential(let message) = error {
                XCTAssertTrue(message.contains("OpenAI"))
            } else {
                XCTFail("Expected missingCredential error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Gemini Tests
    
    func testGeminiSuccessfulResponse() async throws {
        let expectedText = "Gemini corrected text"
        let responseJSON = """
        {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {"text": "\(expectedText)"}
                        ]
                    }
                }
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.host?.contains("googleapis.com") ?? false)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .gemini, geminiModel: "gemini-pro")
        let secrets = Secrets(geminiKey: "test-key")
        
        let result = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
        XCTAssertEqual(result, expectedText)
    }
    
    // MARK: - Claude Tests
    
    func testClaudeSuccessfulResponse() async throws {
        let expectedText = "Claude corrected text"
        let responseJSON = """
        {
            "content": [
                {"text": "\(expectedText)"}
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.host, "api.anthropic.com")
            XCTAssertNotNil(request.allHTTPHeaderFields?["x-api-key"])
            XCTAssertEqual(request.allHTTPHeaderFields?["anthropic-version"], "2023-06-01")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .claude, claudeModel: "claude-3-5-sonnet-20241022")
        let secrets = Secrets(claudeKey: "test-key")
        
        let result = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
        XCTAssertEqual(result, expectedText)
    }
    
    // MARK: - Ollama Tests
    
    func testOllamaSuccessfulResponse() async throws {
        let expectedText = "Ollama corrected text"
        let responseJSON = """
        {
            "response": "\(expectedText)"
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.path.contains("/api/generate") ?? false)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON.data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .ollama, ollamaEndpoint: "http://localhost:11434", ollamaModel: "llama3.2")
        let secrets = Secrets()
        
        let result = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
        XCTAssertEqual(result, expectedText)
    }
    
    // MARK: - Error Handling Tests
    
    func testServerErrorResponse() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "Internal Server Error".data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .openAI)
        let secrets = Secrets(openAIKey: "test-key")
        
        do {
            _ = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
            XCTFail("Expected server error")
        } catch let error as ProviderError {
            if case .server(let message) = error {
                XCTAssertTrue(message.contains("Internal Server Error"))
            } else {
                XCTFail("Expected server error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testInvalidJSONResponse() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "not valid json".data(using: .utf8)!)
        }
        
        let router = ProviderRouter(session: mockSession)
        let prompt = Prompt(system: "Test", user: "Test")
        let settings = Settings(provider: .openAI)
        let secrets = Secrets(openAIKey: "test-key")
        
        do {
            _ = try await router.run(prompt: prompt, settings: settings, secrets: secrets)
            XCTFail("Expected decoding error")
        } catch {
            // Expected - any error is acceptable here
            XCTAssertNotNil(error)
        }
    }
}
#endif
