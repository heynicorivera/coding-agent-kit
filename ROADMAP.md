# Roadmap

Planned work, not built yet. Nothing here is promised by README.md or AGENTS.md. When an item
ships, it moves to CHANGELOG.md.

A finding is ready to fix when it has four parts: where it was seen (by role, never by repository
name), the symptom, the evidence, and the self-test case that proves the fix. Write that case
first as a `known_failure` in `ops/test-kit.sh`: it keeps the suite green while the defect exists
and fails it once the fix lands, which is the signal to make it a normal case and close the entry.
Findings are triaged before each adopter update.

## Next
- **Two skills, `kit-explore` and `kit-debug`, before the change flow.** Both are copied from
  upstream at a pinned commit with their licence, live in `.agents/skills/` with links in
  `.claude/skills/`, and come with a check and install.sh custody of every `kit-` folder, which
  the flow's commands then reuse. Planned in `docs/agent/changes/add-skills.md` (T2); waits for
  the maintainer's "approved".
- **A session-start briefing, after the skills.** Last session, Next and Needs you, copied from
  STATUS.md and shown before the maintainer types anything. Planned in
  `docs/agent/changes/session-briefing.md` (T2).
- **An OpenSpec-style change flow, before the rollout continues.** Each step of a change becomes a
  command an agent runs, on the change file and archive the kit already has. The commands ship as
  `kit-` skills in the skills folder (DECISIONS.md, 2026-10-09): its check and install.sh custody
  cover them, and the other tools read the same folder.
  1. Branch: each change starts on a new branch from `main`.
  2. Explore (optional): think an idea through; it writes nothing. Ships with the skills, as
     `kit-explore`.
  3. Propose (`kit-propose`): write `docs/agent/changes/<name>.md` from the template (intent,
     tier, acceptance, tasks; for T2 also design and spec delta) and stop before any code.
  4. Review: the maintainer reads it, and a command revises it (open, below). A T2 change waits
     for the maintainer's "approved" before anything is built.
  5. Apply (`kit-apply`), then archive (`kit-archive`): build it and run `./ops/verify.sh`;
     `./ops/agent/changes.py archive` folds the spec delta into `docs/agent/specs/`; then the
     pull request as usual.
  Open: the command that revises a proposal in step 4. The flow planned on 2026-10-08 had an
  update command; the naming decision of 2026-10-09 lists none, and a plain `kit-update` would
  read as updating the kit. Also open: the kit's single change file or OpenSpec's
  `openspec/changes/<name>/` layout. The OpenSpec CLI itself would add a Node dependency to a kit
  that needs only bash, git and python3.
  Done when: a change in this repository runs explore, propose, approve, apply and archive with
  the commands, and the self-test covers the shipped command files.
- **Roll the kit out to four repositories, one at a time, cheapest mistake first.** Each run is a
  test; record its surprises here before the next one starts.
  1. A notes vault with a reduced v1.0 kit: an update with `install.sh`, the first with a patched
     shared file and so the first `.kit-new` sidecar. Updated to v2.1.0 on 2026-10-08 (findings
     below); its own follow-up session (AGENTS.md, STATUS.md, DECISIONS.md) remains.
  2. A TypeScript application with no kit yet: the first onboarding with `docs/agent/ONBOARD.md`
     into an app that already has its own instruction files, CI and a hook manager.
  3. The fixes below, shipped as 2.2.
  4. A docs-only repository halfway through its first implementation: an update on 2.2.
  5. The application repository of the first adoption, close to production: last.
- **Fixes found in adopters, planned as 2.2:**
  - The learnings cap is not enforced as documented.
    Seen: kit review, 2026-10-07.
    Symptom: the LEARNINGS.md header promises at most 20 active entries, but no check counts them;
    `ops/agent/session-start.sh` injects only the first 40 lines of Active, so later entries are
    committed yet never reach a session, silently; and the check's 100-line cap counts Converted
    and Archived, which only grow, so passing it eventually means deleting archived entries.
    Evidence: `check_memory_files` in `ops/check-agent-kit.sh` checks lines and `evidence:` only;
    `head -40` in `session-start.sh`.
    Test: known failures "the check refuses a 21st active learning" and "a 41st active learning
    is injected or refused" in `ops/test-kit.sh`.
  - A sidecar re-adds what an adopter removed on purpose.
    Seen: notes-vault update, dry run and a rehearsal on a clone, 2026-10-08.
    Symptom: the `.kit-new` sidecar is the kit's whole file and the report a two-way diff (local
    against the kit's), so it cannot tell the kit's changes since `--from` from the adopter's own
    edits. The vault's diff showed a session-end hook and three deny rules it had removed by a
    recorded decision as kit lines, and its own deny rule and gate switch as removals; the kit's
    only change since v1.0.0 was 13 deny rules. Taking the kit's side would undo that decision.
    Evidence: `sync_one_shared` in `install.sh` writes the kit's file as the sidecar and diffs
    local against it, although `old_copy` already holds the base; `git merge-file` with the
    v1.0.0 copy as the base gave the right merge with one conflict.
    Test: known failure "install sidecar keeps a hook the adopter removed" in `ops/test-kit.sh`;
    the case "install writes a sidecar: kit copy beside it" changes with the fix.
  - The closing steps assume a remote.
    Seen: notes-vault update, 2026-10-08.
    Symptom: the report always ends with "commit on a branch, open a pull request", also in a
    repository without a remote (the vault has none) and after a run that wrote nothing.
    Evidence: the fixed `echo` at the end of `report_steps` in `install.sh`.
    Test: known failure "install closing steps fit a repository without a remote" in
    `ops/test-kit.sh`.
  - The AGENTS.md step assumes the kit's rule order.
    Seen: notes-vault update, 2026-10-08.
    Symptom: an update from before v2.0 says "make rules 1-3 say what the kit's say". The vault
    keeps its own seven rules (rule 1 protects its corpus, rule 2 is about its owner), so taken
    literally the step overwrites both; its rules 3 and 4 already carry the kit's rules 1 and 2.
    Evidence: the fixed `echo` under `before_v2` in `report_steps` in `install.sh`.
    Test: known failure "install AGENTS.md step fits an adopter with its own rules" in
    `ops/test-kit.sh`.
  - The STATUS nudge fires after a pull.
    Seen: this repository, a session that pulled the two merged pull requests, 2026-10-08.
    Symptom: a pull that brings code and its STATUS.md in one commit still asks for a STATUS
    rewrite: freshness compares file times, and checkout wrote `docs/agent/STATUS.md` 1.6 ms
    before `ops/test-kit.sh`, because it writes in path order.
    Evidence: `status_is_stale` in `ops/agent/stop_gate.py` compares `st_mtime`.
    Test: known failure "a pull that brings code with its STATUS.md does not nudge" in
    `ops/test-kit.sh`.
  - The STATUS freshness rule fails bot commits and lockfile-only changes
    (`check_status_freshness` in `ops/check-agent-kit.sh`). The workflow half shipped in 2.1.
  - Stale references are judged by the disk, not git, so a backticked ignored path such as a
    `.env` passes locally and fails in CI (`check_stale_references`).
  - `ops/agent/session-end.sh` reads `git status --porcelain` without `--untracked-files=all`, so
    it stamps a STATUS.md just written inside a still-untracked `docs/agent/`.
  - Nothing says every command in `ops/verify.sh` must exit by itself; a watch-mode test runner
    costs the gate's timeout three turns in a row.
  - `check_hooks` reads `ops/verify.sh.` (with a sentence's full stop) out of a prose description
    in a hook config and reports a missing hook script.
- **Onboard one existing repository** with `docs/agent/ONBOARD.md`. This is the done-when of
  audit item 3.2; record what the prompt missed.

## Later
- **Gate for an open-source model.** Pick a harness that supports a stop hook and wire it to
  `ops/agent/stop_gate.py`, as for Claude Code. Until then, the pre-commit hook and CI are the
  gate for a hookless harness. Waits for: a local model in daily use (audit item 3.5).
- **Windows support.** Port `ops/agent/session-start.sh`, `ops/agent/session-end.sh` and
  `.githooks/pre-commit` to Python, which the kit already requires (audit item 4.3).
- **Promote tool configs from `contrib/untested/`** one at a time, each after a live test that
  is recorded in README.md: Codex, Cursor, Copilot cloud agent, Gemini CLI, Aider.
- **Gemini CLI and Antigravity hooks.** Designed, not shipped: their handler field names are not
  verified in the vendors' documentation (PRD.md OQ1).
- **Copilot CLI with the Claude-format hooks.** It reads `.claude/settings.json`; how it treats an
  exit-2 Stop hook is undocumented (PRD.md OQ2). Test with `/hooks`.
