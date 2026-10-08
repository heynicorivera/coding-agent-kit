# coding-agent-kit

A repository template so a developer and their coding agents share one project context that stays
current between sessions, decide what to build before building it, and cannot call work done until
it verifies. Configured and tested for Claude Code; Codex, Cursor, Copilot, Antigravity, Devin and
Zed read its AGENTS.md natively, and untested configs for five more tools ship in
`contrib/untested/`. Version 2.1 (2026-10-07); see `CHANGELOG.md` and `ROADMAP.md`.

## What it does
1. **Starts every session knowing where the project stands.** `docs/agent/STATUS.md` and the active
   learnings are injected by the session-start hook; tools without one get rule 2.
2. **Verifies before presenting.** `ops/verify.sh` is the one definition of "done". A pre-finish
   gate runs it whenever code changed since the session began, commits included, and blocks
   completion claims until it passes and STATUS.md is current. A change to a gate file
   (`ops/verify.sh`, the check, `ops/agent/`, hooks, CI) blocks too. A pre-commit hook runs it for
   every tool, hooks or not. CI runs it on every push.
3. **Writes down what to build before building it.** Each change is classified after reading the
   code (AGENTS.md rule 3). T0 needs only verification. T1 gets a change file in
   `docs/agent/changes/` whose acceptance criteria each name a test; a bug fix also needs a test
   that failed first. T2 adds design notes and a Spec delta for a living spec in
   `docs/agent/specs/`. Closing a change archives it and merges its delta into the spec.
4. **Leaves memory more correct than it found it.** STATUS.md is rewritten with a verification
   status; DECISIONS.md is append-only (checked); LEARNINGS.md holds curated, evidenced lessons
   with a size cap. `ops/check-agent-kit.sh` enforces all of it locally and in CI.

Every rule is backed by a source: see `PRD.md` and `research/audit-2026-09-28.md`.

## Requirements
bash, git and python3 (3.8 or newer) on macOS or Linux. Windows is not supported yet: the hooks
are shell scripts (see ROADMAP.md). No other dependency.

## Setup (10 steps)
1. Use this template (or copy the files into your project root). Delete `PRD.md`, `research/`,
   `install.sh`, `ops/test-kit.sh` and `.github/workflows/kit-self-test.yml`: they
   develop the kit, not your project. A repository that already has the kit updates with
   `install.sh` instead (see "Updating the kit in a repository").
2. Fill in `AGENTS.md` (Project, Commands, Conventions); keep 7 rules or fewer. In an existing
   codebase, ask your agent to follow `docs/agent/ONBOARD.md`: it fills these from repository
   evidence, proposes your `ops/verify.sh` commands and writes a spec for the first area you change.
3. Replace the `KIT-PLACEHOLDER` block in `ops/verify.sh` with your test and lint commands.
4. Copy `.env.example` to `.env` and fill it in. `.env` is gitignored.
5. Using a tool other than Claude Code? Copy its config from `contrib/untested/` to the same path
   at the root (see `contrib/untested/README.md`). Each tool asks you once to trust hooks.
6. Enable the pre-commit gate once per clone: `git config core.hooksPath .githooks`. Run it
   yourself; the Claude Code deny rules stop the agent from changing `core.hooksPath`.
7. Run `./ops/check-agent-kit.sh` until it prints `OK` with no `TODO:` lines.
8. Commit before the first agent session. The gate measures changes from the commit a session
   started on, and gate files changed during a session block it. `.github/workflows/agent-kit.yml`
   runs `ops/verify.sh` on every push and pull request, and the range rules on pull requests.
9. Open your tool and ask "what did we cover last session?" — the briefing comes from STATUS.md.
10. Make a change and say "done": the gate runs `ops/verify.sh` and asks for STATUS.md first.

## What each tool reads and enforces
| Tool | Reads AGENTS.md | Session start | Pre-finish gate | Backstop |
|---|---|---|---|---|
| Claude Code | via `CLAUDE.md` import | hook | `Stop` hook | end-of-session stamp, pre-commit, CI |
| Copilot CLI | natively | via `.claude/settings.json` | `Stop` via `.claude/settings.json` | pre-commit, CI |
| Zed, Antigravity CLI, Devin Desktop | natively | rule 2 | rule 1 | pre-commit, CI |
| Codex, Cursor, Copilot cloud agent | natively | hook with a `contrib/untested/` config | stop hook with that config | pre-commit, CI |
| Gemini CLI, Aider | with a `contrib/untested/` pointer | rule 2 (Aider: `read:`) | rule 1 (Aider: `auto-test`) | pre-commit, CI |

`.githooks/pre-commit` applies to every row once `core.hooksPath` is set: a commit lands only if
`ops/verify.sh` passes. Rules 1 and 2 are prose; where a tool has no hook, verification before
presenting depends on the agent following them, and the pre-commit hook and CI catch what it
missed. Tested locally: Claude Code. `ops/test-kit.sh` checks the gate's output shape for every
tool and validates the `contrib/untested/` configs; the tools themselves are configured from their
documentation (URLs in `PRD.md`) and not run.

## Updating the kit in a repository
Run it from an up-to-date kit checkout (git 2.31 or newer), against a clean adopter on a new
branch, with no agent session open there:

    git -C <repo> switch -c kit-update
    ./install.sh --dry-run <repo>          # read the report first
    ./install.sh <repo>

The first update of a repository that was copied by hand needs `--from <tag>` (for example
`--from v1.0.0`); after that, `ops/agent/KIT_VERSION` remembers it. What happens to each file:

| Files | On update |
|---|---|
| `ops/check-agent-kit.sh`, `ops/agent/*.py`, `ops/agent/*.sh`, `.githooks/pre-commit`, `docs/agent/ONBOARD.md`, the two `_template.md` files | overwritten: the kit owns them |
| `AGENTS.md`, `CLAUDE.md`, `ops/verify.sh`, `docs/agent/STATUS.md`, `DECISIONS.md`, `LEARNINGS.md` | never written: you own them |
| `.claude/settings.json`, `.github/workflows/agent-kit.yml`, `.gitignore`, `ops/agent/non-code-paths.txt` | overwritten if you never changed them; otherwise the kit's copy lands beside yours as `<path>.kit-new` with a diff, and the kit check fails until you merge it and delete the sidecar |
| `ops/test-kit.sh`, `install.sh`, `contrib/`, `PRD.md`, `research/` and the other kit documents | never copied |

The report ends with the steps left to you: merging sidecars, `core.hooksPath`, AGENTS.md rule
changes, renamed variables, then STATUS.md, DECISIONS.md, `./ops/verify.sh`, commit, pull request.
Start agent sessions there only after that commit.

## Change files and specs
- **Open a change:** copy `docs/agent/changes/_template.md` to `docs/agent/changes/<name>.md`.
  Fill Intent, Tier, Acceptance (one Given/When/Then line per criterion, each with
  ``test: `path` ``), Tasks and Out of scope before code. T2 also fills Design and Spec delta.
- **Close it:** tick the tasks, fill Evidence (`verification: verified …`; a `T1 fix` also needs
  `failed first: …`), set `status: closed`, then run
  `./ops/agent/changes.py archive docs/agent/changes/<name>.md`. It refuses an incomplete change,
  merges the Spec delta (ADDED, MODIFIED, REMOVED by requirement ID) into the spec and moves the
  file to `docs/agent/changes/archive/`.
- **Gaps:** the kit check prints advisory `GAP:` lines when an open change names a test that does
  not exist yet or has not changed on this branch.

## The files
| Path | Job |
|---|---|
| `AGENTS.md` | The instruction file every tool reads: commands, 7 ranked rules, conventions |
| `CLAUDE.md` | Points Claude Code at AGENTS.md |
| `docs/agent/STATUS.md` | Where the project stands; rewritten whenever code changes; injected at session start |
| `docs/agent/DECISIONS.md` | Append-only log of decisions with reasons |
| `docs/agent/LEARNINGS.md` | Curated lessons with evidence; the Active section is injected |
| `docs/agent/changes/` | One change file per T1/T2 change; closed ones in `archive/` |
| `docs/agent/specs/` | Living specs, one per domain, changed through T2 Spec deltas |
| `docs/agent/ONBOARD.md` | Prompt that onboards an existing repository; read on demand |
| `ops/verify.sh` | The one verification command (your tests and lint, plus the kit check) |
| `ops/check-agent-kit.sh` | Enforces the kit's rules; run locally and in CI |
| `ops/test-kit.sh` | Kit only: proves the check, the hooks, the change tooling and `install.sh` behave |
| `install.sh` | Kit only: updates the kit's files in an adopter repository |
| `ops/agent/` | Hook scripts (session start, stop gate, session end), `changes.py`, the non-code list |
| `.githooks/pre-commit` | Runs `ops/verify.sh` before every commit, for every tool |
| `.claude/settings.json` | Claude Code hooks and deny rules (Copilot CLI reads it too) |
| `contrib/untested/` | Configs for Codex, Cursor, Copilot cloud agent, Gemini CLI, Aider; inactive until copied |
| `.github/workflows/agent-kit.yml` | CI: verify on every push, range rules on pull requests |
| `.github/workflows/kit-self-test.yml` | Kit only: runs `ops/test-kit.sh` |
| `CHANGELOG.md`, `ROADMAP.md` | What shipped, what is planned |

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
- **The agent cannot edit hooks or `ops/verify.sh`.** That is the `permissions.deny` block in
  `.claude/settings.json`; edit those files yourself. Its Bash patterns (`--no-verify`,
  `core.hooksPath`, `rm`/`mv`/`chmod` on `ops/`) match only the usual spelling of a command; the
  gate's own gate-file check is what holds.
- **A commit is refused.** `.githooks/pre-commit` ran `ops/verify.sh` and it failed; fix the
  failures. The hook checks the working tree, so unstaged edits count.
- **"is closed; run ./ops/agent/changes.py archive".** A closed change must be archived so its Spec
  delta reaches the spec; run the command it prints.
- **Known limits.** The gate's state in `~/.cache/agent-kit/` is writable by any process running as
  you, and the gate lets the turn end on an internal error. The pre-commit hook and CI are the
  backstops.
- **Check says `TODO:`.** Placeholders remain in `AGENTS.md` or `ops/verify.sh`, or the pre-commit
  gate is off; fix what it names. Once AGENTS.md is filled, an unconfigured `ops/verify.sh` fails
  the check.

## What never goes into agent files
Secrets, credentials, API keys, tokens, connection strings, personal data about real people,
customer data, pasted logs. Environment variables by name only; people by role. The kit check is a
tripwire for common credential patterns, not a full scanner.

## Files you can delete
`PRD.md`, `research/`, `contrib/untested/` configs for tools you do not use. Never add
`.cursorrules`, `.rules`, `AGENT.md`, `GEMINI.md` or `.github/copilot-instructions.md` next to
`AGENTS.md`: Zed reads the first of those it finds, and the check fails on them.

## License
MIT — see `LICENSE`.
