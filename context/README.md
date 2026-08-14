# Safe shared AI context

This directory contains safe AI-readable context. Its files may be connected to Claude Cowork and read by Codex.

- [GLOBAL_AI_CONTEXT.md](GLOBAL_AI_CONTEXT.md) is the shared machine-wide operating context.
- [CLAUDE_COWORK_GLOBAL.txt](CLAUDE_COWORK_GLOBAL.txt) is the Cowork-specific Global Instructions text.

No secrets belong here. Claude Cowork should connect only `/Users/mantoshkumar/Desktop/project/ai-setups/context`, never the parent `ai-setups` directory or `config/`.
