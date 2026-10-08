# Record the notes-vault real-run findings as known failures
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Closed and archived when done. -->
status: closed

## Intent
Two defects found during the real notes-vault update become ready 2.2 items: ROADMAP entries
with source, symptom, evidence and test, and self-test cases that fail today without failing
the suite.

## Tier
T1 · two self-test cases and ROADMAP entries; no shipped script changes

## Acceptance
- Given a v1.0 adopter whose rule 1 is its own, when install.sh updates it, then "make rules 1-3 say what the kit's say" is reported as a known failure · test: `ops/test-kit.sh::install AGENTS.md step fits an adopter with its own rules`
- Given a session that pulls a commit bringing code and STATUS.md together, with STATUS.md written first, when a turn claims done, then the STATUS nudge is reported as a known failure · test: `ops/test-kit.sh::a pull that brings code with its STATUS.md does not nudge`
- Given either defect fixed, when the self-test runs, then the suite fails with "now passes" · test: `ops/test-kit.sh`

## Tasks
- [x] Two known-failure cases in ops/test-kit.sh
- [x] Two ROADMAP entries under the 2.2 fixes, in the four-part format
- [x] STATUS updated

## Out of scope
- Fixing either defect (2.2)
- The vault's own follow-up (its AGENTS.md, STATUS.md, DECISIONS.md), done in a vault session

## Evidence
- verification: verified — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: 2026-10-08, uncommitted on record-vault-update
- last lines: 117 passed, 0 failed, 6 known failures (ROADMAP Next)
- reverse check: in a throwaway worktree, a closing step without rule numbers and a pull case with STATUS.md written last each failed the suite with "now passes"; the gate's message in the pull case was the STATUS nudge
