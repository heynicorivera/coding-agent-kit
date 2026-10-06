# Roadmap

Planned work, not built yet. Nothing here is promised by README.md or AGENTS.md. When an item
ships, it moves to CHANGELOG.md.

## Next
- **Onboard one existing repository** with `docs/agent/ONBOARD.md`, after the 2.0 commit is on
  GitHub. This is the done-when of audit item 3.2; record what the prompt missed.

## Later
- **Gate for an open-source model.** Pick a harness that supports a stop hook and wire it to
  `ops/agent/stop_gate.py`, as for Claude Code. Until then, the pre-commit hook and CI are the
  gate for a hookless harness. Waits for: a local model in daily use (audit item 3.5).
- **Windows support.** Port `ops/agent/session-start.sh`, `ops/agent/session-end.sh` and
  `.githooks/pre-commit` to Python, which the kit already requires (audit item 4.3).
- **Promote tool configs from `contrib/untested/`** one at a time, each after a live test that
  is recorded in README.md: Codex, Cursor, Copilot cloud agent, Gemini CLI, Aider.
- **Gemini CLI and Antigravity hooks.** Designed, not shipped: their handler field names are not
  verified in the vendors' documentation (PRD.md OQ1).
- **Copilot CLI with the Claude-format hooks.** It reads `.claude/settings.json`; how it treats an
  exit-2 Stop hook is undocumented (PRD.md OQ2). Test with `/hooks`.
