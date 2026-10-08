# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-10-07 · commit: the commit that contains this file, on branch `add-installer` off
`main` at f864e2a, built in the worktree /tmp/coding-agent-kit-add-installer
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (117 passed, 0 failed, 2 known failures) — at: 2026-10-07, uncommitted tree

## Now
- In progress: 2.1, the updater. Waits for the maintainer: review, push `add-installer`, pull
  request, merge, tag `v2.1.0` on the merge.
- This repository's own `./ops/verify.sh` still has its KIT-PLACEHOLDER block and AGENTS.md its 6
  placeholders (both reported as TODO by the kit check); `./ops/test-kit.sh` is the real suite

## Last session
- 2026-10-07: added `install.sh` (custody table, `.kit-new` sidecars, a KIT_VERSION stamp in
  adopters, `--dry-run`, `--from`), a sidecar FAIL and a version NOTE in the kit check, 25 self-test
  cases, the CI split (`kit-self-test.yml` for the kit; the shipped workflow runs range rules on
  pull requests only), README "Updating the kit", PRD §6, CHANGELOG 2.1.0, ROADMAP fixes list
- Mutation check: AGENTS.md made kit-owned, a patched shared file overwritten, a dry run that
  writes, a check blind to sidecars, a dirty target accepted: each fails at least one case
- Rehearsal on a throwaway clone of the first adopter (tracked files only): dry run and real run
  matched; its own verify passed; a second run wrote nothing
- Change file closed and archived as `docs/agent/changes/archive/2026-10-07-add-installer.md`
- Learnings cap: documented 20 is not enforced, injection drops entries past 40 lines, the
  100-line cap counts the archive. Recorded as two known failures in the self-test and a ROADMAP
  entry in the new four-part format (where seen, symptom, evidence, test); fix planned for 2.2

## Next
1. Maintainer: merge, then tag `v2.1.0` on the merge commit (a first tag landed on f864e2a,
   before the merge; delete it and re-tag)
2. Roll out in the ROADMAP.md order: the notes vault first, with `install.sh --from v1.0.0` on a
   branch and no agent session open there (README, "Updating the kit")
3. Record what each run missed in ROADMAP.md before the next adopter

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
