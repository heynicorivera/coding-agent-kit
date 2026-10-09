# Ship vetted agent skills in one folder every daily tool reads
<!-- One file per T1 or T2 change (AGENTS.md rule 3). Copy to docs/agent/changes/<short-name>.md
     and fill Intent, Tier, Acceptance, Tasks and Out of scope before writing code. When
     ./ops/verify.sh passes: tick the tasks, fill Evidence, set status: closed, then run
     ./ops/agent/changes.py archive docs/agent/changes/<short-name>.md, which merges the Spec delta
     and moves this file to archive/. ops/check-agent-kit.sh checks the shape.
     No secrets, no personal data. -->
status: open

## Intent
The kit ships two copied, pinned and licensed skills in `.agents/skills/`, `/kit-explore` (Pocock's
grill-me and grilling, merged) and `/kit-debug` (Superpowers' systematic-debugging), linked for
Claude Code and checked, so agents in Claude Code and Zed get a planning interview and a debugging
method without unlicensed or executable third-party files (sources:
`research/skills-addons-proposal.md`).

## Tier
T2 · cross-module: a new shipped folder, a check in a gate file, install.sh custody, AGENTS.md rule 3 and two PRD non-goals change

## Acceptance
- Given the template, when the kit check runs, then it passes with both skills, their links and their SOURCE and LICENSE files · test: `ops/test-kit.sh::skills template passes`
- Given a SKILL.md one folder deeper than a skill folder, when the check runs, then it fails and names the file · test: `ops/test-kit.sh::skills check refuses a nested skill`
- Given a skill whose name breaks the Agent Skills pattern or differs from its folder, when the check runs, then it fails · test: `ops/test-kit.sh::skills check refuses a bad name`
- Given a skill with no description or one of 1,025 characters, when the check runs, then it fails · test: `ops/test-kit.sh::skills check refuses a bad description`
- Given a skill folder without its link in .claude/skills, or a link there that points nowhere, when the check runs, then it fails · test: `ops/test-kit.sh::skills check refuses a missing or dangling link`
- Given a copied skill (one with SOURCE) without LICENSE, without a 40-hex commit, with an executable file or with a hooks key, when the check runs, then it fails once for each · test: `ops/test-kit.sh::skills check refuses an unvetted copy`
- Given an adopter's own skill without SOURCE that ships a script, when the check runs, then it passes · test: `ops/test-kit.sh::skills check allows an adopter script`
- Given frontmatter the check cannot read, when the check runs, then it fails as unreadable instead of passing · test: `ops/test-kit.sh::skills check refuses unreadable frontmatter`
- Given the template, when the kit-debug folder is renamed, then the check fails on the path in AGENTS.md rule 3 · test: `ops/test-kit.sh::skills rule 3 path is checked`
- Given an adopter on an earlier kit with a skill of its own, when install.sh runs, then every kit- skill folder and its link are written, the adopter's skill is byte-unchanged, and a second run writes nothing · test: `ops/test-kit.sh::install skills`
- Given a real directory where a kit skill's link belongs, when install.sh runs, then it is left alone and reported · test: `ops/test-kit.sh::install skills keep a real directory`

## Tasks
- [ ] Branch `add-skills` from `main` in a separate worktree (the check is a gate file)
- [ ] `kit-debug`: systematic-debugging from obra/superpowers at 8ca22db; four files, LICENSE, SOURCE
- [ ] `kit-debug` edits, recorded in SOURCE: the name and four references (proposal, section 4.1)
- [ ] `kit-explore`: grill-me's frontmatter and `agents/openai.yaml` with grilling's body, from mattpocock/skills at b0618bc; LICENSE, SOURCE
- [ ] Relative links in `.claude/skills/`, one per skill
- [ ] `check_skills` in `ops/check-agent-kit.sh` (proposal, section 4.2)
- [ ] `install.sh`: owns every `kit-` skill folder and its link; a real directory reported
- [ ] `ops/test-kit.sh`: the skills and install cases above; break each rule once
- [ ] AGENTS.md rule 3 points at `.agents/skills/kit-debug/SKILL.md`
- [ ] PRD §3 non-goals and R20; README tables; CHANGELOG; DECISIONS; STATUS
- [ ] Maintainer: pickup test in Claude Code (`/skills`) and Zed (trusted worktree); README

## Out of scope
- The LSP plugins, the ast-grep skills and Ponytail (proposal, section 2)
- A "smallest complete change" clause and the Phase 2 measurement (maintainer, 2026-10-09)
- The OpenSpec-style commands; they come next, as `kit-propose`, `kit-apply` and `kit-archive`
- A briefing shown at session start; it is a change of its own
- Removing a kit skill from adopters, or letting an adopter opt out of one
- Windows, where git symlinks need extra setup; the kit does not support Windows yet

## Evidence
- verification: <verified | partial | failed> — command: `./ops/verify.sh` and `./ops/test-kit.sh` — at: <date>, <commit>
- last lines: <the last lines of both commands>
- mutation check: <each broken rule fails at least one skills case>

## Design
- Names: `kit-` plus the step of the change flow (`kit-explore` now; `kit-propose`, `kit-apply`,
  `kit-archive` later) and `kit-debug` for a fix inside apply (maintainer, 2026-10-09). Claude Code
  lets a project skill replace a built-in command of the same name, and `/plan`, `/design`,
  `/review`, `/verify` and `/debug` are built-ins; the prefix rules out such a clash for good and
  marks the folders the kit owns. Rejected: bare verbs (`/explore`, `/fix`: a later built-in of
  that name would be replaced, and adopters could not have their own); classic stage names
  (`/discover`, `/define`, `/build`, `/ship`: they rename the planned flow, and the obvious ones are
  taken); the upstream names (not actions, not tied to a step).
- `kit-explore` is one skill: grill-me's frontmatter (`disable-model-invocation: true`) with
  grilling's body. Nothing of it loads at session start and it never starts on its own; it runs
  when the user types `/kit-explore` (maintainer, 2026-10-09). Rejected: the upstream pair, whose
  model-invoked half keeps a description loaded and can start unprompted.
- Layout: the files live in `.agents/skills/<name>/`; `.claude/skills/<name>` is a relative symlink
  to them. Claude Code reads only `.claude/skills/` and documents symlinked skill folders; Zed and
  Codex read only `.agents/skills/`; Copilot, Cursor and Gemini CLI read it too. Rejected: copies in
  both folders (they drift, and Copilot and Cursor would list two skills); one link for the whole
  folder (no tool documents it, and it collides with an adopter's own `.claude/skills/`);
  `.claude/skills/` alone (Zed would not see the skills).
- Provenance: a copied folder keeps the upstream bytes except recorded edits (here: the names, the
  merge and four references), plus `LICENSE` (the upstream text with its copyright line; MIT
  requires it in copies) and `SOURCE` (`url:`, `path:`, `commit:`, `license:`, one `changed:` line
  per edit). Updating a skill is a new copy at a new pin, reviewed as a diff. Rejected: provenance
  in frontmatter `metadata` (it edits upstream bytes, and Codex and Gemini CLI ignore the field).
- The check: only copied skills must be text without hooks, so an adopter's own skill may ship a
  script. Python's standard library has no YAML parser; a small reader takes plain, quoted and
  block-scalar values and fails the rest as unreadable.
- Custody: `install.sh` owns every `.agents/skills/kit-*` folder and its link, so there is no list
  to keep; adopters name their own skills without the prefix. A missing link is created; a real
  directory in its place is reported and never replaced. Known limit: a kit skill an adopter
  deleted returns on the next update.
- Skills stay code for the gate (not in `ops/agent/non-code-paths.txt`): an edit runs the check,
  and a skill change goes through a pull request the maintainer merges, never a records one. Why:
  skills steer later sessions as learnings do, and learnings need a human's acceptance (PRD R9).
  Zed's agent likewise cannot edit a SKILL.md without the user's authorization.
- AGENTS.md: rule 3 points at `kit-debug`, still seven rules. An independent test saw a skill start
  itself 0 times in 10 sessions; the path also works in tools that read files but not skills, and
  `check_stale_references` keeps it current.
- Risks: VS Code lists each skill twice, and Cursor does not document duplicates. Gemini CLI
  ignores `disable-model-invocation` and has no skill commands, so there `kit-explore` starts only
  when the model picks it. Claude Code's pickup through a link is documented, not yet tested here.
- Sequencing: before the OpenSpec-style flow (maintainer, 2026-10-09; replaces the order decided on
  2026-10-08). The flow's commands then ship as `kit-` skills in this folder with
  `disable-model-invocation`, which answers its open question about a prompt form for other tools.

## Spec delta
spec: docs/agent/specs/skills.md
### ADDED
- SKILLS-1: Each kit skill sits in its own folder directly under `.agents/skills/`, named with the `kit-` prefix, with a relative link of the same name in `.claude/skills/` · test: `ops/test-kit.sh::skills template passes`
- SKILLS-2: The check fails a SKILL.md nested below a skill folder · test: `ops/test-kit.sh::skills check refuses a nested skill`
- SKILLS-3: The check fails a skill whose name breaks the Agent Skills pattern or differs from its folder, or whose description is missing or longer than 1,024 characters · test: `ops/test-kit.sh::skills check refuses a bad name`
- SKILLS-4: The check fails a skill folder without its link in `.claude/skills/` and any link there that points nowhere · test: `ops/test-kit.sh::skills check refuses a missing or dangling link`
- SKILLS-5: A copied skill carries SOURCE with a URL, a 40-hex commit and a licence, plus the upstream LICENSE, and has no executable file and no frontmatter key outside name, description, license, metadata, compatibility, disable-model-invocation, user-invocable and argument-hint · test: `ops/test-kit.sh::skills check refuses an unvetted copy`
- SKILLS-6: The check fails frontmatter it cannot read · test: `ops/test-kit.sh::skills check refuses unreadable frontmatter`
- SKILLS-7: install.sh writes every `kit-` skill folder and its link, never writes another skill folder, and reports a real directory where a link belongs · test: `ops/test-kit.sh::install skills`
