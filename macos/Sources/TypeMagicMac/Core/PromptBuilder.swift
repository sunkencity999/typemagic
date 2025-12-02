import Foundation

struct Prompt {
    let system: String
    let user: String
}

struct PromptOptions {
    var tone: Tone
    var useMarkdown: Bool
    var customSystemPrompt: String
    var bulletize: Bool
    var summarize: Bool
}

struct PromptBuilder {
    func build(text: String, options: PromptOptions) -> Prompt {
        let base = "You are a precise text correction assistant."
        let instructions: String

        if options.summarize {
            instructions = Self.summaryInstructions(useMarkdown: options.useMarkdown)
        } else if options.bulletize {
            instructions = Self.bulletInstructions(useMarkdown: options.useMarkdown)
        } else {
            instructions = Self.toneInstructions(tone: options.tone, useMarkdown: options.useMarkdown)
        }

        let systemPrompt: String
        if options.customSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            systemPrompt = base + instructions
        } else {
            systemPrompt = options.customSystemPrompt
        }

        return Prompt(system: systemPrompt, user: text)
    }

    private static func summaryInstructions(useMarkdown: Bool) -> String {
        let formatting = useMarkdown ? "Use Markdown formatting (bold, italic) to emphasize key points if helpful" : "Return plain text without special formatting"
        return "\n\nYour task: Create a clear, concise summary of the text while fixing any errors.\n\nRules:\n1. Fix spelling, grammar, and punctuation errors in your summary\n2. Capture the main points and key information\n3. Keep the summary between 2-5 sentences (or 20-30% of original length for very long texts)\n4. Preserve the original meaning and intent\n5. Use clear, professional language\n6. Organize information logically\n7. \(formatting)\n\nIMPORTANT: Create a flowing summary, not bullet points. Write it as a coherent paragraph or two.\n\nReturn ONLY the summary. No explanations, no preamble."
    }

    private static func bulletInstructions(useMarkdown: Bool) -> String {
        let formatting = useMarkdown ? "Use Markdown formatting (-, *, **, *) for bullets" : "Use simple dashes (-) or asterisks (*) for bullets"
        return "\n\nYour task: Convert the text into clear, concise bullet points while fixing any errors.\n\nRules:\n1. Fix spelling, grammar, and punctuation errors\n2. Convert paragraphs into bullet points\n3. Each bullet should be a complete, clear statement\n4. Preserve the original meaning and key information\n5. Keep the user's voice and terminology\n6. \(formatting)\n\nReturn ONLY the bulletized text. No explanations, no preamble."
    }

    private static func toneInstructions(tone: Tone, useMarkdown: Bool) -> String {
        let formatting = useMarkdown ? "Use Markdown formatting (bold, italic, headers, lists) to enhance readability" : "Return plain text without special formatting"
        switch tone {
        case .professional:
            return "\n\nYour task: Fix errors and elevate the text to a more professional tone while preserving the core message.\n\nRules:\n1. Fix spelling, grammar, and punctuation errors\n2. Preserve all existing paragraph breaks (blank lines between paragraphs) - do NOT remove them\n3. If text is one long paragraph, add paragraph breaks to separate topics\n4. Replace casual language with professional equivalents\n5. Remove slang and overly casual expressions\n6. Maintain a respectful, business-appropriate tone\n7. Keep the original meaning and intent\n8. Do not change what the user is saying, only how they say it\n9. \(formatting)\n\nReturn ONLY the corrected text. No explanations, no preamble."
        case .casual:
            return "\n\nYour task: Fix errors and make the text more conversational and friendly.\n\nRules:\n1. Fix spelling, grammar, and punctuation errors\n2. Preserve all existing paragraph breaks (blank lines between paragraphs) - do NOT remove them\n3. If text is one long paragraph, add paragraph breaks to separate topics\n4. Make formal language more conversational\n5. Add conversational warmth where appropriate\n6. Keep it natural and approachable\n7. Preserve the original meaning\n8. \(formatting)\n\nReturn ONLY the corrected text. No explanations, no preamble."
        case .preserve:
            return "\n\nYour task: Fix all spelling, grammar, and punctuation errors while preserving the user's unique voice and style.\n\nRules:\n1. Fix every spelling error\n2. Fix every grammar error\n3. Fix punctuation errors\n4. Preserve all existing paragraph breaks\n5. If text is one long paragraph, add paragraph breaks to separate topics\n6. Preserve the user's unique voice, tone, and personality\n7. Preserve informal language, slang, and casual expressions\n8. Do not rewrite sentences unless they contain errors\n9. Do not change vocabulary to sound more formal or sophisticated\n10. Do not add new information or change the meaning\n11. Do not homogenize the writing style\n12. \(formatting)\n\nReturn ONLY the corrected text. No explanations, no preamble."
        }
    }
}