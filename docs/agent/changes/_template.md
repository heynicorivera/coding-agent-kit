# <Change title>
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Copy to docs/agent/changes/<short-name>.md
     and fill Intent, Tier, Acceptance, Tasks and Out of scope before writing code. Close it once
     ./ops/verify.sh passes: tick the tasks, fill Evidence, set status: closed.
     ops/check-agent-kit.sh checks the shape. No secrets, no personal data. -->
status: open

## Intent
<one sentence: what changes, for whom, and why>

## Tier
<T1 | T2> · <one clause: why this tier>

## Acceptance
<!-- One line per criterion. Each names the test that proves it; a closed change needs the file. -->
- Given <context>, when <action>, then <observable result> · test: `<path/to/test>`

## Tasks
- [ ] <task>

## Out of scope
- <what this change deliberately does not do>

## Evidence
<!-- Filled when closing. -->
- verification: <verified | partial | failed> — command: `./ops/verify.sh` — at: <date>, <commit | uncommitted>
- last lines: <the last lines of ./ops/verify.sh output>

## Design
<!-- T2 only: decisions, rejected alternatives, risks. Delete this section for T1. -->
