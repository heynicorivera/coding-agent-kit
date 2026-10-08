# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-08 16:31 CEST · commit: the commit that contains this file, on branch
`records-via-pull-request` off `main` at a1578ef
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (118 passed, 0 failed, 6 known failures) — at: 2026-10-08 16:31 CEST,
uncommitted tree

## Now
- `main` is at a1578ef: #6 (two more rollout findings as known failures) and #7 (records at
  wrap-up; times in STATUS.md) merged; CI passed on both pull requests
- This branch: a records-only change goes through a pull request titled "Records: …" that the
  agent merges once CI passes, replacing #7's direct push, which the maintainer's push-to-main
  hook blocked (AGENTS.md, Git; DECISIONS.md, 2026-10-08). It also plans the OpenSpec-style flow
  (ROADMAP Next), and self-test cases now add to STATUS.md without growing it: four appended a
  line and broke, or passed for the wrong reason, with this file at its 60-line cap
- The maintainer's global Claude instructions still carry today's direct-push exception; it is no
  longer needed and is reverted by hand (CLAUDE.md files are protected)
- The notes vault runs kit v2.1.0 on its `kit-update` branch (stamp v2.1.0, its verify passes);
  its own session (AGENTS.md, STATUS, DECISIONS) waits until after the OpenSpec-style flow
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: #4 to #7 merged. The vault update: dry run, a rehearsal on a clone, the
  maintainer's real run. Four rollout findings as known failures, each reverse-checked (#5, #6).
  Records at wrap-up and STATUS times (#7), then records through self-merged pull requests
- 2026-10-07: added `install.sh`, 25 self-test cases, the CI split, CHANGELOG 2.1.0

## Next
1. Maintainer: merge this branch's pull request; revert the global direct-push exception
2. Design, then build, the OpenSpec-style change flow (ROADMAP Next): decisions first (layout,
   commands, tools), then a branch and a pull request
3. Maintainer: the vault session (prompt given), commit there, then merge `kit-update` into the
   vault's main locally (it has no remote)
4. The TypeScript application with no kit yet: the first onboarding with `docs/agent/ONBOARD.md`
5. The 2.2 fixes in ROADMAP.md (10 entries, 5 with known-failure tests), then the last two
   adopters on 2.2

## Open questions (need a human)
- Gemini/Antigravity hooks: designed, not shipped (handler field names unverified)
- Residual risk: the gate's state in ~/.cache/agent-kit is writable by the agent, and internal
  errors fail open; the pre-commit hook and CI are the backstops
- The pre-commit hook verifies the working tree, not the staged snapshot
- `shfmt` is not installed on this machine; `install.sh` is shellcheck-clean only

## Blockers
- none

<!-- Briefing: when the user asks what was covered or says they are available, answer from this
     file (last session, in progress, next, open questions, uncommitted) before proposing work.
     Wrap-up: when the user is done or asks to wrap up, run ./ops/verify.sh, rewrite this file,
     append decisions and learnings, commit with the summary as the message, then push a branch
     and open a pull request. Records only: title it "Records: …" and merge it once CI passes;
     anything else waits for the maintainer (AGENTS.md, Git). -->
