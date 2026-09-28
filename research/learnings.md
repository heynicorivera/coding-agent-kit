# Learnings

Derived only from `research/sources.md`. Retrieval date 2026-09-27.

Rules used: a learning is **well supported** when at least two sources from different organisations
back it. A vendor's documentation is authoritative for that vendor's own behaviour but still counts
as one source, so vendor-specific behaviours sit in the second table tagged "vendor-authoritative".
S36 repeats S31's numbers and does not count as independent of it. Nothing in the gaps table has been
filled with assumptions.

## Well supported (≥ 2 independent organisations)

| ID | Learning | Sources |
|---|---|---|
| L1 | `AGENTS.md` at the repository root is an open format read natively by Codex, Cursor, Copilot (cloud agent, code review, CLI), VS Code, Devin Desktop (formerly Windsurf), Antigravity CLI, Zed, and Claude Code (conditionally, see L18). No other instruction file has cross-vendor support. | S1, S2, S3, S7, S10, S11, S12, S16, S17, S23, S24, S38 |
| L2 | Every tool resolves instruction files hierarchically: files are concatenated from the root down and the file nearest the edited code wins on conflict; explicit user prompts override files. | S1, S3, S7, S10, S13, S18, S24 |
| L3 | Tools that do not read `AGENTS.md` by default can be pointed at it with one checked-in line: Claude Code `@AGENTS.md` in `CLAUDE.md`; Gemini CLI `context.fileName` in `.gemini/settings.json` or `@AGENTS.md` in `GEMINI.md`; Aider `read: [AGENTS.md]` in `.aider.conf.yml`. | S7, S18, S20, S26, S27 |
| L4 | Instruction files must be short. Published caps: Claude Code target under 200 lines; Cursor under 500 lines; Copilot about 1,000 lines; Devin 12,000 characters per rule file; Codex 32 KiB combined. Practitioners converge on 150 lines or fewer. A shared file must satisfy the smallest cap among the tools in use. | S3, S7, S10, S14, S16, S25, S33, S35, S36 |
| L5 | Content that earns its place: commands an agent cannot guess, non-standard conventions, gotchas, boundaries, repository etiquette. Content to leave out: anything derivable from the code, standard language conventions, repository overviews, style rules a linter can enforce, facts that change often. | S4, S8, S10, S31, S33, S35, S36 |
| L6 | Instruction files are advisory and adherence is non-deterministic. Rules that must always hold need deterministic enforcement: hooks, linters, type checkers, tests, CI. | S4, S8, S15, S33 |
| L7 | Duplicated or contradictory instructions across files degrade adherence. Vendors and practitioners say to keep one source of truth: shared instructions in `AGENTS.md`, tool-specific files only for features unique to that tool. This is the evidence for the hypothesis under test. **Correction 2026-09-28:** adjacent-file contradictions showed no detectable compliance effect in a 1,650-session factorial study (affirmative null, BF10 0.05–0.10; S45). The case for one source of truth is maintenance and growth (+226 % lifetime growth, S49), not adherence. | S7, S8, S15, S35, S36; S45, S49 |
| L8 | Vendor memory features (Claude Code auto memory, Codex memories, Devin memories) are machine-local and non-portable, and Codex memories are off by default. All three vendors say durable team knowledge belongs in checked-in files such as `AGENTS.md`. | S6, S7, S25 |
| L9 | Cross-session continuity comes from a checked-in progress or state file plus git history: read at session start, updated at session end, holding the goal, approach, steps done, current blocker and next steps. Writing a spec or plan to a file and starting a fresh session is the same pattern. | S8, S28, S29, S34 |
| L10 | Load context just in time: keep the always-loaded file minimal and point to files loaded on demand (path-scoped rules, sub-directory files, skills, `file:line` pointers instead of copies). | S7, S8, S10, S18, S24, S28, S33 |
| L11 | Claude Code, Codex and Gemini CLI provide session lifecycle hooks: SessionStart can inject context, Stop or SessionEnd can run scripts. Hook configuration is tool-specific (`.claude/settings.json`, `.codex/hooks.json`, `.gemini/settings.json`). | S5, S9, S20, S21 |
| L12 | Persistent context files and committed hooks are a security surface. They are reloaded every session, so an injection or leaked secret persists; Codex and Gemini require trust review before project hooks run. | S5, S21, S30 |
| L13 | Context files raise inference cost and do not by themselves improve task success; explicit instructions are followed, overviews are not useful, hand-written beats auto-generated. Add a rule only after observing a repeated mistake, and cut any line whose removal would not cause mistakes. | S8, S10, S31 |
| L14 | Instruction files are maintained like code: update them in the same change as the build, test or structure change they describe; prune regularly; check whether behaviour actually shifts. | S8, S10, S35 |
| L15 | Path-scoped rules exist in every major tool but share no format: `.claude/rules/*.md` with `paths`, `.cursor/rules/*.mdc` with `globs`, `.github/instructions/*.instructions.md` with `applyTo`, `.devin/rules/*.md` with glob mode. Nested `AGENTS.md` is the only cross-tool option and is off by default in VS Code. | S1, S7, S10, S11, S16, S24 |
| L16 | Only Claude Code, Gemini CLI and Copilot CLI document an `@path` include syntax inside instruction files; no other opened vendor page describes one, and Copilot CLI does not expand it inside `GEMINI.md`. Portable files should therefore say "read `<path>`" in words rather than rely on `@` includes. | S7, S12, S18 |

## Single source or unverified

| ID | Learning | Source | Status |
|---|---|---|---|
| L17 | Zed reads only the first matching project instruction file from an ordered list in which `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`, `.github/copilot-instructions.md` and `AGENT.md` precede `AGENTS.md`. Shipping any of those next to `AGENTS.md` shadows it in Zed. A personal file lives at `~/.config/zed/AGENTS.md` and project files override it. External agents inside Zed (Claude, Codex, Gemini, Copilot, Cursor) read their own native files. The page does not state where in the project the file must live. | S38, S39 | vendor-authoritative |
| L18 | Claude Code reads `AGENTS.md` directly only when no `CLAUDE.md` or `CLAUDE.local.md` exists in the working directory or above (v2.1.277+). With a `CLAUDE.md` present, it must contain `@AGENTS.md`; a sentence telling Claude to read the file is not sufficient. The import never loads the file twice. Symlinking is documented but has Windows and edit-tool caveats. | S7 | vendor-authoritative |
| L19 | Codex uses at most one file per directory, `AGENTS.override.md` beats `AGENTS.md`, combined size is capped at 32 KiB by default, and extra file names need `project_doc_fallback_filenames`. | S3 | vendor-authoritative |
| L20 | Gemini CLI `context.fileName` accepts a list such as `["AGENTS.md", "GEMINI.md"]`; project `.gemini/settings.json` overrides user settings. The Settings page as opened omits the option (C2). | S18, S20 | vendor-authoritative; confirm in the tool |
| L21 | Gemini CLI stopped serving free, AI Pro and AI Ultra users on 2026-06-18; Antigravity CLI (`agy`) replaces it and reads `GEMINI.md` and `AGENTS.md`; workspace skills move to `.agents/skills/`. Gemini Code Assist Standard and Enterprise keep Gemini CLI. | S21, S22, S23 | vendor-authoritative |
| L22 | Devin Desktop: `.devin/rules/` preferred, `.windsurf/rules/` legacy; a root `AGENTS.md` is an always-on rule; each workspace rule file is capped at 12,000 characters. | S24, S25 | vendor-authoritative |
| L23 | Copilot CLI uses both a root `AGENTS.md` and `.github/copilot-instructions.md` when both exist, defines no precedence between them, expands `@relative/path` includes, and lists loaded files with `/instructions`. | S12 | vendor-authoritative |
| L24 | VS Code loads a root `AGENTS.md` by default (`chat.useAgentsMdFile`); nested files are experimental and off by default. | S16, S17 | vendor-authoritative |
| L25 | Aider documents no `AGENTS.md` support; `read:` in `.aider.conf.yml` loads any file read-only and prompt-cached, from home, git root or current directory with last-loaded priority. | S26, S27 | vendor-authoritative |
| L26 | Codex memories redact secrets but users must still review memory files before sharing them. | S6 | vendor-authoritative |
| L27 | Frontier models follow roughly 150 to 200 instructions reliably and Claude Code's own system prompt already uses about 50. | S33 | **contradicted 2026-09-28**: all-instructions-satisfied accuracy is 0.574 at 5 and 0.213 at 10 (S43, EMNLP 2025 Findings); "breaks down beyond 5-6 simultaneous constraints" (S44); no academic source for 150–200 |
| L28 | Anthropic's long-running harness: an initializer session writes a feature list; each later session reads the git log and progress file, makes incremental progress, commits, and updates the progress file; features are marked passing only after tests. | S29 | single vendor post |
| L29 | Exact effect sizes for context files: no general success gain, cost up by more than 20 percent, overviews unhelpful, instructions well followed. | S31 | single study; S36 repeats it |
| L30 | Across 466 open-source projects there is no established content structure for context files. | S32 | single study |
| L31 | Claude Code auto memory keeps a `MEMORY.md` index of which only the first 200 lines or 25 KB load at startup, and skips anything `CLAUDE.md` already says. | S7 | vendor-authoritative |
| L32 | Claude Code SessionStart hook output is added to context; a Stop hook exiting 2 prevents the turn from ending. Codex SessionStart `additionalContext` is added as developer context. Gemini SessionStart injects context and SessionEnd is advisory. | S5, S9, S21 | each vendor-authoritative for its own tool |

## Added by the audit of 2026-09-28 (see `research/audit-2026-09-28.md`)

| ID | Learning | Source | Status |
|---|---|---|---|
| L33 | Self-correction without external feedback does not help and can degrade output; it works when reliable external feedback exists. The producing model silently endorsed 31.7 % of its own behaviour-changing edits. | S54, S55, S56 | peer-reviewed (ICLR 2024, TACL 2024); preprint |
| L34 | Execution feedback raises code success (up to +12 % with unit tests; TDD +9.49 pp); tests as the only gate get gamed, including by Codex and Claude Code; environmental hardening cuts exploits 87.7 % relative. | S57, S58, S59, S60, S61 | peer-reviewed and preprint |
| L35 | Agents do not read or write memory files voluntarily (0 memory operations in 114 turns); deterministic injection delivers every time. | S52 | preprint |
| L36 | Compaction silently drops in-context rules (violations 0 % → 30 %, up to 59 %); re-pinning after compaction restores 0 %. Prohibitions decay within a session (73 % at turn 5 → 33 % at turn 16); re-injection restores compliance. | S53, S64 | preprints |
| L37 | Summaries and handoffs keep facts but drop verification status and boundary rules; prose notes keep conclusions without the state that supported them; stale stored facts are trusted 0.92–1.00 of the time. | S65, S66, S67, S68 | preprints |
| L38 | LLM-written context files trail developer-written ones by 7 %; distilled strategies beat raw trajectories; append-only insight memory is insufficient; instruction files grow +226 % over their lifetime and rationale enables pruning. | S46, S69, S70, S49 | workshop; ICLR 2026; preprints |
| L39 | Corrections compiled into runtime checks reduce violations (100 % → 37.6 %) where memory alone leaves 57.5 % violated; review-derived rules plus a pre-submission checklist gave 0 % recurrence in one deployment. | S50, S71 | preprint; conference |
| L40 | Agent-written memory is an injection channel (Claude Code cross-session attack success 81.7 %); agents that write and retrieve memory aggressively are more exploitable. | S72, S73 | preprints |
| L41 | A specific external checklist beats a generic self-check (10/10 vs 5/10 runs). | S62 | preprint |
| L42 | Multi-turn performance drops ~39 %; instruction drift appears within eight rounds; compliance falls ~5.6 % per generated function within a session. | S74, S75, S45 | peer-reviewed; preprint |
| L43 | Irrelevant context, length alone and requirement ambiguity all degrade performance; repository overviews are not helpful. A subpar plan is worse than none. | S76, S77, S46, S78, S63 | peer-reviewed and preprint |
| L44 | Only 4.4 % of security rules in 481 CLAUDE.md files had a matching built-in control: prose is not a control. | S48 | preprint |

## Gaps (no reliable source; left open)

| ID | Gap |
|---|---|
| G1 | No cross-vendor "session end" mechanism, and no measurement of whether an instruction-only "update the status file before finishing" is reliably followed. |
| G2 | No primary source measures the best format or size of a progress or decisions file; S29 and S34 give examples, not measurements. |
| G3 | No vendor documents precedence when `AGENTS.md` and the tool's own rules directory contain overlapping instructions (Cursor, Devin, Copilot). |
| G4 | Per-IDE Copilot support for `AGENTS.md` in JetBrains, Xcode and Eclipse was not verified beyond the matrix in S11. |
| G5 | No source on Aider reading `AGENTS.md` natively. |
| G6 | Tools listed on agents.md but not individually verified: Jules, Junie, Amp, opencode, Warp, Factory, goose, Devin cloud. |
| G7 | No source defines "personal data" for agent memory files; the never-store list in the PRD is a rule, not a sourced claim. |
| G8 | ~~Whether Antigravity CLI honours Gemini's `context.fileName` and `.gemini/settings.json` hooks~~ Resolved 2026-09-28: Antigravity hooks live in `.agents/hooks.json` (S91); its handling of `@` imports in GEMINI.md remains undocumented. |
| G9 | Whether Codex, Cursor, Devin or Zed expand `@path` includes: their docs are silent. |
| G10 | Whether Zed reads nested `AGENTS.md` files: not documented on the pages opened. |
| G11 | Hook handler field names for Gemini CLI and Antigravity CLI, Copilot CLI's handling of Claude-format hooks, and Codex's `apply_patch` PreToolUse input: not verified in the pages opened (audit 2026-09-28). |
