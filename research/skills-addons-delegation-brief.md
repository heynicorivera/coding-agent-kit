# Delegation brief: evaluate skill add-ons for the kit

> **Status: feature request, exploration phase.** This brief asks for investigation and a written
> proposal only. It does not authorise building, installing or committing anything to the kit's
> shipped files. Background and sources: `research/skills-addons-exploration-2026-10-09.md`.

## Prompt for the delegated model

You are helping the maintainer of this repository (a coding-agent template) decide whether to add a
small set of agent skills. Work in a branch; never push to `main`. Do not edit gate files
(`ops/verify.sh`, `ops/check-agent-kit.sh`, `ops/agent/`, `.githooks/`, hook configs, CI). Ask
before adding dependencies. No secrets or personal data in any file you write.

**Read first:** `AGENTS.md`, `docs/agent/STATUS.md`, `ROADMAP.md` (Next), `PRD.md` (non-goals), and
the exploration summary named above.

**Goal:** a proposal for adding up to five skills that help the kit deliver code fast with few
tokens, without breaking its rules: 7 ranked rules at most, deterministic checks, only bash, git
and python3 required, always-on context kept minimal.

**Candidates under review:**
1. Official `typescript-lsp` / `pyright-lsp` plugins (per project)
2. Ponytail reduced to one rule line plus its `ponytail-review` skill
3. Superpowers `systematic-debugging`, copied alone
4. ast-grep `ast-grep` and `outline` skills
5. Optional: Pocock `grill-me` + `grilling`

**Tasks, in order. Stop and report after each phase.**

Phase 1: verify (read-only).
- Read each candidate's LICENSE, SKILL.md and any hooks or scripts from its repository at a pinned
  commit. Record URL, commit SHA, licence, files, description length in characters.
- Resolve the open items in section 4 of the summary. Mark each as verified, refuted or still open,
  with the source.
- Check for dangling cross-references in `systematic-debugging` and what it would need to run
  inside this kit.

Phase 2: measure.
- Design a test of 5-10 T1 tasks run twice each (with and without a candidate) on a scratch
  repository, never on a real adopter. Define metrics before running: cost or tokens, wall time,
  `ops/verify.sh` pass on the first attempt, lines changed.
- Run it only if the maintainer approves the plan. Report raw numbers, not only averages. If the
  run is too small to show a difference, say so.

Phase 3: propose (write only).
- Write `research/skills-addons-proposal.md` with: findings per candidate (observed only, no
  interpretation mixed in), then a separate recommendation section; a keep / drop table; the
  file layout (`.agents/skills/`, `SOURCE` files); the deterministic checks that would police it;
  how `install.sh` would treat the files; the effect on the AGENTS.md rule budget; sequencing
  against the planned OpenSpec-style commands.
- Do not create a change file, edit `ROADMAP.md` or touch `install.sh`. The maintainer decides
  whether this becomes a roadmap item.

**Output format:** summary first (bad news before good), then comparison tables, then the action
plan, then references with URLs. Short, plain sentences. Metric units. Mark every figure as
measured by you, measured by a third party, or a vendor claim.

**Done when:** `research/skills-addons-proposal.md` exists, every candidate has a licence and a
pinned commit recorded, every open item is resolved or explicitly left open, and the maintainer has
the approve / reject decision in front of them.

**Out of scope:** installing any full plugin (Superpowers, Ponytail, RTK, caveman, Serena);
changing hooks or the verify command; adding persona or subagent frameworks.
