# coding-agent-kit

A repository template so a developer and their coding agents share one project context that stays
current between sessions, across nine tools: Claude Code, OpenAI Codex, Cursor, GitHub Copilot,
Gemini CLI, Antigravity CLI, Devin Desktop, Zed and Aider. Version 1.1 (2026-10-06).

## What it does
1. **Starts every session knowing where the project stands.** `docs/agent/STATUS.md` and the active
   learnings are injected by session-start hooks (Claude Code, Codex, Cursor); other tools get rule 2.
2. **Verifies before presenting.** `ops/verify.sh` is the one definition of "done". A pre-finish
   gate runs it whenever code changed since the session began, commits included (Claude Code,
   Codex, Copilot, Cursor), and blocks completion claims until it passes and STATUS.md is current.
   A change to a gate file (`ops/verify.sh`, the check, hooks, CI) blocks too. A pre-commit hook
   runs it for every tool, hooks or not. Aider runs it after every edit. CI runs it on every push.
3. **Leaves memory more correct than it found it.** STATUS.md is rewritten with a verification
   status; DECISIONS.md is append-only (checked); LEARNINGS.md holds curated, evidenced lessons
   with a size cap. `ops/check-agent-kit.sh` enforces all of it locally and in CI.
4. **Writes down what to build before building it.** Each change is classified after reading the
   code (AGENTS.md rule 3). T0 needs only verification; T1 and T2 get a change file in
   `docs/agent/changes/` with acceptance criteria that each name a test. The gate nudges once when a
   large change has no change file; the check refuses a closed change without evidence.

Every rule is backed by a source: see `PRD.md` and `research/audit-2026-09-28.md`.

## Requirements
bash, git and python3 (3.8 or newer) on macOS or Linux. Windows is not supported: the hooks are
shell scripts. No other dependency.

## Setup (11 steps)
1. Use this template (or copy the files into your project root). Delete `PRD.md` and `research/`
   unless you want the design notes.
2. Replace the `KIT-PLACEHOLDER` block in `ops/verify.sh` with your test and lint commands.
3. Fill in `AGENTS.md` (Project, Commands, Conventions). Keep 7 rules or fewer.
4. Copy `.env.example` to `.env` and fill it in. `.env` is gitignored.
5. Keep the pointer files for tools you use, delete the rest: `CLAUDE.md` (Claude Code),
   `.gemini/settings.json` (Gemini CLI), `.aider.conf.yml` (Aider). Codex, Cursor, Copilot,
   Antigravity, Devin and Zed need no pointer.
6. Keep the hook files for tools you use: `.claude/settings.json` (Claude Code; Copilot CLI reads it
   too), `.codex/hooks.json`, `.cursor/hooks.json`, `.github/hooks/agent-kit.json` (Copilot).
   Each tool asks you once to trust them.
7. Enable the pre-commit gate once per clone: `git config core.hooksPath .githooks`. Run it
   yourself; the Claude Code deny rules stop the agent from changing `core.hooksPath`.
8. Run `./ops/check-agent-kit.sh` until it prints `OK` with no `TODO:` lines, then `./ops/test-kit.sh`.
9. Commit before the first agent session. The gate measures changes from the commit a session
   started on, and gate files changed during a session block it. `.github/workflows/agent-kit.yml`
   runs the check, the self-test and `ops/verify.sh` on every push and pull request.
10. Open your tool and ask "what did we cover last session?" — the briefing comes from STATUS.md.
11. Make a change and say "done": the gate runs `ops/verify.sh` and asks for STATUS.md first.

## What each tool reads and enforces
| Tool | Reads AGENTS.md | Session start | Pre-finish gate | Wrap-up backstop |
|---|---|---|---|---|
| Claude Code | via `CLAUDE.md` import | hook | `Stop` hook | end-of-session stamp, CI |
| Codex | natively | hook | `Stop` hook | stamp, CI |
| Copilot CLI / cloud agent | natively | CLI via `.claude/settings.json` | `Stop` / `agentStop` | CI |
| Cursor | natively | hook | `stop` hook | CI |
| Gemini CLI | via `.gemini/settings.json` | rule 2 | rule 1, pre-commit hook | CI |
| Antigravity CLI | natively | rule 2 | rule 1, pre-commit hook | CI |
| Devin Desktop | natively (always-on) | rule 2 | rule 1, pre-commit hook | CI |
| Zed | natively | rule 2 | rule 1, pre-commit hook | CI |
| Aider | via `.aider.conf.yml` | `read:`/`file:` | `auto-test` after each edit, pre-commit hook | CI |

`.githooks/pre-commit` applies to every row once `core.hooksPath` is set: a commit lands only if
`ops/verify.sh` passes. Rules 1 and 2 are prose; where a tool has no hook, verification before
presenting depends on the agent following them, and the pre-commit hook and CI catch what it
missed. Tested locally: Claude Code. `ops/test-kit.sh` checks the gate's output shape for each
tool; the other tools themselves are configured from their documentation (URLs in `PRD.md`) and
not tested locally.

## The files
| Path | Job |
|---|---|
| `AGENTS.md` | The instruction file every tool reads: commands, 7 ranked rules, conventions |
| `CLAUDE.md`, `.gemini/settings.json`, `.aider.conf.yml` | Point Claude Code, Gemini CLI and Aider at AGENTS.md |
| `docs/agent/STATUS.md` | Where the project stands; rewritten whenever code changes; injected at session start |
| `docs/agent/DECISIONS.md` | Append-only log of decisions with reasons |
| `docs/agent/LEARNINGS.md` | Curated lessons with evidence; the Active section is injected |
| `docs/agent/changes/` | One change file per T1/T2 change; copy `_template.md` |
| `ops/verify.sh` | The one verification command (your tests and lint, plus the kit check) |
| `ops/check-agent-kit.sh` | Enforces the kit's rules; run locally and in CI |
| `ops/test-kit.sh` | Proves the check and the hooks behave; run after setup and in CI |
| `ops/agent/` | Hook scripts: session start, stop gate, session end |
| `ops/agent/non-code-paths.txt` | Paths that never trigger verification or STATUS.md freshness |
| `.githooks/pre-commit` | Runs `ops/verify.sh` before every commit, for every tool |
| `.claude/`, `.codex/`, `.cursor/`, `.github/hooks/` | Hook configuration per tool |
| `.github/workflows/agent-kit.yml` | CI: check, self-test, verify |

## Troubleshooting
- **Hooks do not fire.** Each tool asks once to trust project hooks; accept the prompt. In Claude
  Code run `/hooks` to list them and `claude --debug` to watch them run. A wrong path disables a hook
  silently; `./ops/check-agent-kit.sh` reports missing hook scripts.
- **The gate blocks every "done".** It runs `ops/verify.sh` once per set of changes and blocks until
  it passes; three blocks in a row let the turn end with a warning. Edits to paths listed in
  `ops/agent/non-code-paths.txt` never trigger it. To turn off the STATUS.md and change-file
  nudges only, set `AGENT_KIT_NUDGES=0` in the tool's environment.
- **"Gate files changed since this session began".** A gate file (`ops/verify.sh`, the check,
  `ops/agent/`, `.githooks/`, hook configs, CI) differs from the commit the session started on.
  If you changed it on purpose, review and commit it, then start a new session.
- **Copilot CLI runs the Claude hooks.** It reads `.claude/settings.json` by design; the commands
  use `$(git rev-parse --show-toplevel)` so they work outside Claude Code too.
- **The agent cannot edit hooks or `ops/verify.sh`.** That is the `permissions.deny` block in
  `.claude/settings.json`; edit those files yourself. Its Bash patterns (`--no-verify`,
  `core.hooksPath`, `rm`/`mv`/`chmod` on `ops/`) match only the usual spelling of a command; the
  gate's own gate-file check is what holds.
- **A commit is refused.** `.githooks/pre-commit` ran `ops/verify.sh` and it failed; fix the
  failures. The hook checks the working tree, so unstaged edits count.
- **Known limits.** The gate's state in `~/.cache/agent-kit/` is writable by any process running as
  you, and the gate lets the turn end on an internal error. The pre-commit hook and CI are the
  backstops.
- **Check says `TODO:`.** Placeholders remain in `AGENTS.md` or `ops/verify.sh`; fill them. Once
  AGENTS.md is filled, an unconfigured `ops/verify.sh` fails the check.

## What never goes into agent files
Secrets, credentials, API keys, tokens, connection strings, personal data about real people,
customer data, pasted logs. Environment variables by name only; people by role. The kit check is a
tripwire for common credential patterns, not a full scanner.

## Files you can delete
`PRD.md`, `research/`, pointer and hook files for tools you do not use. Never add `.cursorrules`,
`.rules`, `AGENT.md`, `GEMINI.md` or `.github/copilot-instructions.md` next to `AGENTS.md`: Zed
reads the first of those it finds, and the check fails on them.

## License
MIT — see `LICENSE`.
