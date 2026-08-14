# Local secret store

This directory is the local secret store. Git ignores everything here except this README, and Claude Cowork must never connect to it.

`.github-pat` is currently used by local Codex for user-owned GitHub Projects v2 when the normal connector lacks that capability. Never print or expose secret values.

Future secrets can be added here without changing `.gitignore`: `config/*` is already ignored by default.

## File permissions

Restrict every secret to the current user. On macOS and Linux, set `.github-pat` to mode `600` with `chmod 600 config/.github-pat`. On Windows, use a user-only NTFS access-control list. Do not rely on the filename or Git ignore rule as the only protection.
