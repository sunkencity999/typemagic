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
