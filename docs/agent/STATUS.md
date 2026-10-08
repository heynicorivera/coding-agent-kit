# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-08 14:52 CEST · commit: the commit that contains this file, on branch
`records-push-and-times`, stacked on `record-vault-update` off `main` at a50f57d
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (118 passed, 0 failed, 6 known failures) — at: 2026-10-08 14:52 CEST,
uncommitted tree

## Now
- 2.1 is released: d217eab, tag `v2.1.0`. Pull requests #4 and #5 merged as d9ee6d5 and a50f57d;
  both workflows passed on each (`gh run list --branch main`)
- The notes vault runs kit v2.1.0 on its `kit-update` branch: stamp v2.1.0, its verify passes,
  a dry run has nothing left to write. Waits for a session in the vault (its AGENTS.md, STATUS,
  DECISIONS) and the maintainer's commit there
- Two branches wait to be pushed after that session, in order: `record-vault-update` (two more
  findings as known failures), then this one
- New on this branch: records-only changes are pushed to `main` at wrap-up, and STATUS.md carries
  times (AGENTS.md, Git; DECISIONS.md, 2026-10-08). The maintainer's global instructions still say
  never to push to `main`; the matching exception is proposed, not applied
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: refreshed this file (#4); the vault dry run, a rehearsal on a clone, and the
  maintainer's real run; four findings recorded as known failures, each reverse-checked (#5 and
  `record-vault-update`); the records-push rule and STATUS times (this branch)
- 2026-10-07: added `install.sh` (custody table, `.kit-new` sidecars, a KIT_VERSION stamp,
  `--dry-run`, `--from`), 25 self-test cases, the CI split, CHANGELOG 2.1.0; recorded the
  learnings-cap defect as two known failures

## Next
1. Maintainer: the vault session, commit there, then merge `kit-update` into the vault's main
   locally (it has no remote)
2. Push `record-vault-update`, then this branch, as pull requests; maintainer merges in that order
3. Maintainer: approve the global-instructions exception for records-only pushes
4. The TypeScript application with no kit yet: the first onboarding with `docs/agent/ONBOARD.md`;
   existing adopters take the new Git lines at their next update
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
     append decisions and learnings, then commit with the summary as the message. Records only:
     push to main. Anything else: push the branch and open a pull request (AGENTS.md, Git). -->
