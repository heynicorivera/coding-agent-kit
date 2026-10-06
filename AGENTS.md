# AGENTS.md

Single source of truth for every coding agent in this repository. `CLAUDE.md` and the opt-in
pointer files in `contrib/untested/` only point here. What must always hold is enforced by hooks,
`ops/verify.sh` and `ops/check-agent-kit.sh`; this file holds only what an agent cannot infer from
the code. Max 7 rules.

## Project
- Purpose: <one sentence: what this software does and for whom>
- Stack: <languages, frameworks, package manager, runtime versions>
- Layout: <`src/` application code, `tests/` tests, `docs/` documentation> (match the real tree)

## Commands
- Verify: `./ops/verify.sh` — tests, lint and kit check; the only definition of "done"
- Setup: `<command>` · Run locally: `<command>`

## Rules — ranked, max 7
1. Nothing is done until `./ops/verify.sh` passes and you quote its last lines. Never change
   `ops/verify.sh`, `ops/check-agent-kit.sh`, `ops/agent/`, `.githooks/`, hook configs or CI.
2. Read `docs/agent/STATUS.md` first if it is not already in your context, then run
   `./ops/verify.sh` before new work; a failure inherited from the last session comes first.
3. Classify each change after reading the code. T0 (trivial, under ~20 lines): verify only.
   T1 (feature or bug fix): a change file from `docs/agent/changes/_template.md` before code; a fix
   needs a test that failed before it. T2 (schema, auth, payments, cross-module): T1 plus Design and
   Spec delta. Unsure: the higher tier. Done: close it, run `./ops/agent/changes.py` archive.
4. When code changed, rewrite `docs/agent/STATUS.md` before presenting: what changed, `verification:`
   (verified | partial | failed) with the command and commit, what is next. Under 60 lines.
5. Append chosen-between alternatives to `docs/agent/DECISIONS.md`; propose repeated lessons in
   `docs/agent/LEARNINGS.md` with evidence. Never delete or rewrite a past decision.
6. Never write secrets, credentials, connection strings, personal data or pasted logs into any agent
   file. Environment variables by name; people by role.
7. Ask before adding dependencies, changing schemas, deleting files, or touching auth, payments or
   production configuration.

## Conventions (only what no linter enforces)
- <e.g. "All HTTP handlers return errors through src/errors, never raw exceptions">

## Git
- Imperative subject ≤ 72 characters, one change per commit. Never push directly to `main`.
