# TypeMagic MCP Server

**AI writing tools for Claude Desktop, Cursor, Windsurf, and other MCP-compatible agents.**

TypeMagic MCP gives your AI assistant access to professional writing tools — polish text, check grammar, rephrase sentences, translate into 13 languages, generate documents from templates, and apply custom voice profiles — all powered by the TypeMagic API.

## Quick Start

### 1. Get an API Key

1. Sign in at [typemagic.pro/profile.html](https://typemagic.pro/profile.html)
2. Scroll to **API Keys** → enter a name → click **Generate Key**
3. Copy the key (starts with `tm_`)

### 2. Add to Claude Desktop

Edit your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "typemagic": {
      "command": "npx",
      "args": ["typemagic-mcp"],
      "env": {
        "TYPEMAGIC_API_KEY": "tm_your_key_here"
      }
    }
  }
}
```

Restart Claude Desktop. You'll see TypeMagic tools in the tools menu.

### 3. Add to Cursor / Windsurf

Add to your MCP settings:

```json
{
  "typemagic": {
    "command": "npx",
    "args": ["typemagic-mcp"],
    "env": {
      "TYPEMAGIC_API_KEY": "tm_your_key_here"
    }
  }
}
```

## Available Tools

| Tool | Description |
|------|-------------|
| `polish_text` | Fix grammar, spelling, punctuation. Improve clarity while preserving voice. |
| `summarize_text` | Create a concise TL;DR summary. |
| `convert_to_bullets` | Convert text into organized bullet points. |
| `format_as_markdown` | Reformat into structured Markdown with headings and lists. |
| `check_text` | Analyze for grammar, clarity, engagement, delivery, and style issues. |
| `rephrase_text` | Get 3 alternative phrasings for any text. |
| `translate_text` | Translate into 13 languages with natural, polished output. |
| `generate_from_template` | Generate a full draft from a template (Cover Letter, Blog Post, etc.). |
| `custom_instruction` | Process text with any custom instruction. |
| `list_profiles` | List your saved voice profiles. |
| `list_templates` | List available document templates and their fields. |
| `check_usage` | Check your API usage and remaining requests for today. |

## Voice Profiles

If you've created voice profiles in the TypeMagic web editor, you can use them via the API:

1. Call `list_profiles` to see your saved profiles and their IDs.
2. Pass `profileId` to any writing tool to emulate that voice.

Example: *"Polish this email using my CEO Voice profile"* → the agent calls `list_profiles`, finds the ID, then calls `polish_text` with that `profileId`.

## Templates

Available templates for `generate_from_template`:

- **cover_letter** — Job title, company, skills, notes
- **cold_email** — Recipient, purpose, value prop, CTA
- **meeting_summary** — Topic, attendees, raw notes
- **project_proposal** — Project name, problem, solution, timeline
- **blog_post** — Topic, audience, key points, CTA
- **complaint_letter** — Company, issue, resolution, deadline
- **thank_you** — Recipient, occasion, specifics
- **executive_summary** — Subject, findings, recommendations

Call `list_templates` to see the exact field keys and descriptions.

## Example Prompts for Your AI Agent

Copy-paste these into Claude Desktop, Cursor, or any MCP-connected agent:

| Prompt | Tools Used |
|--------|------------|
| *"Polish this email to sound professional but warm, then translate it into Spanish for my colleague in Madrid."* | `polish_text` → `translate_text` |
| *"List my TypeMagic voice profiles. Then take these meeting notes and turn them into a blog post using my 'Blog Casual' voice."* | `list_profiles` → `custom_instruction` |
| *"Generate a cover letter for a Senior Product Manager role at Stripe. Highlight my 5 years of B2B SaaS experience."* | `generate_from_template` |
| *"Take this PR description and convert it into executive-friendly bullet points. Target audience: non-technical leadership."* | `convert_to_bullets` |
| *"Check this document for grammar, clarity, and style issues. Then fix any issues you find by polishing the text."* | `check_text` → `polish_text` |
| *"Translate this product announcement into French, German, and Japanese. Keep it concise and professional."* | `translate_text` × 3 |
| *"Here are my raw meeting notes. Generate a structured meeting summary, then also give me a concise TL;DR."* | `generate_from_template` → `summarize_text` |
| *"Give me 3 alternative ways to phrase this call-to-action, then polish the best one in a friendly tone."* | `rephrase_text` → `polish_text` |
| *"Take this README and reformat it as clean Markdown with proper headings. Target audience: developers."* | `format_as_markdown` |
| *"Polish this technical explanation once in a casual tone for team Slack, and once in a professional tone for the client email."* | `polish_text` × 2 |

**Power move:** Chain multiple tools in one prompt. Your agent calls them in sequence automatically. *"Check my essay for issues, polish it in my CEO voice, then give me a concise summary."* — three TypeMagic tools, one prompt.

## Supported Languages (translate_text)

Spanish, French, German, Italian, Portuguese, Dutch, Russian, Japanese, Korean, Chinese (Simplified), Hindi, Arabic, English

## Rate Limits

- **1,000 requests per day** per API key
- Use `check_usage` to see your remaining balance
- Rate limit headers are included in every response

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TYPEMAGIC_API_KEY` | Yes | Your TypeMagic API key (starts with `tm_`) |
| `TYPEMAGIC_API_URL` | No | Custom API base URL (default: TypeMagic Cloud Functions) |

## Manual Run

```bash
TYPEMAGIC_API_KEY=tm_xxx npx typemagic-mcp
```

Or install globally:

```bash
npm install -g typemagic-mcp
TYPEMAGIC_API_KEY=tm_xxx typemagic-mcp
```

## Links

- **Web Editor**: [typemagic.pro/app](https://typemagic.pro/app)
- **Documentation**: [typemagic.pro/docs](https://typemagic.pro/docs.html)
- **API Key Management**: [typemagic.pro/profile](https://typemagic.pro/profile.html)
- **GitHub**: [github.com/sunkencity999/typemagic](https://github.com/sunkencity999/typemagic)

## License

MIT
