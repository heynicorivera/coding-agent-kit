# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-08 · commit: the commit that contains this file, on branch `status-after-v2-1`
off `main` at d217eab
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (117 passed, 0 failed, 2 known failures) — at: 2026-10-08, d217eab + this file

## Now
- 2.1 is released: pull request #3 merged as d217eab, tag `v2.1.0` points at it, and both
  workflows (agent-kit, kit-self-test) passed on it (`gh run list --branch main`)
- The adopter rollout starts next, in the ROADMAP.md order; no adopter has 2.1 yet
- Expected here, not a to-do: this repository's `ops/verify.sh` keeps its KIT-PLACEHOLDER block
  and AGENTS.md its 6 placeholders, so the kit check prints two TODO lines. This repository is the
  template adopters copy (DECISIONS.md, 2026-09-28); `./ops/test-kit.sh` is its real suite

## Last session
- 2026-10-08: confirmed the merge, the re-tag and CI on main; rewrote this file
- 2026-10-07: added `install.sh` (custody table, `.kit-new` sidecars, a KIT_VERSION stamp in
  adopters, `--dry-run`, `--from`), a sidecar FAIL and a version NOTE in the kit check, 25
  self-test cases, the CI split, README "Updating the kit", CHANGELOG 2.1.0; change file archived
  as `docs/agent/changes/archive/2026-10-07-add-installer.md`
- Rehearsal on a throwaway clone of the first adopter: dry run and real run matched; a second run
  wrote nothing
- Learnings cap defect: recorded as two known failures in the self-test and a ROADMAP entry; fix
  planned for 2.2

## Next
1. Notes vault, an update (README, "Updating the kit in a repository"): on a new branch there,
   with no agent session open in it, a dry run with `--from v1.0.0` (read-only), then the
   maintainer runs the real one. Expected: kit-owned files overwritten, a KIT_VERSION stamp, and
   a `.kit-new` sidecar for its patched Claude settings; its kit check fails until the sidecar is
   merged and deleted. The maintainer then enables the pre-commit gate there (README Setup step 6)
2. Record what that run missed in ROADMAP.md (four-part format, a known_failure case) before the
   next adopter
3. The TypeScript application with no kit yet: the first onboarding with `docs/agent/ONBOARD.md`
4. The 2.2 fixes listed in ROADMAP.md, then the last two adopters on 2.2

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
