# coding-agent-kit

A repository template so a developer and their coding agents share one project context that stays
current between sessions, across nine tools: Claude Code, OpenAI Codex, Cursor, GitHub Copilot,
Gemini CLI, Antigravity CLI, Devin Desktop, Zed and Aider. Version 1.0 (2026-09-28).

## What it does
1. **Starts every session knowing where the project stands.** `docs/agent/STATUS.md` and the active
   learnings are injected by session-start hooks (Claude Code, Codex, Cursor); other tools get rule 2.
2. **Verifies before presenting.** `ops/verify.sh` is the one definition of "done". A pre-finish
   gate runs it whenever code changed (Claude Code, Codex, Copilot, Cursor) and blocks completion
   claims until it passes and STATUS.md is current. Aider runs it after every edit. CI runs it on
   every push.
3. **Leaves memory more correct than it found it.** STATUS.md is rewritten with a verification
   status; DECISIONS.md is append-only (checked); LEARNINGS.md holds curated, evidenced lessons
   with a size cap. `ops/check-agent-kit.sh` enforces all of it locally and in CI.

Every rule is backed by a source: see `PRD.md` and `research/audit-2026-09-28.md`.

## Requirements
bash, git and python3 (3.8 or newer) on macOS or Linux. Windows is not supported: the hooks are
shell scripts. No other dependency.

## Setup (10 steps)
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
7. Run `./ops/check-agent-kit.sh` until it prints `OK` with no `TODO:` lines, then `./ops/test-kit.sh`.
8. Commit. `.github/workflows/agent-kit.yml` runs the check, the self-test and `ops/verify.sh` on
   every push and pull request.
9. Open your tool and ask "what did we cover last session?" — the briefing comes from STATUS.md.
10. Make a change and say "done": the gate runs `ops/verify.sh` and asks for STATUS.md first.

## What each tool reads and enforces
| Tool | Reads AGENTS.md | Session start | Pre-finish gate | Wrap-up backstop |
|---|---|---|---|---|
| Claude Code | via `CLAUDE.md` import | hook | `Stop` hook | end-of-session stamp, CI |
| Codex | natively | hook | `Stop` hook | stamp, CI |
| Copilot CLI / cloud agent | natively | CLI via `.claude/settings.json` | `Stop` / `agentStop` | CI |
| Cursor | natively | hook | `stop` hook | CI |
| Gemini CLI | via `.gemini/settings.json` | rule 2 | rule 1 | CI |
| Antigravity CLI | natively | rule 2 | rule 1 | CI |
| Devin Desktop | natively (always-on) | rule 2 | rule 1 | CI |
| Zed | natively | rule 2 | rule 1 | CI |
| Aider | via `.aider.conf.yml` | `read:`/`file:` | `auto-test` after each edit | CI |

Rules 1 and 2 are prose; where a tool has no hook, verification and memory depend on the agent
following them and on CI catching what it missed. Tested locally: Claude Code. The other tools are
configured from their documentation (URLs in `PRD.md`) and not tested locally.

## The files
| Path | Job |
|---|---|
| `AGENTS.md` | The instruction file every tool reads: commands, 7 ranked rules, conventions |
| `CLAUDE.md`, `.gemini/settings.json`, `.aider.conf.yml` | Point Claude Code, Gemini CLI and Aider at AGENTS.md |
| `docs/agent/STATUS.md` | Where the project stands; rewritten whenever code changes; injected at session start |
| `docs/agent/DECISIONS.md` | Append-only log of decisions with reasons |
| `docs/agent/LEARNINGS.md` | Curated lessons with evidence; the Active section is injected |
| `ops/verify.sh` | The one verification command (your tests and lint, plus the kit check) |
| `ops/check-agent-kit.sh` | Enforces the kit's rules; run locally and in CI |
| `ops/test-kit.sh` | Proves the check and the hooks behave; run after setup and in CI |
| `ops/agent/` | Hook scripts: session start, stop gate, session end |
| `.claude/`, `.codex/`, `.cursor/`, `.github/hooks/` | Hook configuration per tool |
| `.github/workflows/agent-kit.yml` | CI: check, self-test, verify |

## Troubleshooting
- **Hooks do not fire.** Each tool asks once to trust project hooks; accept the prompt. In Claude
  Code run `/hooks` to list them and `claude --debug` to watch them run. A wrong path disables a hook
  silently; `./ops/check-agent-kit.sh` reports missing hook scripts.
- **The gate blocks every "done".** It runs `ops/verify.sh` once per set of changes and blocks until
  it passes; three failures in a row let the turn end with a warning. To turn off the STATUS.md
  freshness part only, set `AGENT_KIT_STATUS_GATE=0` in the tool's environment.
- **Copilot CLI runs the Claude hooks.** It reads `.claude/settings.json` by design; the commands
  use `$(git rev-parse --show-toplevel)` so they work outside Claude Code too.
- **The agent cannot edit hooks or `ops/verify.sh`.** That is the `permissions.deny` block in
  `.claude/settings.json`; edit those files yourself.
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
