# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-06 · commit: uncommitted on branch harden-gate, based on a0e820f (the maintainer commits)
verification: verified — command: `./ops/verify.sh` — at: 2026-10-06, uncommitted tree on a0e820f (kit check OK, `./ops/test-kit.sh` 71/71)

## Now
- In progress: nothing; phases 1 and 2 of the 2026-10-06 audit are done and await review
- Uncommitted: all of it, on branch harden-gate in the worktree /tmp/coding-agent-kit-harden-gate

## Last session
- 2026-10-06, phase 1 (harden the gate): `ops/agent/stop_gate.py` measures changes from a session
  base recorded by `ops/agent/session-start.sh`, so commits count (B1); a gate file changed, deleted
  or `chmod -x`-ed since the base blocks, and "unconfigured" is read from the base (B2–B4);
  `.githooks/pre-commit` runs verify for every tool; Claude deny list gains Bash patterns;
  `ops/agent/non-code-paths.txt` is the one non-code list (README-only edits skip verify);
  `ops/agent/session-end.sh` replaces its stamp instead of appending
- 2026-10-06, phase 2 (intent layer): `docs/agent/changes/_template.md`; AGENTS.md rule 3 (T0/T1/T2;
  old rules 2 and 3 merged); the gate nudges once on a claim when > 3 files or > 50 lines changed
  without a change file, or one is still open; `check_change_files` in the kit check
- Evidence: `./ops/test-kit.sh` 32 → 71 cases; the 24 new behaviour cases fail against v1.0;
  7 mutants of the gate each fail at least one case; the suite also passes under Python 3.8
- `AGENT_KIT_STATUS_GATE` is now `AGENT_KIT_NUDGES`; README, PRD (R-verify, R7, R12, R14, new R18)
  and DECISIONS updated; README says Version 1.1

## Next
1. Maintainer: review the worktree diff, commit on harden-gate, push, open a PR, merge when CI is
   green; then `git config core.hooksPath .githooks` in each clone and start a new session
   (a session opened before the merge has no recorded base and can block on the new gate files)
2. Phase 3 needs input: the harness that runs the open-source model (3.4, 3.5), one existing repo
   to onboard (3.2), approval to move untested tool configs to contrib/untested/ (3.4)
3. Phase 4: git tags and a CHANGELOG; the bug-fix flow
4. Test pickup in Codex, Copilot CLI and Cursor (not tested locally); record results in README

## Open questions (need a human)
- Gemini/Antigravity hooks: designed, not shipped (handler field names unverified)
- Residual risk: the gate's state in ~/.cache/agent-kit is writable by the agent, and internal
  errors fail open; the pre-commit hook and CI are the backstops
- The pre-commit hook verifies the working tree, not the staged snapshot

## Blockers
- none

<!-- Briefing: when the user asks what was covered or says they are available, answer from this
     file (last session, in progress, next, open questions, uncommitted) before proposing work.
     Wrap-up: when the user is done or asks to wrap up, run ./ops/verify.sh, rewrite this file,
     append decisions and learnings, then commit with the summary as the message. -->
