# Show a short briefing at the start of every session
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Copy to docs/agent/changes/<short-name>.md
     and fill Intent, Tier, Acceptance, Tasks and Out of scope before writing code. When
     ./ops/verify.sh passes: tick the tasks, fill Evidence, set status: closed, then run
     ./ops/agent/changes.py archive docs/agent/changes/<short-name>.md, which merges the Spec delta
     and moves this file to archive/. ops/check-agent-kit.sh checks the shape.
     No secrets, no personal data. -->
status: open

## Intent
The maintainer sees, before typing anything, what the last session did, what comes next and what
needs them, in 3-5 one-line bullets per section, each pointing at a file or pull request with more
context, copied from STATUS.md as written (built after `docs/agent/changes/add-skills.md`).

## Tier
T2 · schema: the STATUS.md shape changes for every adopter, plus the session-start hook, the Claude Code hook config and the check

## Acceptance
- Given a STATUS.md in the new shape, when the session-start hook runs for Claude Code, then its JSON carries a header and the Last session, Next and Needs you sections as systemMessage and the full STATUS.md and learnings as additionalContext · test: `ops/test-kit.sh::briefing claude hook shows three sections`
- Given the same STATUS.md, when the hook runs for Codex or Cursor, then their output is what it was before this change · test: `ops/test-kit.sh::briefing other consumers unchanged`
- Given Last session or Next with 2 or 6 bullets, or Needs you with 0 or 6, when the check runs, then it fails · test: `ops/test-kit.sh::briefing check counts bullets`
- Given a briefing bullet that wraps to a second line or is longer than 100 characters, when the check runs, then it fails · test: `ops/test-kit.sh::briefing check refuses a long bullet`
- Given a briefing bullet with neither a backticked path nor a URL, other than "- none" under Needs you, when the check runs, then it fails · test: `ops/test-kit.sh::briefing check refuses a bullet without a link`
- Given a STATUS.md without a Needs you section, when the check runs, then it fails · test: `ops/test-kit.sh::briefing check needs the three sections`
- Given an adopter updated by install.sh, when the report prints, then its STATUS.md step names the new shape · test: `ops/test-kit.sh::install report names the briefing shape`

## Tasks
- [ ] Branch `session-briefing` from `main` once add-skills is merged, in a separate worktree
- [ ] `ops/agent/session-start.sh --format claude`: JSON with `systemMessage` and `additionalContext`
- [ ] `.claude/settings.json`: the SessionStart hook passes `--format claude`
- [ ] `check_memory_files`: the three sections, bullet counts, one line of at most 100 characters, a path or URL in each
- [ ] STATUS.md header comment: the new shape, and the first-reply briefing for tools without the hook
- [ ] `install.sh` report: the STATUS.md step names the new shape
- [ ] `ops/test-kit.sh`: the cases above; break each rule once
- [ ] PRD R4 and R5; README; CHANGELOG; DECISIONS; this repository's STATUS.md in the new shape
- [ ] Maintainer: pickup test in Claude Code (briefing before the first prompt, paths clickable) and Zed (first reply)

## Out of scope
- A briefing written by the model at session start, and showing STATUS.md whole
- What Codex and Cursor display (their configs are untested; their output stays as it is)
- Real terminal hyperlinks: Claude Code's hook docs reject OSC 8 sequences
- Keeping a STATUS.md in the old shape passing; the check names the fix instead

## Evidence
- verification: <verified | partial | failed> — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: <date>, <commit>
- last lines: <the last lines of both commands>
- mutation check: <each broken rule fails at least one briefing case>

## Design
- Shape, as chosen by the maintainer on 2026-10-09 (the time comes from STATUS.md's `updated:`):

      Briefing · docs/agent/STATUS.md · updated <date> <time> <zone>

      Last session
      - Verified 5 skill candidates, kept 2 · `research/skills-addons-proposal.md`
      - Planned the skills change (T2) · `docs/agent/changes/add-skills.md`
      - Kit check passes; nothing committed yet · `ops/verify.sh`

      Next
      - Build add-skills in a separate worktree · `docs/agent/changes/add-skills.md`
      - Then this briefing · `docs/agent/changes/session-briefing.md`
      - Then the OpenSpec-style flow · `ROADMAP.md`

      Needs you
      - Approve the skills change · `docs/agent/changes/add-skills.md`

- Source: STATUS.md's sections Last session (3-5 bullets), Next (3-5) and Needs you (1-5, "- none"
  allowed), written at wrap-up, when the agent knows the session best, and shown as written. Each
  bullet is one line of at most 100 characters (the kit's line width) and names its evidence as a
  backticked path or a URL, which the header already asks of every claim; `check_stale_references`
  already fails a backticked path that does not exist. Needs you holds decisions, approvals and
  manual steps waiting on the maintainer; Open questions keeps the known unknowns. Rejected: a
  model-written briefing at session start (tokens every session, and it can drift from the file);
  Claude Code's `initialUserMessage` (only in `claude -p`); STATUS.md whole (60 lines is not a
  glance); a separate briefing file (two sources of truth).
- Claude Code: `ops/agent/session-start.sh --format claude` prints JSON: `systemMessage` with the
  header and the three sections, and `hookSpecificOutput.additionalContext` with today's body plus
  a line saying the user has seen the briefing, so the agent does not repeat it. The hook config
  in `.claude/settings.json` gains the flag; an adopter who patched that file gets a sidecar.
- Other tools: Codex keeps plain stdout and Cursor its JSON. Zed and the tools without a hook get
  the briefing from the STATUS.md header: the first reply of a session opens with the three
  sections, as written, unless a hook already showed them.
- Links: a terminal makes paths and URLs clickable when it detects them (Cmd-click in iTerm2, Zed,
  VS Code); Zed's agent renders its reply as Markdown. Whether Claude Code renders Markdown in a
  hook's `systemMessage` is not documented, so the bullets use plain paths, tested in the pickup
  step.
- Migration: STATUS.md is adopter-owned, so install.sh never rewrites it. After an update, the check
  fails on an old-shaped STATUS.md and names the sections and limits; the install report says the
  same. No transition period (the maintainer's rule: replace, don't deprecate).
- Risks: the 100-character limit may force terse bullets; the hook's message style in Claude Code
  is untested; a wrap-up that skips the rewrite leaves a stale briefing, which the freshness rules
  (R7) already catch for code changes. Found at the 2026-10-09 wrap-up: the self-test copies the
  kit without `research/`, so a backticked research path in STATUS.md failed 8 cases; the check
  must accept a plain path there, or the bullet must point at a file that ships.

## Spec delta
spec: docs/agent/specs/briefing.md
### ADDED
- BRIEF-1: STATUS.md has the sections Last session (3-5 bullets), Next (3-5) and Needs you (1-5, or "- none"), each bullet one line of at most 100 characters naming a backticked path or a URL · test: `ops/test-kit.sh::briefing check counts bullets`
- BRIEF-2: In Claude Code, the session-start hook shows those three sections under a header line before the first prompt, without a model call · test: `ops/test-kit.sh::briefing claude hook shows three sections`
- BRIEF-3: The hook still puts the full STATUS.md and the active learnings into the agent's context, for every consumer · test: `ops/test-kit.sh::briefing other consumers unchanged`
- BRIEF-4: install.sh's report names the STATUS.md shape when it lists the STATUS.md step · test: `ops/test-kit.sh::install report names the briefing shape`
