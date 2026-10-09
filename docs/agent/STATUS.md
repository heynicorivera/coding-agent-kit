# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-09 12:18 CEST · commit: the commit that contains this file, a records-only
pull request off `main` at f0b2239
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (118 passed, 0 failed, 6 known failures) — at: 2026-10-09 12:18 CEST, f0b2239

## Now
- `main` is at f0b2239 (pull request #9); this session wrote plans and research, no code
- Two T2 change files are open and nothing is built: `docs/agent/changes/add-skills.md` waits
  for approval; `docs/agent/changes/session-briefing.md` is built after it
- Expected, not a to-do: the kit check prints two TODO lines (this repository is the template,
  DECISIONS.md 2026-09-28) and GAP lines for the open changes' tests, which do not exist yet

## Last session
- Verified 5 skill candidates, kept 2 · research/skills-addons-proposal.md
- Planned /kit-explore and /kit-debug (T2) · `docs/agent/changes/add-skills.md`
- Planned a session-start briefing (T2) · `docs/agent/changes/session-briefing.md`
- Decided: skills before the OpenSpec flow, kit- names · `docs/agent/DECISIONS.md`

## Next
- Build add-skills in a separate worktree once approved · `docs/agent/changes/add-skills.md`
- Then the briefing change · `docs/agent/changes/session-briefing.md`
- Then the OpenSpec-style flow, its commands as kit- skills · `ROADMAP.md`
- Then the rollout: vault follow-up, TypeScript app, 2.2 fixes · `ROADMAP.md`

## Needs you
- Approve the skills change, or say what to change · `docs/agent/changes/add-skills.md`
- Review the briefing change before its build · `docs/agent/changes/session-briefing.md`
- Say what accepts a learning in a records PR; two wait below · `docs/agent/LEARNINGS.md`

## Open questions (need a human)
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
