# Record the notes-vault update findings as known failures
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Closed and archived when done. -->
status: closed

## Intent
The two install.sh defects found while preparing the notes-vault update become ready 2.2 items:
ROADMAP entries with source, symptom, evidence and test, and self-test cases that fail today
without failing the suite.

## Tier
T1 · two self-test cases and ROADMAP entries; no shipped script changes

## Acceptance
- Given a v1.0 adopter that removed the SessionEnd hook from its Claude settings, when install.sh updates it, then the sidecar re-adding that hook is reported as a known failure · test: `ops/test-kit.sh::install sidecar keeps a hook the adopter removed`
- Given an adopter without a git remote, when install.sh prints its closing steps, then "open a pull request" is reported as a known failure · test: `ops/test-kit.sh::install closing steps fit a repository without a remote`
- Given either defect fixed, when the self-test runs, then the suite fails with "now passes" · test: `ops/test-kit.sh`

## Tasks
- [x] Two known-failure cases in the install.sh section of ops/test-kit.sh
- [x] Two ROADMAP entries under the 2.2 fixes, in the four-part format
- [x] STATUS updated (no CHANGELOG entry: the cases are kit-internal; the fixes get one in 2.2)

## Out of scope
- Fixing either defect (2.2)
- The real notes-vault run: the maintainer runs install.sh there

## Evidence
- verification: verified — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: 2026-10-08, uncommitted on vault-rollout-findings
- last lines: 117 passed, 0 failed, 4 known failures (ROADMAP Next)
- reverse check: in a throwaway worktree, a sidecar written by `git merge-file` and a closing step that checks for a remote made both cases fail the suite with "now passes"
