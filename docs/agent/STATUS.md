# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-08 · commit: the commit that contains this file, on branch
`vault-rollout-findings`, stacked on `status-after-v2-1` (pull request #4) off `main` at d217eab
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (117 passed, 0 failed, 4 known failures) — at: 2026-10-08, uncommitted tree

## Now
- 2.1 is released: pull request #3 merged as d217eab, tag `v2.1.0` points at it, and both
  workflows (agent-kit, kit-self-test) passed on it (`gh run list --branch main`)
- In progress: the notes-vault update (rollout step 1). A `kit-update` branch exists there, no
  agent session is open in it, and the dry run is read. A rehearsal on a clone passed: after the
  merge its verify printed both OKs, and a second run wrote nothing. Waits for the maintainer's
  real run
- The vault's settings must be merged three-way (base: the v1.0.0 copy): its 2026-10-04 decision
  left out the session-end hook, which the two-way sidecar diff shows as a kit line
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: confirmed the merge, the re-tag and CI on main; refreshed this file (#4); ran the
  vault dry run and rehearsal; recorded two install.sh findings as known failures and ROADMAP
  entries, each reverse-checked (change file
  `docs/agent/changes/archive/2026-10-08-vault-rollout-findings.md`)
- 2026-10-07: added `install.sh` (custody table, `.kit-new` sidecars, a KIT_VERSION stamp,
  `--dry-run`, `--from`), 25 self-test cases, the CI split, CHANGELOG 2.1.0; recorded the
  learnings-cap defect as two known failures

## Next
1. Maintainer: merge #4, then this branch's pull request
2. Maintainer: the real vault run (install, apply the reviewed merged settings and Codex config,
   delete the sidecar, enable the pre-commit gate, verify, commit on `kit-update`)
3. A new agent session in the vault: AGENTS.md rules 1-3 against the kit's (decide whether the
   change-file rule fits a vault where "a capture is not a code change"), STATUS and DECISIONS
4. Record anything the real run adds in ROADMAP.md, then the TypeScript application onboarding
5. The 2.2 fixes in ROADMAP.md (8 entries, 3 with known-failure tests), then the last two
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
