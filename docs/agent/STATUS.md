# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-06 · commit: branch harden-gate, 3 commits on a0e820f, not pushed (the maintainer commits)
verification: verified — command: `./ops/verify.sh` — at: 2026-10-06, b4a5765 plus the cleanup fix (kit check OK, `./ops/test-kit.sh` 92/92, also from a terminal)

## Now
- In progress: nothing; v2.0 (audit of 2026-10-06, phases 1–3 and 4.1–4.2) awaits review
- Branch harden-gate in the worktree /tmp/coding-agent-kit-harden-gate: phases 1–2, phase 3 with
  the release, and a third commit that stops `./ops/test-kit.sh` prompting on cleanup in a terminal

## Last session
- 2026-10-06, phase 1: the stop gate measures from a session base, so commits count (B1); a gate
  file changed since the base blocks (B2–B4); `.githooks/pre-commit`; Claude Bash deny patterns;
  one non-code list `ops/agent/non-code-paths.txt`; `ops/agent/session-end.sh` replaces its stamp
- 2026-10-06, phase 2: change files from `docs/agent/changes/_template.md`; AGENTS.md rule 3 tiers
  (old rules 2 and 3 merged); the gate's change-file nudge
- 2026-10-06, phase 3: living specs from `docs/agent/specs/_template.md`; `ops/agent/changes.py`
  (`check` with advisory GAP lines, `archive` merges Spec deltas); `docs/agent/ONBOARD.md`;
  untested configs moved to `contrib/untested/`; open-source model gate moved to `ROADMAP.md`
- 2026-10-06, phase 4: bug-fix rule (`T1 fix` needs `failed first:`); `CHANGELOG.md`; v2.0
- 2026-10-06, fix: the kit check aborted on a branch's first push (all-zero base); the v1.0 push
  to main failed CI that way (GitHub run 36441532465); it now notes it and skips range rules
- Evidence: `./ops/test-kit.sh` 32 → 92 cases; new cases fail against v1.0; 15 mutants of the gate
  and `changes.py` each fail a case; the suite passes under Python 3.8

## Next
1. Maintainer: push harden-gate; open a PR; merge when CI is green; tag the merge `v2.0.0`;
   run `git config core.hooksPath .githooks` in the main checkout; remove the worktree; start a
   new agent session
2. Onboard one existing repository with `docs/agent/ONBOARD.md`; record what it missed
3. Later (ROADMAP.md): open-source model gate, Windows, promoting `contrib/untested/` configs

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
