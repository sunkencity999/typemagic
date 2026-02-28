#!/usr/bin/env node

/* ================================================
   TypeMagic MCP Server
   ================================================
   Exposes TypeMagic's AI writing tools as MCP tools
   for Claude Desktop, Cursor, Windsurf, and other
   MCP-compatible AI agents.

   Usage:
     TYPEMAGIC_API_KEY=tm_xxx npx typemagic-mcp
   
   Or in Claude Desktop config:
     {
       "mcpServers": {
         "typemagic": {
           "command": "npx",
           "args": ["typemagic-mcp"],
           "env": { "TYPEMAGIC_API_KEY": "tm_xxx" }
         }
       }
     }
   ================================================ */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const fetch = require('node-fetch');

// ── Configuration ──

const API_KEY = process.env.TYPEMAGIC_API_KEY;
const API_BASE = process.env.TYPEMAGIC_API_URL || 'https://us-central1-typemagic-ab70c.cloudfunctions.net/api';

if (!API_KEY) {
    console.error('Error: TYPEMAGIC_API_KEY environment variable is required.');
    console.error('Generate one at https://typemagic.pro/profile.html');
    process.exit(1);
}

// ── API Helper ──

async function callAPI(endpoint, method = 'POST', body = null) {
    const opts = {
        method,
        headers: {
            'Authorization': `Bearer ${API_KEY}`,
            'Content-Type': 'application/json',
        },
    };
    if (body) opts.body = JSON.stringify(body);

    const res = await fetch(`${API_BASE}${endpoint}`, opts);
    const data = await res.json();

    if (!res.ok) {
        throw new Error(data.error || `API error ${res.status}`);
    }
    return data;
}

// ── Tool Definitions ──

const TOOLS = [
    {
        name: 'polish_text',
        description: 'Polish and improve text — fix grammar, spelling, punctuation, and improve clarity while preserving the author\'s voice and meaning. Optionally apply a specific voice profile.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to polish' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone for the output (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID to emulate a specific writing style (optional)' },
                goals: {
                    type: 'object',
                    description: 'Writing goals (optional)',
                    properties: {
                        audience: { type: 'string', enum: ['general', 'expert', 'executive', 'academic', 'customer'] },
                        formality: { type: 'string', enum: ['default', 'informal', 'neutral', 'formal'] },
                        domain: { type: 'string', enum: ['general', 'business', 'technical', 'creative', 'academic', 'legal', 'medical', 'marketing'] },
                        intent: { type: 'string', enum: ['default', 'inform', 'persuade', 'describe', 'instruct', 'entertain'] },
                    },
                },
            },
            required: ['text'],
        },
    },
    {
        name: 'summarize_text',
        description: 'Create a concise TL;DR summary of the provided text.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to summarize' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text'],
        },
    },
    {
        name: 'convert_to_bullets',
        description: 'Convert text into clean, organized bullet points.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to convert' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text'],
        },
    },
    {
        name: 'format_as_markdown',
        description: 'Reformat text into clean, well-structured Markdown with headings, lists, and emphasis.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to format' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text'],
        },
    },
    {
        name: 'check_text',
        description: 'Analyze text for grammar, spelling, clarity, engagement, delivery, and style issues. Returns a list of issues with suggested fixes.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to check' },
            },
            required: ['text'],
        },
    },
    {
        name: 'rephrase_text',
        description: 'Get 3 alternative phrasings for a piece of text, each with a different approach.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to rephrase' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text'],
        },
    },
    {
        name: 'translate_text',
        description: 'Translate text into another language with polished, natural-sounding output (not word-for-word literal translation).',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to translate' },
                language: { type: 'string', description: 'Target language (e.g. Spanish, French, German, Japanese, Korean, Chinese, Arabic, etc.)' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text', 'language'],
        },
    },
    {
        name: 'generate_from_template',
        description: 'Generate a full document draft from a template. Available templates: cover_letter, cold_email, meeting_summary, project_proposal, blog_post, complaint_letter, thank_you, executive_summary. Call list_templates first to see required fields.',
        inputSchema: {
            type: 'object',
            properties: {
                templateId: { type: 'string', description: 'Template ID (e.g. cover_letter, blog_post)' },
                fields: { type: 'object', description: 'Template field values (keys depend on template — use list_templates to see required fields)' },
                tone: { type: 'string', enum: ['keep', 'professional', 'casual', 'friendly', 'concise'], description: 'Tone (default: keep)' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['templateId', 'fields'],
        },
    },
    {
        name: 'custom_instruction',
        description: 'Process text with a custom instruction. Send any text with any instruction for the AI to follow.',
        inputSchema: {
            type: 'object',
            properties: {
                text: { type: 'string', description: 'The text to process' },
                instruction: { type: 'string', description: 'Custom instruction for the AI (e.g. "Rewrite as a LinkedIn post with a hook")' },
                profileId: { type: 'string', description: 'Voice profile ID (optional)' },
            },
            required: ['text', 'instruction'],
        },
    },
    {
        name: 'list_profiles',
        description: 'List all voice profiles saved in your TypeMagic account. Returns profile IDs, names, and traits. Use a profile ID with other tools to emulate a specific writing style.',
        inputSchema: {
            type: 'object',
            properties: {},
        },
    },
    {
        name: 'list_templates',
        description: 'List all available document templates with their required fields. Use with generate_from_template.',
        inputSchema: {
            type: 'object',
            properties: {},
        },
    },
    {
        name: 'check_usage',
        description: 'Check your API usage for today, including remaining requests.',
        inputSchema: {
            type: 'object',
            properties: {},
        },
    },
];

// ── Tool Handlers ──

async function handleTool(name, args) {
    switch (name) {
        case 'polish_text':
            return await callAPI('/polish', 'POST', {
                text: args.text, tone: args.tone, goals: args.goals, profileId: args.profileId,
            });

        case 'summarize_text':
            return await callAPI('/summarize', 'POST', {
                text: args.text, tone: args.tone, profileId: args.profileId,
            });

        case 'convert_to_bullets':
            return await callAPI('/bullets', 'POST', {
                text: args.text, tone: args.tone, profileId: args.profileId,
            });

        case 'format_as_markdown':
            return await callAPI('/markdown', 'POST', {
                text: args.text, tone: args.tone, profileId: args.profileId,
            });

        case 'check_text':
            return await callAPI('/check', 'POST', { text: args.text });

        case 'rephrase_text':
            return await callAPI('/rephrase', 'POST', {
                text: args.text, profileId: args.profileId,
            });

        case 'translate_text':
            return await callAPI('/translate', 'POST', {
                text: args.text, language: args.language, tone: args.tone, profileId: args.profileId,
            });

        case 'generate_from_template':
            return await callAPI('/template', 'POST', {
                templateId: args.templateId, fields: args.fields, tone: args.tone, profileId: args.profileId,
            });

        case 'custom_instruction':
            return await callAPI('/custom', 'POST', {
                text: args.text, instruction: args.instruction, profileId: args.profileId,
            });

        case 'list_profiles':
            return await callAPI('/profiles', 'GET');

        case 'list_templates':
            return await callAPI('/templates', 'GET');

        case 'check_usage':
            return await callAPI('/usage', 'GET');

        default:
            throw new Error(`Unknown tool: ${name}`);
    }
}

// ── Server Setup ──

async function main() {
    const server = new Server(
        {
            name: 'typemagic-mcp',
            version: '1.0.0',
        },
        {
            capabilities: {
                tools: {},
            },
        }
    );

    // List available tools
    server.setRequestHandler(ListToolsRequestSchema, async () => {
        return { tools: TOOLS };
    });

    // Handle tool calls
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;

        try {
            const result = await handleTool(name, args || {});
            // Format the result as text content for the agent
            const text = typeof result === 'string' ? result : JSON.stringify(result, null, 2);
            return {
                content: [{ type: 'text', text }],
            };
        } catch (err) {
            return {
                content: [{ type: 'text', text: `Error: ${err.message}` }],
                isError: true,
            };
        }
    });

    // Connect via stdio
    const transport = new StdioServerTransport();
    await server.connect(transport);
}

main().catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
});
