# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-08 18:06 CEST · commit: the commit that contains this file, a records-only
pull request off `main` at 6ece6e7
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (118 passed, 0 failed, 6 known failures) — at: 2026-10-08 18:06 CEST, 6ece6e7

## Now
- `main` is at 6ece6e7; pull requests #4 to #8 merged on 2026-10-08, CI passed on each
- The rules now: every change goes through a pull request; a records-only one is titled
  "Records: …" and the agent merges it once CI passes, anything else waits for the maintainer
  (AGENTS.md, Git). STATUS.md times come from the clock
- Rule gap found at wrap-up: LEARNINGS.md needs a human to accept each learning, but as a record
  the agent would merge it itself. No learning was added (Next 1)
- The notes vault runs kit v2.1.0, committed on its `kit-update` branch (bd0ece4): stamp v2.1.0,
  its verify passes, a dry run has nothing left to write. Its own session waits (Next 3)
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: STATUS refresh (#4). Vault update: dry run, rehearsal on a clone, real run (settings
  merged three-way to keep its 2026-10-04 decisions). Four rollout findings as known failures
  (#5, #6). Records rule and STATUS times (#7), then self-merged records pull requests (#8; the
  push-to-main hook blocked direct pushes) with a self-test cap fix; OpenSpec-style flow planned
- 2026-10-07: added `install.sh`, 25 self-test cases, the CI split, CHANGELOG 2.1.0

## Next
1. Close the rule gap: keep LEARNINGS.md out of self-merged records, or say what accepts a
   learning. Then propose: "check the maintainer's global hooks before a rule that pushes or edits
   instruction files" (evidence: #7 replaced by #8; a blocked CLAUDE.md edit the same day)
2. Design, then build, the OpenSpec-style change flow (ROADMAP Next): decisions first (layout,
   command names, which tools), then a branch and a pull request
3. Maintainer: a vault session: keep its seven rules, add `.githooks/` and "fix an inherited
   verify failure first" to its rule 3, no change-file rule; DECISIONS entry, STATUS rewrite;
   then the maintainer commits and merges `kit-update` into its main locally (no remote)
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
