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
