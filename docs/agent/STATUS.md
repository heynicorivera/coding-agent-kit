# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-09 16:05 CEST · commit: the commit that contains this file, a pull request off
`main` at b0c8f56
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (153 passed, 0 failed, 6 known failures) — at: 2026-10-09 16:05 CEST, 8e725e6
and the uncommitted records

## Now
- Branch `add-skills` ships `/kit-explore` and `/kit-debug`, the skills check and install.sh
  custody; it is code, so it waits for the maintainer's merge
- One T2 change file is open and not built: `docs/agent/changes/session-briefing.md`
- Expected, not a to-do: the kit check prints two TODO lines (this repository is the template,
  DECISIONS.md 2026-09-28) and GAP lines for the briefing change's tests, which do not exist yet

## Last session
- Reconciled ROADMAP with the skills-first order (PR #11) · `ROADMAP.md`
- Built 2 skills, their check and install.sh custody · `docs/agent/specs/skills.md`
- Pickup test passed in Claude Code and in Zed; Zed's own agent untested · `README.md`
- Mutation check found a weak test (it matched advisory GAP text); fixed and rerun ·
  `docs/agent/changes/archive/2026-10-09-add-skills.md`

## Next
- Build the session-start briefing · `docs/agent/changes/session-briefing.md`
- Then the OpenSpec-style flow, its commands as kit- skills · `ROADMAP.md`
- Then the rollout: vault follow-up, TypeScript app, 2.2 fixes · `ROADMAP.md`

## Needs you
- Merge the add-skills pull request once CI passes · `docs/agent/changes/archive/2026-10-09-add-skills.md`
- Review the briefing change before its build · `docs/agent/changes/session-briefing.md`
- Say what accepts a learning in a records PR; two wait below · `docs/agent/LEARNINGS.md`
- Optional: type `/kit-` in a Zed Agent thread (not Claude) in a trusted worktree · `README.md`

## Open questions (need a human)
- Which command revises a proposal after review; `kit-update` would read as updating the kit ·
  `ROADMAP.md`
- Proposed learnings, held until something accepts them: (1) check the maintainer's global hooks
  before a rule that pushes or edits instruction files (#7 was replaced by #8); (2) re-open a
  cited source before planning on its figures (research corrections of 2026-09-28 and 2026-10-09)
- Gemini/Antigravity hooks: designed, not shipped (handler field names unverified)
- Residual risk: the gate's state in ~/.cache/agent-kit is writable by the agent, and internal
  errors fail open; the pre-commit hook and CI are the backstops
- The pre-commit hook verifies the working tree, not the staged snapshot
- `shfmt` is not installed on this machine; `install.sh` is shellcheck-clean only

## Blockers
- none

<!-- Briefing: open the first reply of every session with Last session, Next and Needs you from
     this file, as written, then answer the user's message.
     Wrap-up: when the user is done or asks to wrap up, run ./ops/verify.sh, rewrite this file,
     append decisions and learnings, commit with the summary as the message, then push a branch
     and open a pull request. Records only: title it "Records: …" and merge it once CI passes;
     anything else waits for the maintainer (AGENTS.md, Git). -->
