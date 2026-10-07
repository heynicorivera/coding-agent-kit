# Roadmap

Planned work, not built yet. Nothing here is promised by README.md or AGENTS.md. When an item
ships, it moves to CHANGELOG.md.

A finding is ready to fix when it has four parts: where it was seen (by role, never by repository
name), the symptom, the evidence, and the self-test case that proves the fix. Write that case
first as a `known_failure` in `ops/test-kit.sh`: it keeps the suite green while the defect exists
and fails it once the fix lands, which is the signal to make it a normal case and close the entry.
Findings are triaged before each adopter update.

## Next
- **Update the three adopters with `install.sh`**, one at a time: a docs-only repository first,
  then a notes vault with a reduced kit, then fold in the fixes below, then the application
  repository of the first adoption. Record every surprise here before the next one.
- **Fixes found in adopters, planned as 2.2:**
  - The learnings cap is not enforced as documented.
    Seen: kit review, 2026-10-07.
    Symptom: the LEARNINGS.md header promises at most 20 active entries, but no check counts them;
    `ops/agent/session-start.sh` injects only the first 40 lines of Active, so later entries are
    committed yet never reach a session, silently; and the check's 100-line cap counts Converted
    and Archived, which only grow, so passing it eventually means deleting archived entries.
    Evidence: `check_memory_files` in `ops/check-agent-kit.sh` checks lines and `evidence:` only;
    `head -40` in `session-start.sh`.
    Test: known failures "the check refuses a 21st active learning" and "a 41st active learning
    is injected or refused" in `ops/test-kit.sh`.
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
