# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-08 · commit: the commit that contains this file, on branch
`record-vault-update` off `main` at a50f57d
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (117 passed, 0 failed, 6 known failures) — at: 2026-10-08, uncommitted tree

## Now
- 2.1 is released: d217eab, tag `v2.1.0`. Pull requests #4 and #5 merged as d9ee6d5 and a50f57d;
  both workflows passed on each (`gh run list --branch main`)
- The notes vault runs kit v2.1.0: committed on its `kit-update` branch, stamp v2.1.0, its own
  verify passes (both OKs), and a dry run has nothing left to write. Its Claude and Codex configs
  were merged three-way to keep its 2026-10-04 decisions (no session-end hook, nudges off)
- Waits for a session in the vault: its AGENTS.md (keep its seven rules, add `.githooks/` to its
  never-change rule, no change-file rule), STATUS and DECISIONS; the maintainer commits there
- This branch is committed locally, not pushed: it opens as a pull request after the vault
  session, with anything that session finds
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: refreshed this file (#4); the vault dry run, a rehearsal on a clone, and the
  maintainer's real run; four findings recorded as known failures and ROADMAP entries, each
  reverse-checked: sidecar and closing steps (#5), the AGENTS.md step and the STATUS nudge after a
  pull (this branch; change file
  `docs/agent/changes/archive/2026-10-08-vault-update-findings.md`)
- 2026-10-07: added `install.sh` (custody table, `.kit-new` sidecars, a KIT_VERSION stamp,
  `--dry-run`, `--from`), 25 self-test cases, the CI split, CHANGELOG 2.1.0; recorded the
  learnings-cap defect as two known failures

## Next
1. Maintainer: the vault session (prompt given), commit there, then merge `kit-update` into the
   vault's main locally (it has no remote)
2. Push this branch and open its pull request; maintainer merges
3. The TypeScript application with no kit yet: the first onboarding with `docs/agent/ONBOARD.md`
4. The 2.2 fixes in ROADMAP.md (10 entries, 5 with known-failure tests), then the last two
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
     append decisions and learnings, then commit with the summary as the message. -->
