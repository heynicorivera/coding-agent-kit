# PRD: Agent starter kit v2.0

Version 2.0, 2026-10-06: closes the gate bypasses and adds the intent layer from the audit of
2026-10-06 (see `CHANGELOG.md`). Version 1.0, 2026-09-28, superseded the unreleased draft of 2026-09-28 (the audit in
`research/audit-2026-09-28.md` calls that draft "v1.0" and this kit "v2.0"; the labels were swapped
at publication). Evidence: `research/sources.md` (S-IDs) and the audit. Sources below are given as
arXiv IDs, vendor documentation pages and repositories; every one was re-opened on 2026-09-28.
Anything resting on a gap is labelled as a kit choice, not a fact.

## 1. Problem

A solo developer working across several coding agents has no reviewer between the agent's claim and
the commit. Four things break, all measured:

| Break | Evidence |
|---|---|
| **Sessions start empty and stay that way.** Agents do not read or write memory files on their own: "voluntary memory use is near zero even with a pre-seeded store (0 memory operations in 114 turns)". Context compaction silently drops in-context rules: violations rise "from 0% with the policy in full context to 30% after compaction, reaching 59% for some models". Prohibitions decay within a session (omission compliance "73% at turn 5 to 33% at turn 16"). | arXiv 2607.20972; 2606.22528; 2604.20911 |
| **"I verified it" is not verification.** Without external feedback, self-correction does not help and "at times, their performance even degrades" (ICLR 2024); "self-correction works well in tasks that can use reliable external feedback" (TACL 2024). The producing model silently endorsed 31.7 % of its own behaviour-changing edits. Execution feedback does work (+12 % with unit tests). Tests as the only gate get gamed, including by Codex and Claude Code. | 2310.01798; 2406.01297; 2605.21537; 2304.05128; 2605.21384; 2511.21654; 2605.02964 (ICML 2026) |
| **Agent-written memory drifts and misleads.** Stale stored facts are answered "0.92-1.00 of the time"; prose notes keep conclusions "without the program state that supported it"; handoffs keep the claim and lose "the fact that the claim was never verified"; "append-only memory is insufficient"; instruction files grow "+226%" over their lifetime; LLM-written context files trail developer-written ones by 7 %. Incorrect documentation "can greatly hinder code understanding, while incomplete or missing documentation does not". | 2609.01852; 2608.04278; 2609.20211; 2608.11248; 2608.11095; 2602.11988; NAACL 2024 Findings (Macke & Doyle) |
| **Too many always-on instructions.** All-instructions-satisfied accuracy is 0.574 at five instructions and 0.213 at ten (EMNLP 2025 Findings); "reliable instruction following breaks down beyond 5-6 simultaneous constraints". The unreleased draft carried 26–28. File size and position, by contrast, showed no measurable compliance effect; they cost tokens (+20 %). | 2509.21051; 2608.12426; 2605.10039; 2602.11988 |
| **Nine tools, nine mechanisms.** Prose rules had a matching built-in control in 4.4 % of cases across 481 CLAUDE.md files. Each tool reads different files and exposes different hooks. | 2608.23550; §2 |

The kit is configuration, not a harness: it can only enforce through the hooks, permission rules and
CI each harness supports. Where a harness supports none, this document says so.

## 2. Users and tools in scope

| User | Need |
|---|---|
| Solo developer using several agents (daily: Zed, Claude Code; occasionally: Codex, Copilot, Aider) | One instruction file; a correct briefing at session start; a machine gate before "done"; memory that is more correct at the end of a session than at the start |
| Any coding agent below | Instructions, state and learnings in a predictable place, loaded only as far as the task needs |
| A future collaborator | Understand the structure in five minutes from `README.md` |

**Compatibility contract** (from vendor documentation, 2026-09-28). Since 2.0 the kit files for Codex,
Cursor, Copilot cloud agent, Gemini CLI and Aider ship in `contrib/untested/` and take effect only
when copied to the repository root; Claude Code and Copilot CLI use `.claude/settings.json`:

| Tool | Reads AGENTS.md | Kit file | Session-start injection | Pre-finish hook | Source |
|---|---|---|---|---|---|
| Claude Code | via `CLAUDE.md` import ("never makes Claude read AGENTS.md twice"); natively only when no CLAUDE.md/CLAUDE.local.md exists | `CLAUDE.md`, `.claude/settings.json` | `SessionStart` (startup, resume, clear, compact) | `Stop`: "Prevents Claude from stopping" on exit 2 | code.claude.com/docs/en/memory, /hooks, /permissions |
| OpenAI Codex | natively; "at most one file per directory"; 32 KiB cap | `.codex/hooks.json` | `SessionStart` (incl. compact) | `Stop`: JSON `decision: block` or exit 2 | learn.chatgpt.com/docs/agent-configuration/agents-md, /docs/hooks |
| GitHub Copilot (CLI, cloud agent, code review, VS Code) | natively; CLI "does not define a general precedence order" | `.claude/settings.json` (cross-read by the CLI), `.github/hooks/agent-kit.json` | `sessionStart` | `agentStop` / VS Code `Stop` | docs.github.com hooks-reference, custom-instructions-support, CLI instructions; code.visualstudio.com hooks |
| Cursor | natively, root and subdirectories | `.cursor/hooks.json` | `sessionStart` → `additional_context` | `stop` → `followup_message` | cursor.com/docs/rules, /docs/hooks |
| Gemini CLI | via `.gemini/settings.json` `context.fileName` | `.gemini/settings.json` | none shipped (hook config shape unverified) | `AfterAgent` exists; not shipped | geminicli.com gemini-md, configuration, hooks |
| Antigravity CLI | natively | none | `PreInvocation` exists; not shipped | `Stop` exists; not shipped | antigravity.google/docs/hooks |
| Aider | via `.aider.conf.yml` `read:` | `.aider.conf.yml` | `read:`/`file:` every session | none; `auto-test` after each edit | aider.chat aider_conf, lint-test |
| Devin Desktop | natively; root file "included in Cascade's system prompt on every message"; 12,000-char cap | none | none | none (`post_cascade_response` is asynchronous) | docs.devin.ai agents-md, memories, hooks |
| Zed | natively, first match of a fixed list | none | none | none | zed.dev/docs/ai/instructions |

## 3. Goals and non-goals

**Goals.** Across the nine tools, an agent (1) starts every session knowing where the project stands,
(2) verifies its own work — tests, kit checks, diff against the task — before presenting anything,
(3) leaves the project's memory (status, decisions, learnings) more correct at the end of a session
than at the start. "Verified" and "learned" mean enforced by a hook, check script or CI where the
tool allows it; prose is the fallback, not the mechanism.

**Non-goals, and why.**
- A repository index or map. It has the strongest efficacy evidence of anything reviewed (structural
  indexes: arXiv 2605.16352, 2601.10112), but it is language- and tool-specific; a language-agnostic
  kit cannot ship one honestly. Projects add one when they need it.
- A specs/plans tree. Plans help when good and reminded and "a subpar plan hurts performance even
  more than no plan at all" (2604.12147); plan files appear in 10 of 36,710 repositories (2608.04661).
- Per-tool skills, rules directories, subagents: no shared format; skills are mostly static text.
- Automatic memory capture or LLM-written summaries as memory (see §1, third row).
- LLM-judged checks. Every check in the kit is deterministic.
- Hooks for Gemini CLI and Antigravity CLI: their hook handler field names are not documented in
  the pages opened; the kit ships nothing it cannot validate.
- Merge rules for two writers of STATUS.md at once: single writer assumed.
- Making the agent correct. Context files do not raise task success (2602.11988, 2607.27250); the
  kit makes work verifiable and memory current, not the model smarter.

## 4. Requirements

Each requirement names the file(s) that implement it, the check that enforces it, and its source.
Check names refer to functions in `ops/check-agent-kit.sh`; "test-kit" refers to `ops/test-kit.sh`.

| ID | Requirement | Files | Enforced by | Source |
|---|---|---|---|---|
| R1 | One canonical `AGENTS.md`: ≤ 100 lines, ≤ 12,000 characters, **≤ 7 numbered rules under `## Rules`**, no `@path` includes; `AGENTS.md` + `CLAUDE.md` ≤ 32 KiB | `AGENTS.md` | `check_agents_md` (script, CI) | 2509.21051; 2608.12426; Devin 12,000-char cap; Codex 32 KiB; 2605.10039 (line cap is a cost choice) |
| R2 | Pointer files (since 2.0 the Gemini CLI and Aider pointers ship in `contrib/untested/` and are checked once copied to the root): `CLAUDE.md` contains the line `@AGENTS.md`; `.gemini/settings.json` lists `"AGENTS.md"` in `context.fileName`; `.aider.conf.yml` has `read:` with `AGENTS.md`, `file:` with `docs/agent/STATUS.md`, `test-cmd: ./ops/verify.sh`, `auto-test: true` | those files | `check_pointer_files` | code.claude.com memory; geminicli.com gemini-md, configuration; aider.chat aider_conf, lint-test |
| R3 | No shadowing or duplicating files: `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.github/copilot-instructions.md`, `AGENT.md`, `GEMINI.md` are absent | — | `check_pointer_files` | zed.dev/docs/ai/instructions ("first matching file in this list") |
| R4 | Session-start injection of `docs/agent/STATUS.md` plus the Active section of `docs/agent/LEARNINGS.md` (≤ 40 lines), total under 10,000 characters: Claude Code `SessionStart` on `startup|resume|clear|compact`; Codex `SessionStart` (all sources); Cursor `sessionStart` as JSON `additional_context`. Tools without a shipped hook rely on rule 2 | `ops/agent/session-start.sh`, `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json` | `check_hooks` (valid JSON, executable paths, no `CLAUDE_PROJECT_DIR`); test-kit | 2607.20972; 2606.22528; code.claude.com hooks (10,000-char cap); learn.chatgpt.com hooks; cursor.com hooks |
| R5 | `STATUS.md` shape: ≤ 60 lines; lines `updated: <date> · commit: <sha|uncommitted>` and `verification: none|verified|partial|failed — command … — at …`; sections Now, Last session, Next, Open questions, Blockers; rewritten, never appended; briefing and wrap-up wording live in its header comment | `docs/agent/STATUS.md` | `check_memory_files` | 2609.20211; 2608.04278; 2609.01852; spec-kit status vocabulary; NAACL 2024 Findings |
| **R-verify** (R6) | (a) `ops/verify.sh` is the one verification command (tests + lint + kit check), executable. It ships with a `KIT-PLACEHOLDER` block that warns and exits 0; the check fails on that block as soon as `AGENTS.md` no longer carries its purpose placeholder, so a real project cannot stay unconfigured while the unfilled template stays green. (b) A pre-finish gate runs when paths outside `ops/agent/non-code-paths.txt` changed since the session base (the HEAD recorded at session start and kept across compaction; else the merge-base with the upstream branch; else HEAD), so commits made during the session count: it runs `ops/verify.sh` once per change set (digest cache), blocks the turn on failure with the last 40 lines and the instruction not to weaken tests or edit the gate, lets the turn end after 3 consecutive blocks with a warning, skips when `verify.sh` was unconfigured at the base (never judged from the working tree), and fails open on internal error. A gate file (`ops/verify.sh`, `ops/check-agent-kit.sh`, `ops/agent/`, `.githooks/`, hook configs, `.github/workflows/`) changed, deleted or made non-executable since the base blocks like a failure. Per tool: Claude Code and Copilot CLI `Stop` via `.claude/settings.json` (exit 2 + stderr); Codex `Stop` (`{"decision":"block","reason"}`); Copilot cloud agent `agentStop` via `.github/hooks/agent-kit.json`; Cursor `stop` (`followup_message`, `loop_limit` 3). Aider: `auto-test: true` runs `verify.sh` after each edit. Gemini CLI, Antigravity, Devin, Zed: **no pre-finish hook shipped**; rule 1 (quote the last lines of `verify.sh`) and CI are the only enforcement, and the kit loses the pre-presentation guarantee there. (c) Gate files cannot be edited by the agent in Claude Code: `permissions.deny` on `ops/verify.sh`, `ops/check-agent-kit.sh`, `ops/agent/**`, `.githooks/**`, hook configs, `.github/workflows/**`, plus best-effort Bash patterns (`--no-verify`, `core.hooksPath`, `rm`/`mv`/`chmod` on `ops/`). (d) The gate appends one line `time · consumer · outcome` to `~/.cache/agent-kit/<repo-key>/gate.log`; state and log live there, not in the repository. (e) `.githooks/pre-commit` runs `ops/verify.sh` before every commit, for every tool, once `core.hooksPath` is set; the check prints a `TODO:` locally until it is | `ops/verify.sh`, `ops/agent/stop_gate.py`, `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`, `.github/hooks/agent-kit.json`, `.aider.conf.yml` | `check_verify_script`, `check_hooks`; test-kit; CI runs `verify.sh` | 2310.01798; 2406.01297; 2605.21537; 2304.05128; 2509.24148; 2602.19594; 2607.03691; 2605.21384; 2511.21654; 2605.02964; code.claude.com hooks, permissions; learn.chatgpt.com hooks; docs.github.com hooks-reference; cursor.com hooks; aider.chat lint-test; github.com/elijahmanlockedin112/verify-gate-hook; github.com/LZong-tw/clawback; github.com/leavemagic-cyber/epitype |
| R7 | STATUS freshness: (a) at the gate, when code changed and the agent's last message claims completion (Claude, Codex payloads carry `last_assistant_message`; Cursor and Copilot gate on dirty tree alone) and `STATUS.md` is older than the changed files, the turn is blocked once per change set with the instruction to rewrite STATUS.md; (b) in CI, a push or PR range that changes files outside the paths in `ops/agent/non-code-paths.txt` (`docs/agent/`, `README.md`, `PRD.md`, `research/`; the gate reads the same list) must also change `docs/agent/STATUS.md`, unless every commit subject starts with `wip:`; (c) `SessionEnd` in Claude Code and Codex stamps STATUS.md when the tree is dirty and STATUS.md untouched, replacing any earlier stamp (detection only; Codex timeout 3 s) | `ops/agent/stop_gate.py`, `ops/check-agent-kit.sh`, `ops/agent/session-end.sh`, `.github/workflows/agent-kit.yml` | `check_status_freshness` (CI); gate; test-kit | 2609.20211; github.com/sara-star-quant/presence; anthropics/claude-quickstarts `autonomous-coding` ("MANDATORY BEFORE NEW WORK"); learn.chatgpt.com hooks (3 s) |
| R8 | `DECISIONS.md` is append-only: dated bullets with the reason and rejected alternatives; no line may disappear relative to HEAD (local) or the push base (CI) | `docs/agent/DECISIONS.md` | `check_decisions_append_only` | 2608.23550; 2606.13174; 2602.07609 |
| **R-learn** (R9) | What is rewritten at session end: `STATUS.md` (rewritten), `DECISIONS.md` (appended), `LEARNINGS.md` (Active list curated). Who curates: the agent proposes entries in the wrap-up; a human accepts by committing; nothing enters otherwise. Format: `<date> · <lesson> · evidence: <commit/test/PR> · why: <clause>`; sections Active (≤ 20 entries), Converted to checks, Archived; whole file ≤ 100 lines. Promotion: a lesson that recurs twice becomes a check or one of the 7 rules and moves to Converted; wrong or obsolete entries move to Archived, never deleted silently. Injection: Active entries only, after STATUS.md, at session start. The check that fails when it is skipped: `check_memory_files` (evidence field, caps) locally and in CI; `check_status_freshness` fails a push that changed code without rewriting STATUS.md | `docs/agent/LEARNINGS.md`, `ops/agent/session-start.sh` | `check_memory_files`, `check_status_freshness` | 2505.16067 (outcomes as labels); 2608.11248 (append-only insufficient); 2608.11095 (rationale enables pruning); 2607.13091 (review-derived rules, 0 % recurrence); 2606.13174 (corrections → checks); 2609.13889 and 2606.04329 (memory is an injection channel → human acceptance); github.com/roampal-ai/roampal-core (promote/demote) |
| R10 | Never-store rule (rule 6) plus a credential tripwire over agent files (AWS, GitHub, OpenAI-style, Slack tokens, private keys) | `AGENTS.md`, `ops/check-agent-kit.sh` | `check_credentials` | 2604.20911 (prohibitions decay → must be a check); 2609.13889 |
| R11 | Stale references: every backticked path in `AGENTS.md`, `STATUS.md`, `LEARNINGS.md` that contains a `/` must exist (placeholders in `<>` and globs exempt) | those files | `check_stale_references` | NAACL 2024 Findings; github.com/openintelligence-labs/agents-md-lint; github.com/ctxlint/Ctxlint |
| R12 | Re-verify before new work: rule 2 runs `ops/verify.sh` first; the gate re-runs it on any change since the session base (prose for an unchanged tree) | `AGENTS.md` | rule 2 (prose) + gate | anthropics/claude-quickstarts; 2609.01852 |
| R13 | CI runs `ops/check-agent-kit.sh --range <base>..HEAD`, `ops/test-kit.sh` and `ops/verify.sh` on push and PR; checkout pinned to a commit SHA, `persist-credentials: false`, `fetch-depth: 0`, read-only token; Dependabot keeps the action current | `.github/workflows/agent-kit.yml`, `.github/dependabot.yml` | CI | GitHub Actions security docs (S40–S42 in sources.md) |
| R14 | Kit self-test: `ops/test-kit.sh` builds temporary repositories and asserts that each rule above fails when broken and passes when honoured, that `session-end.sh` stamps only a dirty tree with untouched STATUS.md and never twice, that the gate answers each consumer in the documented shape, that committing before stopping and changing, deleting or `chmod -x`-ing gate files still block, that the pre-commit hook refuses a failing commit, that change files are checked and nudged, that `ops/agent/changes.py archive` refuses an incomplete change and merges Spec deltas, and that the `contrib/untested/` configs pass the check once copied to the root | `ops/test-kit.sh` | itself; run in step 7 of setup and in CI | audit Phase 1 (the draft's SC3/SC4 were unproven) |
| R15 | `PRD.md` and `research/` are never loaded by any tool and are deletable; `.env.example` lists every variable with a safe placeholder; `.env` is gitignored | `PRD.md`, `research/`, `.env.example`, `.gitignore` | by construction; `.gitignore` | 2302.00093; 2510.05381; 2602.11988 (overviews unhelpful) |
| R16 | Hook portability: every hook command resolves the repository with `$(git rev-parse --show-toplevel)`; Codex `SessionEnd` timeout ≤ 3 s; hook files stay valid JSON; every referenced `ops/…` path exists and is executable; `python3` is present | hook configs | `check_hooks`, `check_python` | docs.github.com hooks-reference (cross-tool read of `.claude/settings.json`); learn.chatgpt.com hooks; code.claude.com hooks ("mistyped path … silently disabled") |
| R18 | Intent before code: AGENTS.md rule 3 classifies each change after reading the code (T0 trivial: verify only; T1 feature or fix: a change file before code, and a fix needs a test that failed before it; T2 schema, auth, payments, cross-module: T1 plus Design and Spec delta sections; unsure: higher tier). A change file in `docs/agent/changes/` (from `_template.md`) has `status: open|closed` and the sections Intent, Tier, Acceptance (Given/When/Then, each naming a `test:` path), Tasks, Out of scope, Evidence. The check fails a missing section or status, an acceptance line without a test, a T2 change without Design and Spec delta, and a closed change whose test file is missing, whose tasks are unticked, whose Evidence lacks `verification: verified`, or, for `T1 fix`, lacks `failed first:`; a closed change left in `docs/agent/changes/` fails until it is archived. The gate nudges once per change set, on a completion claim, when more than 3 code files or 50 lines changed and no change file was touched, or when a touched change file is still open | `AGENTS.md`, `docs/agent/changes/_template.md`, `ops/agent/changes.py`, `ops/agent/stop_gate.py`, `ops/check-agent-kit.sh` | `check_change_files` (runs `ops/agent/changes.py check`); gate; test-kit | OpenSpec (change proposals); BMAD (tier after investigation); Spec Kit (acceptance scenarios; no fix without a test that failed first) |
| R19 | Living specs and brownfield: `docs/agent/specs/<domain>.md` holds one requirement per line with an ID like `AUTH-1`, unique per file, written only for the area about to change. `ops/agent/changes.py archive <change>` refuses a change that is not closed or fails R18, merges its Spec delta (ADDED: new ID appended; MODIFIED: replaces the line with that ID; REMOVED: deletes it; nothing written on conflict) and moves the file to `docs/agent/changes/archive/<date>-<name>.md`. The check prints advisory `GAP:` lines for open changes whose acceptance tests do not exist or are unchanged since the push base or upstream merge-base. `docs/agent/ONBOARD.md` fills AGENTS.md from repository evidence, proposes `ops/verify.sh` for the human and writes specs only for the first area to change | `docs/agent/specs/_template.md`, `ops/agent/changes.py`, `docs/agent/ONBOARD.md` | `check_change_files`; test-kit | OpenSpec (delta specs, archive step); audit items 3.1–3.3 |
| R17 | The check reports remaining placeholders (`TODO:` lines for `<…>` in AGENTS.md and the verify.sh block) without failing, so an adopter sees what is left | `ops/check-agent-kit.sh` | `report_todos` | usability (kit choice) |

## 5. Acceptance criteria

The kit is correct when all of the following hold on a fresh copy after step 7 of the README:

1. `./ops/check-agent-kit.sh` prints `OK` (with `TODO:` lines while placeholders remain) and prints
   `FAIL` for each of: AGENTS.md > 100 lines; > 7 rules; `@path` include; `CLAUDE.md` without
   `@AGENTS.md`; `.gemini/settings.json` without `"AGENTS.md"`; `.aider.conf.yml` without `read:`
   AGENTS.md; any shadowing file present; invalid hook JSON; a hook path that does not exist;
   `CLAUDE_PROJECT_DIR` in a hook; Codex SessionEnd timeout > 3; `KIT-PLACEHOLDER` still in
   `verify.sh` once AGENTS.md is filled; a backticked path that does not exist; STATUS.md > 60 lines
   or without `verification:`; LEARNINGS.md > 100 lines or an active entry without `evidence:`; a
   credential pattern; a removed DECISIONS.md line (with `--range`); code changed without STATUS.md
   in the range (with `--range`, non-`wip:`); `ops/agent/non-code-paths.txt` missing; a
   non-executable `.githooks/pre-commit`; a change file that breaks R18.
2. `./ops/test-kit.sh` passes all cases in R14, including: gate exit 2 with the failure tail for
   `--consumer claude`, JSON `decision: block` for `codex` and `copilot`, `followup_message` for
   `cursor`, exit 0 on a clean tree, exit 0 with a warning after three failures, exit 0 when
   `verify.sh` was unconfigured at the base, a nudge once per change set, and a block for each
   bypass: commit then stop, placeholder added to `verify.sh`, `chmod -x`, delete or rename,
   `--no-verify` commit.
3. CI on GitHub runs the three steps and is green on the template itself; zizmor and actionlint
   report no findings.
4. Per-tool pickup, recorded in `README.md` as tested or not tested: Claude Code `/hooks` lists the
   three hooks and a session start shows the injected STATUS.md; Codex lists and trusts the hooks;
   Cursor shows the hooks under Customize; Copilot CLI `/instructions` lists AGENTS.md; Gemini CLI
   `/memory show` contains AGENTS.md. Tools not installed locally are marked "not tested locally".
5. `wc -l AGENTS.md` ≤ 100 and the rule count is 7 on the template.

## 6. Migration

**v1.0 → v2.x** — run `./install.sh --from v1.0.0 <repo>` (README, "Updating the kit"); it does
steps 1 and 2 and prints the rest.

1. Replace `ops/agent/`, `ops/check-agent-kit.sh` and `.claude/settings.json`; add
   `.githooks/pre-commit` and run `git config core.hooksPath .githooks`. Do not copy
   `ops/test-kit.sh`: it tests the kit; in an adopter it copies the whole tree, ignored data
   included, about thirty times, and stops at its first case once AGENTS.md is filled.
2. Add `docs/agent/changes/_template.md`, `docs/agent/specs/_template.md` and `docs/agent/ONBOARD.md`.
3. In AGENTS.md, merge rules 2 and 3 and add the tier rule as rule 3 (see the template).
4. Rename `AGENT_KIT_STATUS_GATE` to `AGENT_KIT_NUDGES` wherever it is set.
5. Move tool configs you have not tested to `contrib/untested/`, or keep them at the root.
6. Commit, then start a new agent session: the gate measures from the session's first commit.

**The unreleased draft → v1.0**

1. Delete `GEMINI.md`; add `.gemini/settings.json`.
2. Replace `AGENTS.md` with the v1.0 template; move project-specific lines from the old Conventions,
   Boundaries and Git sections into rules 5–7 or `## Conventions`; keep 7 rules.
3. Add `ops/verify.sh` and replace the placeholder with the project's test and lint commands.
4. Replace `.claude/settings.json` and `.codex/hooks.json`; add `.cursor/hooks.json`,
   `.github/hooks/agent-kit.json`, `ops/agent/stop_gate.py`; replace `ops/agent/session-start.sh`.
5. Convert `docs/agent/STATUS.md` to the v1.0 shape (add `updated`, `verification`; move briefing
   and wrap-up wording into the header comment); add `docs/agent/LEARNINGS.md`; add `.env.example`.
6. Replace `ops/check-agent-kit.sh` and `.github/workflows/agent-kit.yml`; add `ops/test-kit.sh`.
7. Append the v1.0 decision entries to `docs/agent/DECISIONS.md` (never rewrite old ones).
8. Run `./ops/check-agent-kit.sh`, then `./ops/test-kit.sh`, then trust the hooks in each tool.
9. Commit. Other repositories (for example one using an ADR folder) keep their decision format;
   only the append-only rule is required.

## 7. Open questions and unproven parts

| # | Question | Status |
|---|---|---|
| OQ1 | Gemini CLI and Antigravity hook handler field names; `AfterAgent` retry semantics | Not verified in the pages opened; hooks designed, not shipped |
| OQ2 | How Copilot CLI treats a Claude-format `Stop` hook that exits 2, and plain stdout from `SessionStart` | Cross-read is documented; output handling is not; test with `/hooks` |
| OQ3 | Codex `apply_patch` PreToolUse input schema, needed to protect gate files under Codex | Not verified; edits are denied in Claude Code only, but every tool with a stop hook blocks the turn when gate files changed |
| OQ4 | Whether blocking on completion claims at the gate is tolerable day to day | Design choice (`AGENT_KIT_NUDGES=0` disables the STATUS.md and change-file nudges); the 30-day metrics decide |
| OQ5 | The exact numbers: 7 rules, 100 lines, 60-line STATUS, 20 learnings, 3 strikes | Direction is evidenced; numbers are choices |
| OQ6 | Whether an instruction-only wrap-up is ever followed reliably | Unmeasured; the kit no longer depends on it |
| OQ7 | Devin Desktop and Zed: no enforcement of goals 2 and 3 before presenting | Vendor limitation; the pre-commit hook enforces goal 2 at commit time; stated in README |
| OQ8 | Whether a status file improves outcomes at all | No study exists; the nearest evidence says verified experience helps 1.1–4.5 pp and self-built memory mostly does not (2609.23570) |
| OQ9 | Two people or two tools editing STATUS.md at once | Single writer assumed |

## 8. Success metrics (30 days from adoption; all observable from git, CI and the gate log)

| # | Metric | Target | How measured |
|---|---|---|---|
| M1 | Pushes rejected by `check_status_freshness` | ≥ 1 in week 1 (the check bites), 0 in week 4 (the habit holds) | GitHub Actions history |
| M2 | Share of commits whose STATUS.md `verification:` line is `verified` with a commit that exists | 100 % of non-`wip:` commits | `git log -p -- docs/agent/STATUS.md` |
| M3 | Gate blocks that were followed by a passing `verify.sh` in the same session | ≥ 5 in 30 days; 0 sessions ended by the 3-strike breaker | `~/.cache/agent-kit/<key>/gate.log` |
| M4 | Sessions that started with a "Session ended without wrap-up" stamp present | ≤ 2 in 30 days | `git log -S "Session ended without wrap-up" -- docs/agent/STATUS.md` |
| M5 | Reverts or amends of agent-authored commits within 24 h | Lower than the 30 days before adoption | `git log --grep=Revert`, reflog |
| M6 | LEARNINGS.md: entries converted to a check | ≥ 1; Active ≤ 20; every entry has evidence | file + `check_memory_files` |
| M7 | AGENTS.md rule count and length | ≤ 7 and ≤ 100 every commit | `git log -p -- AGENTS.md` |
| M8 | Briefing test on five random session starts across at least two tools | 5/5 answers cite STATUS.md content | manual tally recorded in STATUS.md "Open questions" |
