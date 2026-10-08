# Record the learnings-cap defect as known failures
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Closed and archived when done. -->
status: closed

## Intent
The learnings-cap defect becomes a ready 2.2 item: a ROADMAP entry with source, symptom, evidence
and test, and self-test cases that fail today without failing the suite.

## Tier
T1 · a new self-test mechanism (known failures) and two cases; no shipped script changes

## Acceptance
- Given 21 active learnings, when the self-test runs, then the check's silence is reported as a known failure and the suite still passes · test: `ops/test-kit.sh::the check refuses a 21st active learning`
- Given 41 one-line active learnings, when the self-test runs, then the dropped 41st entry is reported as a known failure · test: `ops/test-kit.sh::a 41st active learning is injected or refused`
- Given a known failure that starts passing, when the self-test runs, then the suite fails and says to make it a normal case · test: `ops/test-kit.sh`

## Tasks
- [x] `known_failure` helper and the two cases in ops/test-kit.sh
- [x] ROADMAP Next entry in the four-field format, with the format stated once
- [x] DECISIONS entry; CHANGELOG and STATUS updated

## Out of scope
- Fixing the cap, the 40-line injection limit or the file-wide 100-line cap (2.2)

## Evidence
- verification: verified — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: 2026-10-07, uncommitted on add-installer
- last lines: 117 passed, 0 failed, 2 known failures (ROADMAP Next)
- reverse check: with a 20-entry check added, both cases failed the suite with "now passes"
