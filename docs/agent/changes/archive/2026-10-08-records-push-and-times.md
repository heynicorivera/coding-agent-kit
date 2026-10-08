# Push records-only changes at wrap-up; time in STATUS.md
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Closed and archived when done. -->
status: closed

## Intent
The maintainer stops approving pull requests that only change records: at wrap-up, a change whose
every path is in `ops/agent/non-code-paths.txt` is committed and pushed to `main`, while code keeps
going through pull requests; and STATUS.md, rewritten several times a day, shows the time it was
updated.

## Tier
T1 · a shipped rule and template change; no script changes

## Acceptance
- Given the STATUS.md the kit ships, when the self-test runs, then its `updated:` line carries a time and zone · test: `ops/test-kit.sh::the shipped STATUS.md dates its update with a time`

## Tasks
- [x] Self-test case, failing first
- [x] AGENTS.md Git section: records-only changes pushed to `main` at wrap-up, anything else a pull request
- [x] STATUS.md: wrap-up wording in its comment; `updated:` and `at:` with time and zone
- [x] PRD R5 shape; DECISIONS entries for both choices; CHANGELOG Unreleased

## Out of scope
- A hook or script that pushes: the rule is followed by the agent at wrap-up
- Times in DECISIONS, LEARNINGS, change files or CHANGELOG
- A check that enforces the time format in adopters' STATUS.md

## Evidence
- verification: verified — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: 2026-10-08 14:52 CEST, uncommitted on records-push-and-times
- last lines: 118 passed, 0 failed, 6 known failures (ROADMAP Next)
- test first: the new case failed (117 passed, 1 failed) while STATUS.md's updated: line had a date only
