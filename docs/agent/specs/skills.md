# skills spec
<!-- Living spec created by docs/agent/changes/archive/2026-10-09-add-skills.md; see docs/agent/specs/_template.md. -->

## Requirements
- SKILLS-1: Each kit skill sits in its own folder directly under `.agents/skills/`, named with the `kit-` prefix, with a relative link of the same name in `.claude/skills/` · test: `ops/test-kit.sh::skills template passes`
- SKILLS-2: The check fails a SKILL.md nested below a skill folder · test: `ops/test-kit.sh::skills check refuses a nested skill`
- SKILLS-3: The check fails a skill whose name breaks the Agent Skills pattern or differs from its folder, or whose description is missing or longer than 1,024 characters · test: `ops/test-kit.sh::skills check refuses a bad name`
- SKILLS-4: The check fails a skill folder without its link in `.claude/skills/` and any link there that points nowhere · test: `ops/test-kit.sh::skills check refuses a missing or dangling link`
- SKILLS-5: A copied skill carries SOURCE with a URL, a 40-hex commit and a licence, plus the upstream LICENSE, and has no executable file and no frontmatter key outside name, description, license, metadata, compatibility, disable-model-invocation, user-invocable and argument-hint · test: `ops/test-kit.sh::skills check refuses an unvetted copy`
- SKILLS-6: The check fails frontmatter it cannot read · test: `ops/test-kit.sh::skills check refuses unreadable frontmatter`
- SKILLS-7: install.sh writes every `kit-` skill folder and its link, never writes another skill folder, and reports a real directory where a link belongs · test: `ops/test-kit.sh::install skills`
