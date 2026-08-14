# Local secret store

This directory is the local secret store. Git ignores everything here except this README, and Claude Cowork must never connect to it.

`.github-pat` is currently used by local Codex for user-owned GitHub Projects v2 when the normal connector lacks that capability. Never print or expose secret values.

Future secrets can be added here without changing `.gitignore`: `config/*` is already ignored by default.
