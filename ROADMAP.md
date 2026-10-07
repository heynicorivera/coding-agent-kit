# Roadmap

Planned work, not built yet. Nothing here is promised by README.md or AGENTS.md. When an item
ships, it moves to CHANGELOG.md.

## Next
- **Update the three adopters with `install.sh`**, one at a time: a docs-only repository first,
  then a notes vault with a reduced kit, then fold in the fixes below, then the application
  repository of the first adoption. Record every surprise here before the next one.
- **Fixes found in adopters, planned as 2.2:**
  - The STATUS freshness rule fails bot commits and lockfile-only changes
    (`check_status_freshness` in `ops/check-agent-kit.sh`). The workflow half shipped in 2.1.
  - Stale references are judged by the disk, not git, so a backticked ignored path such as a
    `.env` passes locally and fails in CI (`check_stale_references`).
  - `ops/agent/session-end.sh` reads `git status --porcelain` without `--untracked-files=all`, so
    it stamps a STATUS.md just written inside a still-untracked `docs/agent/`.
  - Nothing says every command in `ops/verify.sh` must exit by itself; a watch-mode test runner
    costs the gate's timeout three turns in a row.
  - `check_hooks` reads `ops/verify.sh.` (with a sentence's full stop) out of a prose description
    in a hook config and reports a missing hook script.
- **Onboard one existing repository** with `docs/agent/ONBOARD.md`. This is the done-when of
  audit item 3.2; record what the prompt missed.

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
