# Add install.sh to update adopter repositories
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Copy to docs/agent/changes/<short-name>.md
     and fill Intent, Tier, Acceptance, Tasks and Out of scope before writing code. When
     ./ops/verify.sh passes: tick the tasks, fill Evidence, set status: closed, then run
     ./ops/agent/changes.py archive docs/agent/changes/<short-name>.md, which merges the Spec delta
     and moves this file to archive/. ops/check-agent-kit.sh checks the shape.
     No secrets, no personal data. -->
status: closed

## Intent
Adopters update the kit in their repository with one command that overwrites only kit-owned files,
never adopter-owned ones, and leaves a reviewable sidecar for files both sides may have patched.

## Tier
T1 · a new script with tests; no schema, auth or cross-module behaviour change in the gate

## Acceptance
- Given a v1.0.0 adopter with filled AGENTS.md and configured verify.sh, when install.sh runs, then adopter-owned files are byte-unchanged, kit-owned files equal the kit's and never-shipped files are absent · test: `ops/test-kit.sh::install update from v1.0.0`
- Given an updated adopter with the result committed, when install.sh runs again, then the working tree stays clean · test: `ops/test-kit.sh::install is idempotent`
- Given a shared file patched by the adopter and changed by the kit, when install.sh runs, then the target is unchanged, `<path>.kit-new` is written and named in the report, and the kit check fails until it is resolved · test: `ops/test-kit.sh::install writes a sidecar`
- Given --dry-run, when install.sh runs, then nothing in the target changes and the report says "would write" · test: `ops/test-kit.sh::install dry run`
- Given a dirty target, a non-git target, the kit itself or an existing sidecar, when install.sh runs, then it refuses with one line and exit 1 · test: `ops/test-kit.sh::install refuses`
- Given --from v1.0.0, when install.sh runs, then the report lists core.hooksPath, the AGENTS.md rule changes and every AGENT_KIT_STATUS_GATE hit · test: `ops/test-kit.sh::install report`
- Given an adopter without an optional shared file, when install.sh runs, then that file is reported and not written, and a missing non-code-paths.txt is written · test: `ops/test-kit.sh::install absent shared files`

## Tasks
- [x] install.sh at the repository root with the custody table at the top
- [x] ops/check-agent-kit.sh: FAIL on `*.kit-new`, NOTE with the version from ops/agent/KIT_VERSION
- [x] ops/test-kit.sh: `== install.sh ==` section with the seven cases above
- [x] CI split: shipped agent-kit.yml (range rules on pull requests, not Dependabot), kit-only kit-self-test.yml
- [x] README, PRD §6, CHANGELOG 2.1.0, ROADMAP (adopter findings, named by role)
- [x] DECISIONS entries; STATUS rewrite

## Out of scope
- Merging shared-custody files; an init mode for new repositories; copying contrib/ configs
- The adopter findings listed in ROADMAP.md Next (planned as 2.2)

## Evidence
- verification: verified — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: 2026-10-07, uncommitted on add-installer
- last lines: OK: agent kit checks passed · 117 passed, 0 failed
- mutation check: five broken custody rules each fail at least one install case
