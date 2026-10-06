# Onboarding an existing repository
<!-- Read on demand ("follow docs/agent/ONBOARD.md"); never injected. Run it once, after the kit
     files are copied in and before the first change. No secrets, no personal data. -->

Goal: the kit describes this repository from evidence before anyone changes it. Work in this
order. Where the repository gives no evidence, leave the placeholder and ask; never guess.

1. **Collect evidence.** Read the README, the CI workflows, the manifests and lockfiles
   (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, …), any Makefile or task runner, and
   the test directories. Note the exact commands CI runs.
2. **Fill AGENTS.md → Project and Commands.** Purpose, Stack (with versions from manifests or
   lockfiles), Layout (directories that exist), Setup and Run locally. In your reply, name the file
   each value came from; do not put sources into AGENTS.md.
3. **Propose `ops/verify.sh`.** Write the replacement for its KIT-PLACEHOLDER block from the
   commands CI runs (tests, lint, type check). Do not edit the file: it is a gate file. The human
   pastes it, runs `./ops/verify.sh`, and commits before the first agent session.
4. **Conventions.** Add at most five, each one the code follows consistently and no linter
   enforces. Skip the section if nothing qualifies.
5. **Specs, only where the first change lands.** Ask which change comes first. For the domain it
   touches, copy `docs/agent/specs/_template.md` to `docs/agent/specs/<domain>.md` and list what the
   code does today: one requirement per line, an ID like AUTH-1, the covering test if one exists.
   Write only behaviour you have read in the code or its tests. Leave every other domain unwritten.
6. **STATUS.md.** Rewrite it: what was onboarded, `verification: none` until the human has run
   the new `ops/verify.sh`, and next: the first change, with its tier.
7. **Check.** Run `./ops/check-agent-kit.sh` until it prints OK. List the remaining `TODO:` lines
   for the human, including `git config core.hooksPath .githooks`.
