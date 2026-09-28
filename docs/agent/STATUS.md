# Status
<!-- Injected at session start by the kit hooks. Rewritten, never appended, whenever code changes.
     Under 60 lines. Every claim names its evidence. No secrets, no personal data. -->

updated: 2026-09-28 · commit: uncommitted (first commit pending; the maintainer commits)
verification: verified — command: `./ops/verify.sh` — at: 2026-09-28, uncommitted tree (kit check OK, `./ops/test-kit.sh` 32/32)

## Now
- In progress: nothing
- Uncommitted: the whole kit v1.0 (staged, awaiting the maintainer's first commit and push)

## Last session
- 2026-09-28: applied the audit (research/audit-2026-09-28.md, deletable): AGENTS.md cut to 7 rules; pre-finish
  gate `ops/agent/stop_gate.py` on Claude Code, Codex, Copilot, Cursor; `ops/verify.sh`; LEARNINGS.md;
  `.gemini/settings.json` replaces GEMINI.md; check script with 10 rules; CI runs check + self-test +
  verify; LICENSE, Dependabot, README rewritten — verification: verified (`./ops/verify.sh`, uncommitted)

## Next
1. Maintainer: `git config user.name`, first commit on `main`, push to github.com/heynicorivera/coding-agent-kit,
   mark it as a template; confirm the `agent-kit` workflow is green
2. Adopters (per README): replace the KIT-PLACEHOLDER block in `ops/verify.sh`, fill AGENTS.md
3. Test pickup in Codex, Copilot CLI and Cursor (not tested locally); record results in README

## Open questions (need a human)
- Claude Code deny rules now block the agent from editing gate files (by design); edit them by hand
- Gemini/Antigravity hooks: designed, not shipped (handler field names unverified)

## Blockers
- none

<!-- Briefing: when the user asks what was covered or says they are available, answer from this
     file (last session, in progress, next, open questions, uncommitted) before proposing work.
     Wrap-up: when the user is done or asks to wrap up, run ./ops/verify.sh, rewrite this file,
     append decisions and learnings, then commit with the summary as the message. -->
