# Changelog

Notable changes to the kit, newest first. Versions are git tags (`v2.0.0`); dates are ISO 8601.

## Unreleased

### Changed
- AGENTS.md, Git: a records-only change (every path in `ops/agent/non-code-paths.txt`) is
  committed and pushed to `main` at wrap-up once `./ops/verify.sh` passes; anything else goes
  through a branch and a pull request. Existing adopters copy the lines into their own AGENTS.md.
- STATUS.md: `updated:` and the verification line's `at:` carry the time and zone, read from the
  clock (`2026-10-08 14:37 CEST`).

## 2.1.0 — 2026-10-07

### Added
- `install.sh` updates the kit in an adopter repository: overwrites kit-owned files, never writes
  adopter-owned ones, and puts the kit's copy of a locally patched shared file beside it as
  `<path>.kit-new`. `--dry-run` previews; `--from <tag>` names the kit an older copy came from.
  It stamps `ops/agent/KIT_VERSION` and ends with the steps left to a human.
- `ops/check-agent-kit.sh` fails while a `*.kit-new` file exists and prints the stamped version.
- `.github/workflows/kit-self-test.yml` runs `ops/test-kit.sh` in the kit only. The self-test
  grows from 92 to 117 cases.
- Known failures in `ops/test-kit.sh`: a ROADMAP finding is written as a case that must fail
  until it is fixed; the suite fails once it passes. Two record the learnings-cap defect.

### Changed
- `.github/workflows/agent-kit.yml` runs the range rules on pull requests only and not for
  Dependabot, and no longer runs the self-test: the version proven in the first adopter.
- README and PRD §6 no longer tell adopters to copy or run `ops/test-kit.sh`.

## 2.0.0 — 2026-10-06

### Fixed
- The stop gate could be skipped four ways: commit, then stop (B1); add `KIT-PLACEHOLDER` to
  `ops/verify.sh` (B2); `chmod -x` it (B3); delete or rename it (B4). The gate now measures changes
  from the session base, so commits count, and a gate file changed since that base blocks the turn.
  Whether `verify.sh` is configured is read from the base.
- `ops/agent/session-end.sh` replaces its earlier "ended without wrap-up" stamp instead of adding
  another, so STATUS.md stays under its 60-line cap.
- CI failed on the first push of a branch: GitHub sends an all-zero `before` commit and
  `ops/check-agent-kit.sh --range` aborted with exit 128. It now prints a note and skips the
  range rules; the pull-request run still applies them.
- `ops/test-kit.sh` asked to confirm deleting each read-only git object when run from a
  terminal; its cleanup now makes them writable first.
- README-only edits no longer run `ops/verify.sh`: the gate and the CI freshness rule read one list,
  `ops/agent/non-code-paths.txt`.

### Added
- `.githooks/pre-commit` runs `ops/verify.sh` before every commit, for every tool; enable it with
  `git config core.hooksPath .githooks`.
- Change files (`docs/agent/changes/`) with tiers in AGENTS.md rule 3: T0 verify only, T1 a change
  file with acceptance criteria that each name a test (a fix needs a test that failed first), T2
  adds Design and a Spec delta. The gate nudges once when a large change has none or one is open.
- Living specs (`docs/agent/specs/`) and `ops/agent/changes.py`: `check` validates change files and
  specs and lists advisory GAP lines; `archive` merges a closed change's Spec delta into its spec
  and moves the change to `docs/agent/changes/archive/`.
- `docs/agent/ONBOARD.md`, a prompt that onboards an existing repository from evidence.
- Claude Code deny rules for `.githooks/**`, the gate's cache, `--no-verify`, `core.hooksPath`
  and `rm`/`mv`/`chmod` on `ops/`.
- ROADMAP.md and this changelog. `ops/test-kit.sh` grows from 32 to 92 cases.

### Changed
- AGENTS.md rules 2 and 3 merged (read STATUS.md, then verify) to make room for the tier rule;
  still 7 rules.
- `AGENT_KIT_STATUS_GATE=0` is now `AGENT_KIT_NUDGES=0` and turns off both nudges.

### Moved
- The untested configs for Codex, Cursor, Copilot cloud agent, Gemini CLI and Aider moved to
  `contrib/untested/`; copy one to the root to enable it.

## 1.0.0 — 2026-09-28
- First release: AGENTS.md with 7 ranked rules, STATUS/DECISIONS/LEARNINGS memory, session-start
  injection, the stop gate on four tools, `ops/verify.sh`, the kit check and self-test, CI.
