#if canImport(XCTest)
import XCTest
@testable import TypeMagicMac

final class PromptBuilderTests: XCTestCase {
    func testSummaryInstructionsIncludeRules() {
        let builder = PromptBuilder()
        let options = PromptOptions(tone: .preserve, useMarkdown: false, customSystemPrompt: "", bulletize: false, summarize: true)
        let prompt = builder.build(text: "Example", options: options)
        XCTAssertTrue(prompt.system.contains("Create a clear, concise summary"))
        XCTAssertEqual(prompt.user, "Example")
    }
}
#endif