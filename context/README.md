# Safe shared AI context

This directory contains safe AI-readable context. Its files may be connected to Claude Cowork and read by Codex.

- [GLOBAL_AI_CONTEXT.md](GLOBAL_AI_CONTEXT.md) is the shared machine-wide operating context.
- [CLAUDE_COWORK_GLOBAL.txt](CLAUDE_COWORK_GLOBAL.txt) is the Cowork-specific Global Instructions text.

No secrets belong here. Claude Cowork should connect only this `context/` directory, never the repository root or its sibling `config/` directory.
