#if canImport(XCTest)
import XCTest
@testable import TypeMagicKit

final class TypeMagicEngineTests: XCTestCase {
    
    // MARK: - PromptBuilder Tests
    
    func testPromptBuilderPreserveTone() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: false,
            customSystemPrompt: "",
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test input", options: options)
        
        XCTAssertTrue(prompt.system.contains("precise text correction assistant"))
        XCTAssertTrue(prompt.system.contains("PRESERVE the user's unique voice"))
        XCTAssertEqual(prompt.user, "Test input")
    }
    
    func testPromptBuilderProfessionalTone() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .professional,
            useMarkdown: false,
            customSystemPrompt: "",
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test input", options: options)
        
        XCTAssertTrue(prompt.system.contains("professional tone"))
        XCTAssertTrue(prompt.system.contains("business-appropriate"))
    }
    
    func testPromptBuilderCasualTone() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .casual,
            useMarkdown: false,
            customSystemPrompt: "",
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test input", options: options)
        
        XCTAssertTrue(prompt.system.contains("conversational"))
        XCTAssertTrue(prompt.system.contains("friendly"))
    }
    
    func testPromptBuilderBulletize() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: true,
            customSystemPrompt: "",
            bulletize: true,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test input", options: options)
        
        XCTAssertTrue(prompt.system.contains("bullet points"))
        XCTAssertTrue(prompt.system.contains("Markdown"))
    }
    
    func testPromptBuilderSummarize() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: false,
            customSystemPrompt: "",
            bulletize: false,
            summarize: true
        )
        
        let prompt = builder.build(text: "Test input", options: options)
        
        XCTAssertTrue(prompt.system.contains("summary"))
        XCTAssertTrue(prompt.system.contains("2-5 sentences"))
    }
    
    func testPromptBuilderMarkdownEnabled() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: true,
            customSystemPrompt: "",
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test", options: options)
        
        XCTAssertTrue(prompt.system.contains("Markdown formatting"))
    }
    
    func testPromptBuilderMarkdownDisabled() {
        let builder = PromptBuilder()
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: false,
            customSystemPrompt: "",
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test", options: options)
        
        XCTAssertTrue(prompt.system.contains("plain text"))
    }
    
    func testPromptBuilderCustomSystemPrompt() {
        let builder = PromptBuilder()
        let customPrompt = "You are a custom assistant that does special things."
        let options = PromptOptions(
            tone: .preserve,
            useMarkdown: false,
            customSystemPrompt: customPrompt,
            bulletize: false,
            summarize: false
        )
        
        let prompt = builder.build(text: "Test", options: options)
        
        XCTAssertEqual(prompt.system, customPrompt)
    }
    
    // MARK: - CorrectionRequest Tests
    
    func testCorrectionRequestInitialization() {
        let request = CorrectionRequest(
            tone: .professional,
            bulletize: true,
            summarize: false,
            useMarkdown: true
        )
        
        XCTAssertEqual(request.tone, .professional)
        XCTAssertTrue(request.bulletize)
        XCTAssertFalse(request.summarize)
        XCTAssertTrue(request.useMarkdown)
    }
    
    // MARK: - CorrectionResult Tests
    
    func testCorrectionResultInitialization() {
        let result = CorrectionResult(
            originalText: "Original",
            correctedText: "Corrected",
            source: .manualInput
        )
        
        XCTAssertEqual(result.originalText, "Original")
        XCTAssertEqual(result.correctedText, "Corrected")
        XCTAssertEqual(result.source, .manualInput)
    }
    
    func testCorrectionSourceTypes() {
        XCTAssertNotEqual(CorrectionSource.manualInput, CorrectionSource.accessibility)
        XCTAssertNotEqual(CorrectionSource.accessibility, CorrectionSource.clipboard)
        XCTAssertNotEqual(CorrectionSource.clipboard, CorrectionSource.manualInput)
    }
    
    // MARK: - Tone Tests
    
    func testToneDisplayNames() {
        XCTAssertEqual(Tone.preserve.displayName, "Keep My Voice")
        XCTAssertEqual(Tone.professional.displayName, "More Professional")
        XCTAssertEqual(Tone.casual.displayName, "More Casual")
    }
    
    func testToneAllCases() {
        let allTones = Tone.allCases
        XCTAssertEqual(allTones.count, 3)
        XCTAssertTrue(allTones.contains(.preserve))
        XCTAssertTrue(allTones.contains(.professional))
        XCTAssertTrue(allTones.contains(.casual))
    }
    
    // MARK: - ProviderType Tests
    
    func testProviderTypeDisplayNames() {
        XCTAssertEqual(ProviderType.openAI.displayName, "OpenAI")
        XCTAssertEqual(ProviderType.gemini.displayName, "Google Gemini")
        XCTAssertEqual(ProviderType.claude.displayName, "Anthropic Claude")
        XCTAssertEqual(ProviderType.fastAPI.displayName, "FastAPI")
        XCTAssertEqual(ProviderType.ollama.displayName, "Ollama")
    }
    
    func testProviderTypeAllCases() {
        let allProviders = ProviderType.allCases
        XCTAssertEqual(allProviders.count, 5)
    }
    
    // MARK: - Settings Tests
    
    func testSettingsDefaultValues() {
        let settings = Settings.default
        
        XCTAssertEqual(settings.provider, .openAI)
        XCTAssertEqual(settings.openAIModel, "gpt-4o-mini")
        XCTAssertEqual(settings.geminiModel, "gemini-pro")
        XCTAssertEqual(settings.claudeModel, "claude-3-5-sonnet-20241022")
        XCTAssertEqual(settings.ollamaEndpoint, "http://localhost:11434")
        XCTAssertEqual(settings.ollamaModel, "llama3.2")
        XCTAssertFalse(settings.useMarkdown)
        XCTAssertTrue(settings.customSystemPrompt.isEmpty)
    }
    
    func testSettingsEquatable() {
        let settings1 = Settings.default
        let settings2 = Settings.default
        
        XCTAssertEqual(settings1, settings2)
        
        var settings3 = Settings.default
        settings3.provider = .claude
        
        XCTAssertNotEqual(settings1, settings3)
    }
    
    // MARK: - Secrets Tests
    
    func testSecretsDefaultValues() {
        let secrets = Secrets()
        
        XCTAssertTrue(secrets.openAIKey.isEmpty)
        XCTAssertTrue(secrets.geminiKey.isEmpty)
        XCTAssertTrue(secrets.claudeKey.isEmpty)
    }
}
#endif
