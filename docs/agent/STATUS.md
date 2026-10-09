# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. Times in
     `updated:` and `at:` come from `date '+%Y-%m-%d %H:%M %Z'`, never from memory. -->

updated: 2026-10-09 19:00 CEST · commit: the commit that contains this file, a records-only
pull request off `main` at 1a24d26
verification: verified — command: `./ops/verify.sh` (exit 0, "OK: agent kit checks passed") and
`./ops/test-kit.sh` (153 passed, 0 failed, 6 known failures) — at: 2026-10-09 19:00 CEST, 1a24d26

## Now
- `main` is at 1a24d26 (pull request #12): the two skills, their check and install.sh custody
  have shipped; CI passed on that commit
- One T2 change file is open and needs rework before approval: `docs/agent/changes/session-briefing.md`
- Expected, not a to-do: the kit check prints two TODO lines (this repository is the template,
  DECISIONS.md 2026-09-28) and GAP lines for the briefing change's tests, which do not exist yet

## Last session
- Reconciled ROADMAP (#11); built and merged the skills (#12) · `docs/agent/specs/skills.md`
- Pickup test passed in Claude Code and Zed; Zed's own agent untested · `README.md`
- Reviewed the briefing plan: 4 open problems · `docs/agent/changes/session-briefing.md`
- Found: forked sessions skip the hook (matcher lacks `fork`) · `.claude/settings.json`

## Next
- Spike a hook `systemMessage` in Claude Code and in Zed · `docs/agent/changes/session-briefing.md`
- Then settle the briefing design, approve, build · `docs/agent/changes/session-briefing.md`
- Then the OpenSpec-style flow, its commands as kit- skills · `ROADMAP.md`
- Then the rollout: vault follow-up, TypeScript app, 2.2 fixes · `ROADMAP.md`

## Needs you
- Settle the briefing's open questions after the spike · `docs/agent/changes/session-briefing.md`
- Say what accepts a learning in a records PR; three wait below · `docs/agent/LEARNINGS.md`
- Optional: type `/kit-` in a Zed Agent thread (not Claude) in a trusted worktree · `README.md`

## Open questions (need a human)
- Which command revises a proposal after review; `kit-update` would read as updating the kit ·
  `ROADMAP.md`
- Proposed learnings, held until something accepts them: (1) check the maintainer's global hooks
  before a rule that pushes or edits instruction files (#7 was replaced by #8); (2) re-open a
  cited source before planning on its figures (research corrections of 2026-09-28 and 2026-10-09);
  (3) try what each client displays before building on it (the skills pickup test and the
  briefing review of 2026-10-09 each changed the plan)
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
