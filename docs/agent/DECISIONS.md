# Decisions

Append-only log of decisions and the reason behind them. Newest at the bottom. Read on demand,
not at session start. No secrets, no personal data; refer to people by role.

Format: `- YYYY-MM-DD: <decision>. Why: <reason>. Rejected: <alternatives, optional>.`

- 2026-09-28: Adopted the agent starter kit: one canonical AGENTS.md, pointer files per tool,
  STATUS.md and DECISIONS.md as shared session memory. Why: AGENTS.md is the only instruction
  file every tool reads, and one source of truth avoids contradictory rules (see PRD.md).
- 2026-09-28: Kit scripts live in `ops/` (`ops/check-agent-kit.sh`, `ops/agent/`), not
  `scripts/`. Why: chosen by the maintainer; hook configs, CI workflow, AGENTS.md, README and
  PRD updated to match. Rejected: `scripts/` (the PRD v1.0 name).
- 2026-09-28: Added a pre-finish gate (`ops/agent/stop_gate.py`) on Claude Code, Codex, Copilot and
  Cursor; reverses the draft PRD's rejection of a Stop hook. Why: prose self-checks do not work without
  external feedback (arXiv 2310.01798, 2406.01297); 31.7 % of behaviour-changing edits were self-endorsed
  (2605.21537); every one of these tools documents a hook that can force continuation. The gate is
  conditional (dirty tree, once per change set), bounded (3 strikes) and fail-open, as in
  github.com/elijahmanlockedin112/verify-gate-hook and github.com/LZong-tw/clawback.
- 2026-09-28: Capped AGENTS.md at 7 ranked rules and 100 lines, checked; reverses the v0.3 rule-cap
  rejection. Why: all-instructions-satisfied accuracy 0.574 at 5 and 0.213 at 10 (arXiv 2509.21051);
  "breaks down beyond 5-6 simultaneous constraints" (2608.12426). The line cap is a cost choice
  (file structure had no measurable compliance effect, 2605.10039; context files cost +20 %, 2602.11988).
- 2026-09-28: Added `ops/verify.sh` as the single verification command; justfile still rejected.
  Why: harness and executable checks move outcomes (arXiv 2602.19594, 2607.03691, 2304.05128,
  2509.24148); no study covers task runners; a shell script adds no dependency.
- 2026-09-28: Replaced `GEMINI.md` with `.gemini/settings.json` (`context.fileName: ["AGENTS.md"]`).
  Why: documented on geminicli.com (gemini-md, configuration); Antigravity reads AGENTS.md natively and
  its handling of `@` imports is undocumented, so an import could load the file twice.
- 2026-09-28: Hook commands resolve the repo root with `$(git rev-parse --show-toplevel)`; Codex
  SessionEnd timeout set to 3 s. Why: Copilot CLI reads `.claude/settings.json` ("Cross-tool …
  are also read", docs.github.com hooks reference); Codex documents a 3 s ceiling; Claude documents
  that a mistyped path "leaves the gate silently disabled".
- 2026-09-28: STATUS.md carries `updated`, `commit` and `verification: none|verified|partial|failed`
  with command and commit; ≤ 60 lines; rewritten, never appended. Why: handoffs lose verification
  status (arXiv 2609.20211); prose notes lose supporting state (2608.04278); stale facts override
  evidence (2609.01852); incorrect docs hurt, missing ones do not (NAACL 2024 Findings); vocabulary
  from github.com/github/spec-kit.
- 2026-09-28: Added `docs/agent/LEARNINGS.md` with evidence field, human acceptance by commit,
  ≤ 20 active entries, promote/convert/archive rules. Why: error propagation and outcome labels
  (arXiv 2505.16067); append-only insight memory insufficient (2608.11248); instruction files grow
  +226 % without rationale (2608.11095); review-derived rules gave 0 % recurrence (2607.13091);
  corrections compiled into checks beat memory (2606.13174); memory is an injection channel (2609.13889).
- 2026-09-28: Removed the 18-line session protocol from AGENTS.md; briefing and wrap-up wording live
  in STATUS.md's header, injection is the mechanism. Why: agents make "0 memory operations in 114
  turns" unprompted (arXiv 2607.20972); compaction drops in-context rules and re-injection restores
  them (2606.22528, 2604.20911); reminders reduce drift (2510.07777).
- 2026-09-28: Extended `ops/check-agent-kit.sh` (rule count, char caps, hook JSON/paths/timeouts,
  pointer and shadowing files, verify.sh configured, stale references, STATUS/LEARNINGS shape,
  DECISIONS append-only, STATUS freshness per push). Why: only 4.4 % of security rules in 481
  CLAUDE.md files had a matching built-in control (arXiv 2608.23550); stale-reference linting after
  github.com/openintelligence-labs/agents-md-lint and github.com/ctxlint/Ctxlint.
- 2026-09-28: Gate files denied to the agent in Claude Code (`permissions.deny` on ops/verify.sh,
  the check, ops/agent/, hook configs, CI). Why: agents game test suites (arXiv 2605.21384,
  2511.21654, ICML 2026 2605.02964); deny rules are evaluated first and cannot be carved out
  (code.claude.com permissions).
- 2026-09-28: Rule 3 re-verifies before new work. Why: Anthropic's autonomous-coding quickstart makes
  it "MANDATORY BEFORE NEW WORK"; stale stored facts are trusted 0.92–1.00 of the time (2609.01852).
- 2026-09-28: Pointer superset kept; Cursor and Copilot hook files shipped; Gemini and Antigravity
  hooks designed but not shipped. Why: handler field names for those two are not verified in their
  docs; the kit ships nothing it cannot validate.
- 2026-09-28: PRD.md stays at the root and is never injected. Why: irrelevant and long context degrade
  performance (arXiv 2302.00093, 2510.05381); repository overviews are not helpful (2602.11988).
- 2026-09-28: Added `.env.example`, `ops/test-kit.sh`; corrected research/ (L7, L27), deleted the v0.3
  diagram, added the audit. Why: hygiene (practice); SC3/SC4 were unproven; two learnings were
  contradicted by verified sources.
- 2026-09-28: DECISIONS.md stays one dated-bullet file; other repositories keep their ADR folders. Why:
  no evidence either way; one file is simplest to inject and diff-check; violation detection needs
  explicit, code-inferable records in any form (arXiv 2602.07609).
- 2026-09-28: Gate state and log live in `~/.cache/agent-kit/<repo-key>/`, not in the repository.
  Why: logs never go into agent files (rule 6); the 30-day metrics need a persistent record.
- 2026-09-28: The shipped `ops/verify.sh` keeps its KIT-PLACEHOLDER block but exits 0 with a warning,
  and the check fails on the placeholder only once AGENTS.md's purpose line is filled; CI also runs
  `ops/test-kit.sh`. Why: the template repository's own CI must be green while adopters are still
  forced to configure verification before their project counts as real. Rejected: a flag or a
  marker file exempting the template (adopters would inherit it).
- 2026-09-28: The published kit is v1.0; the audited pre-publication draft is "the unreleased draft".
  The audit text in research/audit-2026-09-28.md calls the draft "v1.0" and the revised kit "v2.0";
  the labels were swapped at publication. Why: the first commit is the first release; nothing was
  published before.
- 2026-09-28: The maintainer commits and pushes; the agent stages only. The first commit lands on
  `main` (no history, no remote yet); feature branches and pull requests from the second commit on.
  Why: maintainer's rule; a review step between the agent's claim and the commit.
- 2026-09-28: LICENSE is MIT with the maintainer's public GitHub handle as the copyright holder.
  Why: a public template without a license cannot be reused; no legal name is on record on this machine.
- 2026-09-28: The repository is named `coding-agent-kit`. Why: it names who the kit is for (coding
  agents such as Claude Code, Codex, Cursor) and what it is (a kit of files, not a framework), and it
  matches the internal identifier `agent-kit` used by the check, the workflow and the hooks. Rejected:
  `ai-native-coding-template` (says nothing about the function), `agent-starter-kit` (100+ collisions,
  reads as a kit for building agents), `multi-agent-starter-kit` (multi-agent orchestration is a non-goal).
- 2026-10-06: The stop gate measures changes from a session base: the HEAD that session-start records
  (kept across compaction), else the merge-base with the upstream branch, else HEAD. Why: committing
  before stopping skipped `ops/verify.sh` (audit of 2026-10-06, probe B1). Rejected: one base file
  per session id (no id shared by every tool; parallel agents already get separate worktrees and keys).
- 2026-10-06: A gate file changed, deleted or made non-executable since the session base blocks like a
  failing verify, and "unconfigured" is read from the base. Why: probes B2–B4 ended turns with failing
  tests; the Claude deny list covers its edit tools only. Rejected: an escape variable for kit work (an
  agent can set environment through `.claude/settings.local.json`). Cost: a requested gate change blocks
  until a human commits it and starts a new session; the 3-strike breaker bounds it.
- 2026-10-06: Added `.githooks/pre-commit` (runs `ops/verify.sh`), enabled per clone with
  `git config core.hooksPath .githooks`; the check prints a TODO locally until it is set. Why: Zed,
  Gemini CLI, Antigravity and Devin have no stop hook, and a commit is the one point every tool passes.
  Rejected: checking only the staged snapshot (stash juggling is fragile); a hook framework (dependency).
- 2026-10-06: Claude deny list extended with Bash patterns (`--no-verify`, `core.hooksPath`, `rm`/`mv`/
  `chmod` on `ops/`) and `.githooks/**`. Why: cheap first line; code.claude.com permissions says a Bash
  rule "isn't a security boundary", so the gate-file check above is the real fix.
- 2026-10-06: One list of non-code paths, `ops/agent/non-code-paths.txt`, read by the gate and the check.
  Why: the gate excluded only `docs/agent/` while CI also excluded README, PRD and research, so
  README-only edits ran the full verify.
- 2026-10-06: `session-end.sh` replaces its earlier stamp instead of appending. Why: a committed stamp
  plus another unclean exit added a second one, and enough of them break the 60-line cap.
- 2026-10-06: Intent layer: one change file per T1/T2 change in `docs/agent/changes/` (Intent, Tier,
  Acceptance with a `test:` path per line, Tasks, Out of scope, Evidence; Design for T2). AGENTS.md
  rules 2 and 3 merged so the tier rule fits in 7. The gate nudges once per change set, on a claim,
  when more than 3 code files or 50 lines changed without a change file, or a touched one is still
  open; the check refuses a closed change without existing tests, ticked tasks and
  `verification: verified`. Why: passing tests prove nothing about building the wrong thing. Borrowed:
  OpenSpec change files, BMAD tiering after investigation, Spec Kit acceptance scenarios. Rejected:
  personas, multi-file feature folders, a framework CLI; spec deltas wait for living specs (phase 3).
- 2026-10-06: `AGENT_KIT_NUDGES=0` replaces `AGENT_KIT_STATUS_GATE=0` and turns off both nudges, which
  now share one block per change set. Why: two nudges, one switch; no adopters yet to migrate.
- 2026-10-06: Kit changes that touch gate files are built on a branch in a separate worktree and merged
  by the maintainer. Why: the deny rules stop the agent from editing gate files in the main checkout,
  and the new gate would block its own development there.
- 2026-10-06: This release is v2.0, tagged `v2.0.0`, with CHANGELOG.md and ROADMAP.md. Why: the
  maintainer's call; the gate semantics and the `AGENT_KIT_NUDGES` rename break compatibility.
- 2026-10-06: Untested configs (Codex, Cursor, Copilot cloud agent, Gemini CLI, Aider) moved to
  `contrib/untested/`; the check still validates them once copied to the root, and the self-test
  copies them there. Why: the maintainer uses Claude Code and Zed daily; untested configs are upkeep
  without evidence (audit 3.4). Rejected: deleting them (they are cheap to keep and to promote).
- 2026-10-06: A gate for an open-source model moved to ROADMAP.md. Why: no local model is in daily
  use, so there is no harness to wire (audit 3.5).
- 2026-10-06: Living specs in `docs/agent/specs/`, changed only through a T2 Spec delta;
  `ops/agent/changes.py` holds the change-file rules (`check`) and the merge-and-move step
  (`archive`), so the check and the archive share one definition, and it sits under `ops/agent/` so
  the agent cannot weaken it. A closed change fails the check until archived. Why: specs must stay in
  step with code in brownfield repositories (audit 3.1); a deterministic merge beats an agent
  editing specs by hand. Rejected: an OpenSpec-style CLI dependency; spec deltas for T1.
- 2026-10-06: The spec-vs-diff check (audit 3.3) prints advisory `GAP:` lines for open changes only:
  acceptance tests that do not exist yet or are unchanged since the base. Why: the plan makes it
  advisory; `ops/verify.sh` stays the hard gate.
- 2026-10-06: Bug-fix rule: a `T1 fix` change cannot be archived without a `failed first:` Evidence
  line. Why: Spec Kit's rule that missing verification is not a fix (audit 4.1); it fits inside
  rule 3, so the rule count stays 7.
- 2026-10-06: Onboarding an existing repository (`docs/agent/ONBOARD.md`) is validated on a real
  repository after the v2.0 commit is on GitHub. Why: the maintainer's sequencing.
- 2026-10-06: When the `--range` base is not a commit (GitHub's all-zero `before` on a branch's first
  push), the check prints a note and skips the range rules instead of aborting. Why: the v1.0 push to
  `main` failed CI this way (run 36441532465), and every adopter's first push would too; the
  pull-request run still applies the range rules. Rejected: changing the workflow's base expression
  (the check is what crashed, and local `--range` use hits the same case).
- 2026-10-07: Adopters update the kit with `install.sh`, built after the same copy had been done by
  hand three times and two of the copies had drifted (a self-test copied then deleted, a CI
  workflow patched locally). It sits at the repository root, outside `ops/`, so it is never among
  the files it copies. Rejected: `ops/kit-sync.sh` with a self-exclusion; the manual recipe in
  PRD §6 alone.
- 2026-10-07: Every kit file has one custody class, held as arrays at the top of `install.sh`:
  kit-owned (overwritten), adopter-owned (never written; a missing one is reported), shared
  (`.claude/settings.json`, the CI workflow, `.gitignore`, `ops/agent/non-code-paths.txt`) and
  never shipped (`ops/test-kit.sh`, `install.sh`, `contrib/`, the kit's own documents). A shared
  file is overwritten only when it still equals the kit's copy at the old version; otherwise the
  kit's copy goes beside it as `<path>.kit-new` with a diff, and the check fails until a human
  merges it. Why: adopters patch these files on purpose, and a merge done by a script is a merge
  nobody reviewed. Rejected: three-way merging; overwriting with a backup; an init mode for new
  repositories (the template already covers them).
- 2026-10-07: The installed version is stamped in `ops/agent/KIT_VERSION` (`git describe` output)
  and is the default `--from` of the next update; the check prints it and never fails on its
  absence. It sits under `ops/agent/` so the gate and the deny rules protect it. A dirty kit
  checkout is stamped `-dirty` rather than refused, so the self-test can run from a working tree;
  the suffix is dropped when the stamp is read, which can only produce extra sidecars.
- 2026-10-07: `ops/test-kit.sh` is never shipped to adopters, and the first-adoption finding that it
  cannot run there is closed by that rather than by making it portable. The self-test moves to
  `.github/workflows/kit-self-test.yml`, which only the kit runs; the shipped `agent-kit.yml`
  becomes the workflow the first adopters proved: range rules on pull requests only, not for
  Dependabot. Why: the self-test tests the kit's scripts, which adopters consume but do not
  develop. Rejected: an allowlist rewrite of `fresh_copy` (work for a test no adopter needs).
- 2026-10-07: Committed kit files name adopters by role, never by repository name, and do not point
  at the local, excluded `FEEDBACK.md`; findings are restated in ROADMAP.md. Why: this repository
  is public and the adopters are private.
- 2026-10-07: A ROADMAP finding is ready when it names where it was seen, the symptom, the evidence
  and a self-test case, written first as a `known_failure` in `ops/test-kit.sh` that must keep
  failing; the suite fails once it passes. Findings are triaged before each adopter update. Why:
  a prose bullet goes stale (four of five first-adoption findings sat untracked through 2.0), a red
  case does not, and it applies the kit's own "a fix needs a test that failed first" rule to the
  kit. Rejected: GitHub issues (this repository is public and the adopters are private); skipped
  tests (they pass silently once fixed and are never promoted).
- 2026-10-07: The rollout runs from the cheapest mistake to the most expensive: the notes vault, then
  a TypeScript application that has no kit yet, then the 2.2 fixes, then the docs-only repository
  halfway through its first implementation, then the production application of the first adoption.
  Why: the maintainer's call; each run is a test, and the two near-greenfield repositories absorb
  the first mistakes. The fixes land before the two repositories that carry real work. Replaces the
  order in the 2.1 ROADMAP draft (docs-only repository first).
- 2026-10-08: Records-only changes (every path in `ops/agent/non-code-paths.txt`) are committed and
  pushed to `main` by the agent at wrap-up, once `./ops/verify.sh` passes; anything else still goes
  through a branch and a pull request the maintainer merges. Replaces the 2026-09-28 "the agent
  stages only" for records. Why: the maintainer's call; approving a records-only pull request cost
  a click per session and bought no review, and pull requests now list what shipped. CI still runs
  on every push. Rejected: GitHub auto-merge for records pull requests (needs branch protection and
  more pull requests); a SessionEnd hook that pushes (the model is gone by then, so nothing judges
  or asks, and a push can fail silently within the hook's 3-10 s). Accepted risk: in a public
  repository, records are published without a human look; rule 6 and the CI credential check stay.
- 2026-10-08: STATUS.md's `updated:` and `at:` carry the time and zone read from the clock
  (`date '+%Y-%m-%d %H:%M %Z'`); DECISIONS, LEARNINGS, change files and CHANGELOG keep dates. Why:
  STATUS is rewritten several times a day (three committed versions on 2026-10-08, all dated
  alike); the logs are append-only, so their order shows the sequence and git keeps exact times.
  Rejected: times in every record (longer entries, no decision depends on the hour).
- 2026-10-08: An OpenSpec-style change flow (commands for explore, propose, update, apply and
  archive; a T2 change waits for the maintainer's "approved") is built before the notes-vault
  follow-up and the rest of the rollout. Why: the maintainer's call; adopters then receive the flow
  with their next update instead of in a second one.
- 2026-10-08: A records-only change goes through a pull request titled "Records: …" that the agent
  merges once CI passes, not a push to `main`. Replaces the direct push decided earlier the same
  day. Why: the maintainer's hook blocks every push to `main`, and CI's range rules (DECISIONS
  append-only, STATUS freshness) run on pull requests only, so a pull request guards records
  better; the maintainer still clicks nothing. Rejected: relaxing the hook (a global guardrail
  loosened for one kit, and direct pushes skip the range rules); the maintainer pushing records
  (a step per session).
- 2026-10-09: Skill add-ons are planned and built before the OpenSpec-style flow, whose commands
  then ship as `kit-` skills in the same folder. Replaces the order of 2026-10-08. Why: the
  maintainer's call; the skills folder, its check and install.sh custody are built once.
- 2026-10-09: Of five candidate skill sets, two skills are planned in
  `docs/agent/changes/add-skills.md`: `kit-explore` (Pocock's grill-me and grilling merged into one
  skill that runs only when the user types it) and `kit-debug` (Superpowers' systematic-debugging).
  Why: licences, pins and files verified in `research/skills-addons-proposal.md`. Rejected: the
  LSP plugins (they install without LSP configuration, claude-plugins-official #379; Claude Code
  only; language servers to install); the ast-grep skills (no LICENSE file, a name that differs
  from its folder, a binary); Ponytail (its author refuses a condensed version, and the sentence
  measured in its issue #685 is already rule 3).
- 2026-10-09: No "smallest complete change" clause in rule 3, and no A/B measurement before
  building. Why: the maintainer's call; no one-line version has been measured, and 5-10 task pairs
  cannot show the effects measured elsewhere (JetBrains needed 80 pairs for −10.3 % cost).
- 2026-10-09: Kit skills are named `kit-` plus a step of the change flow (`kit-explore`; later
  `kit-propose`, `kit-apply`, `kit-archive`), and `kit-debug`. Why: Claude Code lets a project
  skill replace a built-in command of the same name, and `/plan`, `/design`, `/review`, `/verify`
  and `/debug` are built-ins; the prefix also marks the folders install.sh owns. Rejected: bare
  verbs, classic product-stage names, the upstream names.
- 2026-10-09: A session-start briefing (Last session, Next, Needs you; 3-5 one-line bullets, each
  with a path or URL, copied from STATUS.md) is planned as its own T2 change after the skills, in
  `docs/agent/changes/session-briefing.md`. Until it ships, STATUS.md's header asks for the
  briefing in the first reply of every session. Why: the maintainer's call. Rejected: a briefing
  the model writes at session start (tokens every session; it can drift from the file); Claude
  Code's `initialUserMessage` (only in `claude -p`).
