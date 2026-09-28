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
