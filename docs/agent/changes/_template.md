# <Change title>
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Copy to docs/agent/changes/<short-name>.md
     and fill Intent, Tier, Acceptance, Tasks and Out of scope before writing code. When
     ./ops/verify.sh passes: tick the tasks, fill Evidence, set status: closed, then run
     ./ops/agent/changes.py archive docs/agent/changes/<short-name>.md, which merges the Spec delta
     and moves this file to archive/. ops/check-agent-kit.sh checks the shape.
     No secrets, no personal data. -->
status: open

## Intent
<one sentence: what changes, for whom, and why>

## Tier
<T1 | T1 fix | T2> · <one clause: why this tier>

## Acceptance
<!-- One line per criterion. Each names the test that proves it; a closed change needs the file. -->
- Given <context>, when <action>, then <observable result> · test: `<path/to/test>`

## Tasks
- [ ] <task>

## Out of scope
- <what this change deliberately does not do>

## Evidence
<!-- Filled when closing. "failed first" is for T1 fix only: the test that failed before the fix
     and how it failed. Delete that line for other tiers. -->
- verification: <verified | partial | failed> — command: `./ops/verify.sh` — at: <date>, <commit | uncommitted>
- last lines: <the last lines of ./ops/verify.sh output>
- failed first: <test path> failed with <message> before the fix

## Design
<!-- T2 only: decisions, rejected alternatives, risks. Delete this section for T1. -->

## Spec delta
<!-- T2 only: requirement lines for one living spec, merged on archive. ADDED IDs must be new,
     MODIFIED and REMOVED IDs must exist. Delete this section for T1. -->
spec: docs/agent/specs/<domain>.md
### ADDED
- <DOMAIN-2>: <what the system does after this change> · test: `<path/to/test>`
### MODIFIED
- <DOMAIN-1>: <the requirement as it reads after this change> · test: `<path/to/test>`
### REMOVED
- <DOMAIN-3>
