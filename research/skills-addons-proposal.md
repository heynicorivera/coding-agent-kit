# Skill add-ons: verification and implementation plan

> **Status: proposal, 2026-10-09.** Phase 1 (verify) of `research/skills-addons-delegation-brief.md`
> is done; Phase 2 (measure) was not run (section 5). Nothing is built. The maintainer answered the
> three choices (section 6); the plan continues as the T2 change file
> `docs/agent/changes/add-skills.md`. Figures are marked **ours** (computed in this session from the
> pinned files), **third party** or **vendor claim**.

## 1. Summary

**Bad news first**
- Three of the five candidates fail verification:
  - The LSP plugins are not files the kit can copy, work in Claude Code only, need language
    servers that are not installed here, and have an open bug: they install without any LSP
    configuration (claude-plugins-official #379, reported again for v2.1.288 on 2026-10-06).
  - `ast-grep/agent-skill` has no LICENSE file. Its `outline` skill is named `ast-grep-outline` in
    a folder named `outline`, so tools that require a match skip it. Both skills need the
    `ast-grep` binary (0.44 or newer for `outline`), which is not installed here.
  - Ponytail's author refuses a condensed version (#685, closed as not planned). The cheap "one
    sentence" measured in #685 asked the agent to leave a runnable check, which the kit already
    requires, and it was not significantly cheaper than no prompt (third party: −5.8 %, 95 % CI
    −11.7 % to +1.1 %). `ponytail-review` leans on the main skill's comment convention and
    overlaps Claude Code's bundled `/code-review` and `/simplify`.
- No single folder reaches every tool. Claude Code reads only `.claude/skills/`; Zed and Codex read
  only `.agents/skills/`.
- The exploration summary has errors, among them a cited page that does not contain the 500-task
  Superpowers figures (section 7).
- This widens the kit's scope. PRD §3 lists per-tool skills and "making the agent correct" as
  non-goals; both need revising, with a DECISIONS entry.

**Good news**
- Superpowers `systematic-debugging` (MIT) fills the kit's one gap, a debugging method. It adds a
  91-character description at session start (ours). It needs 4 of its 11 files (22 of 41 KB) and
  four edited references.
- Pocock `grill-me` and `grilling` (MIT) are text only and add about 200 characters at session start
  (ours). They are the body of the planned explore step and usable now as `/grill-me`.
- One layout serves both daily tools: the files in `.agents/skills/<name>/` (Zed, Codex, Copilot,
  Cursor and Gemini CLI read it) and one symlink per skill in `.claude/skills/`, which Claude Code
  documents ("a `<skill-name>` entry … can be a symlink to a directory elsewhere on disk").
- Every check the plan adds is deterministic and catches a failure seen in these repositories: a
  name that does not match its folder, an executable script, a missing licence.

## 2. Keep or drop

| # | Candidate | Verdict | Deciding facts |
|---|---|---|---|
| 1 | `typescript-lsp`, `pyright-lsp` | Drop from the kit | Plugin folders hold only README and LICENSE; the config sits in the marketplace file; #379 open; binaries missing; Claude Code only. Try them in the TypeScript application's onboarding once #379 is fixed |
| 2 | Ponytail line + `ponytail-review` | Drop | Upstream refuses a condensed version; the measured sentence is one the kit already has; the review skill overlaps bundled skills and has no independent data |
| 3 | `systematic-debugging` | Keep, adapted | MIT; 91-character description; text only once trimmed; dangling references fixed in four places |
| 4 | `ast-grep`, `outline` | Drop for now | No LICENSE file; name mismatch; a new binary dependency. Revisit if upstream adds a licence |
| 5 | `grill-me`, `grilling` | Keep | MIT; text only; `grilling` is model-invoked, so its 152-character description is always loaded |

## 3. Verified facts

### 3.1 Candidates at their pinned commits (full SHAs in section 8)
| Candidate | Repository @ commit (date) | Licence | Description, characters | Runs code or needs |
|---|---|---|---|---|
| LSP plugins | anthropics/claude-plugins-official @ 315c4e4 (2026-10-08) | Apache-2.0 | n/a | `typescript-language-server`, `pyright-langserver` |
| Ponytail | DietrichGebert/ponytail @ 9cc65d0, v5.1.0 (2026-10-08) | MIT | review: 370 (ours) | Node hooks at SessionStart, SubagentStart, UserPromptSubmit |
| systematic-debugging | obra/superpowers @ 8ca22db, v6.4.2 (2026-09-25) | MIT | 91 (ours) | `find-polluter.sh` (executable, runs `npm test`) |
| ast-grep skills | ast-grep/agent-skill @ f2175af (2026-09-13) | none; MIT claimed in README prose | 425 and 165 (ours) | `ast-grep` 0.44 or newer |
| grill-me, grilling | mattpocock/skills @ b0618bc (2026-10-08) | MIT | 51 and 152 (ours) | nothing |

### 3.2 Where each tool looks for project skills
| Tool | Folder it reads | Symlinked skill folder | `/name`; `disable-model-invocation` |
|---|---|---|---|
| Claude Code (2.1.220 installed) | `.claude/skills/`, also in parent folders up to the repository root | Documented | Yes; honoured |
| Zed (1.23.2 installed) | `<worktree>/.agents/skills/`, one level, trusted worktrees only | Not documented for project skills | Yes; honoured |
| Codex CLI | `.agents/skills` from the working directory up to the root | Documented | `/skills` or `$`; policy in `agents/openai.yaml` instead |
| Copilot (VS Code, CLI, cloud agent) | `.github/skills/`, `.agents/skills/`, `.claude/skills/` | Not documented | VS Code and CLI yes; cloud agent model only |
| Cursor | `.agents/skills/`, `.cursor/skills/`, `.claude/skills/`, `.codex/skills/`, recursive | Not documented | Yes; honoured |
| Gemini CLI | `.gemini/skills/` or `.agents/skills/`, one level, trusted folders | `gemini skills link` | Model only; flag ignored |

Shared rules (agentskills.io specification): `name` has 1-64 characters, lowercase letters, digits
and single hyphens, and equals its folder; `description` has 1-1024 characters. Tools load the name
and description at session start and the body on use. With the symlink, VS Code lists a skill
twice, Copilot CLI keeps the first one found (`.agents` before `.claude`), and Cursor does not say.

## 4. Implementation plan (T2)

### 4.1 Layout and provenance
- Files live in `.agents/skills/<name>/`; `.claude/skills/<name>` is a relative symlink to
  `../../.agents/skills/<name>`. Rejected: copies in both folders (they drift, and Copilot and
  Cursor would see two skills); one symlink for the whole folder (no tool documents it, and it
  collides with an adopter's own `.claude/skills/`).
- A copied skill keeps the upstream bytes except recorded edits and adds two files: `LICENSE`, the
  upstream text with its copyright line (MIT requires it in copies), and `SOURCE`, with `url:`,
  `path:`, `commit:` (40 hex digits), `license:` (SPDX id) and one `changed:` line per edit.
- `systematic-debugging` keeps `SKILL.md`, `root-cause-tracing.md`, `defense-in-depth.md` and
  `condition-based-waiting.md`. It drops the test fixtures, the creation log, the TypeScript example
  (its imports do not resolve) and `find-polluter.sh`. Edits: `SKILL.md:177` points at AGENTS.md
  rule 3 instead of `superpowers:test-driven-development`; `SKILL.md:189` at `./ops/verify.sh`
  instead of `superpowers:verification-before-completion`; `root-cause-tracing.md:101-104`
  describes the bisection without the script; `condition-based-waiting.md:82` drops the reference
  to the example.
- `grill-me` and `grilling` are copied unchanged, with their `agents/openai.yaml` (Codex reads the
  invocation policy there).

### 4.2 The check: `check_skills` in `ops/check-agent-kit.sh`
1. Every `SKILL.md` under `.agents/skills/` sits at `<name>/SKILL.md`: Zed and Gemini CLI do not
   find nested skills.
2. The frontmatter has `name` and `description`; `name` follows the specification and equals its
   folder. VS Code: invalid names "cause the skill to silently fail to load".
3. `description` has 1-1024 characters.
4. `.claude/skills/<name>` exists and resolves to `.agents/skills/<name>`, and no symlink under
   `.claude/skills/` dangles; otherwise Claude Code does not see the skill.
5. A folder with `SOURCE` is a copied skill: `SOURCE` names a URL, a 40-hex commit and a licence;
   `LICENSE` exists; no file is executable; frontmatter keys come only from `name`, `description`,
   `license`, `metadata`, `compatibility`, `disable-model-invocation`, `user-invocable` and
   `argument-hint`. Claude Code skills can carry `hooks` and `allowed-tools`, which would bypass the
   kit's hook and permission files.

Adopter skills without `SOURCE` get rules 1-4 only. Python's standard library has no YAML parser:
the check reads plain, quoted and block-scalar (`>`, `|`) values and fails anything else as
unreadable. Ponytail writes its descriptions as block scalars.

### 4.3 `install.sh`
- A `KIT_SKILLS` list names the kit's skills. Their files are kit-owned (overwritten); the
  `.claude/skills/<name>` link is created when missing; a real directory in its place is reported
  and left alone. Other skill folders are never touched.
- Known limit: a kit skill an adopter deleted comes back on the next update, as other kit-owned
  files do.

### 4.4 `AGENTS.md` (template; adopters copy the clause, as with the records rule)
- Rule 3's fix clause becomes: "a fix starts from the root cause
  (`.agents/skills/systematic-debugging/SKILL.md`) and needs a test that failed before it". Still
  seven rules; `check_stale_references` keeps the path honest. The pointer is explicit because
  JetBrains saw Ponytail activate itself 0 times in 10 sessions (third party), and it works in tools
  without skill support, which can read the file directly.

### 4.5 Tests: a `== skills ==` section in `ops/test-kit.sh`
- The check passes on the template and fails once per rule in 4.2: a nested skill, a bad name, a
  name unlike its folder, a 1,025-character description, a missing link, a dangling link, a copied
  skill without `LICENSE`, a `SOURCE` without a commit, an executable file, a `hooks` key,
  unreadable frontmatter.
- `install.sh` writes the kit's skills and links, leaves an adopter's skill alone, writes nothing on
  a second run, and reports a real directory where a link belongs.
- Before closing: break each rule once and see a case fail, as for `install.sh`.

### 4.6 Records
PRD §3 non-goals and a new R20; README (files, update and tool tables); CHANGELOG; DECISIONS (skills
before the OpenSpec flow, the non-goals, the layout, provenance). The change's Spec delta creates
`docs/agent/specs/skills.md`, the kit's first living spec.

### 4.7 Order of work
1. Me: the change file `docs/agent/changes/skills.md` (T2), from the answers to section 6.
   You: "approved" or edits.
2. Me: build on a `skills` branch in a separate worktree (the check is a gate file; DECISIONS
   2026-10-06); `./ops/verify.sh` and `./ops/test-kit.sh` pass; pull request. You: merge.
3. You: pickup test. Claude Code's `/skills` lists `systematic-debugging`; Zed offers
   `/systematic-debugging` in a trusted worktree. Me: README records both as tested locally.
4. Then the OpenSpec flow can ship its commands as skills in the same folder, with
   `disable-model-invocation` and `/grill-me` as the explore step. That answers its open question
   about a prompt form for tools other than Claude Code.

## 5. Measurement (brief Phase 2): not recommended now
- Five to ten paired tasks cannot show effects of the size measured elsewhere. JetBrains needed 80
  pairs to show −10.3 % cost (p = 0.004), and its −15.4 % code was not significant at 80 pairs
  (p = 0.088) (third party).
- Instead: the checks and the self-test, the pickup test, and a note in STATUS.md of whether the
  agent loads `systematic-debugging` on the next real fixes (the 2.2 fixes are T1 fixes). README
  makes no efficiency claim.

## 6. Choices (answered by the maintainer, 2026-10-09)
1. `grill-me` and `grilling` ship in this change. Neither runs at session start, which stays the
   STATUS.md briefing. `grill-me` is user-only: Claude Code keeps its description out of context and
   Zed hides it from the catalog. `grilling` is model-invoked, so its description is loaded, and it
   may start on its own when the user asks to stress-test a plan. If it ever starts unprompted, fold
   `grilling` into `grill-me` as one user-only skill, recorded as an edit in `SOURCE`.
2. No "smallest complete change" clause: no one-line version has been measured, and each always-on
   constraint dilutes the others (PRD §1). An adopter can add one to its own AGENTS.md.
3. No Phase 2 measurement (section 5).
4. Names follow the change flow with a `kit-` prefix: `kit-explore` (grill-me and grilling merged
   into one user-only skill) and `kit-debug` (systematic-debugging). Claude Code lets a project
   skill replace a built-in command of the same name, and `/plan`, `/design`, `/review`, `/verify`
   and `/debug` are built-ins. Point 1 above is superseded: nothing of `kit-explore` loads at
   session start, and it never starts on its own.

## 7. Corrections to the exploration summary
| Exploration claim | What the sources say |
|---|---|
| Ponytail's measured saving is "about a fifth" of the advertised one (−10.3 % cost vs −54 %) | −54 % was code, not cost. Like for like, JetBrains lists −20 % cost advertised and −10.3 % measured: about half |
| Full Superpowers: 500 tasks, 1.56M to 2.18M tokens, 228 vs 239 solved (cited to mejba.me) | The cited page has none of these figures. It reports 12 sessions of its own on v6.3.0, "roughly 9% cheaper and about 14% fewer tokens". The figures are attributed to two other posts that returned HTTP 403: unverified |
| #685: the full Ponytail plugin cost more than "a one-sentence prompt" | Correct, but the sentence asked the agent to leave a runnable check, not to keep changes small |
| `grill-me` + `grilling`: about 0 always-on cost | Only `grill-me` disables model invocation; `grilling`'s description is always loaded |
| Superpowers bootstrap skill: 63 lines, 3.04 KB | That is v6.3.0; v6.4.2 has 65 lines, 3,192 bytes |
| LSP: check the registration bug, issue 16291, after install | 16291 was closed as stale, not fixed; #379 (open) says the LSP plugins install with no LSP configuration |
| ast-grep and Pocock licences not read | Pocock: MIT. ast-grep/agent-skill: no LICENSE file at all |

## 8. References
- Pins: anthropics/claude-plugins-official 315c4e48967d9541c29c3c656441dded353ca7aa;
  DietrichGebert/ponytail 9cc65d03aa2da1db7121b912d03596409ee340b8 (v5.1.0);
  obra/superpowers 8ca22dba9a94f28898bbce59f2537ff4d87c747d (v6.4.2);
  ast-grep/agent-skill f2175aff21f20cfb8e2db30c28febeb3a2d42b61;
  mattpocock/skills b0618bc436ad893b3c5e84e55fba86586d34a404
- Issues: https://github.com/anthropics/claude-plugins-official/issues/379 ;
  https://github.com/anthropics/claude-code/issues/16291 ;
  https://github.com/DietrichGebert/ponytail/issues/685
- Third-party tests: https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/ ;
  https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/ ;
  https://www.mejba.me/blog/superpowers-plugin-claude-code-review
- Tool documentation: https://code.claude.com/docs/en/skills ;
  https://code.claude.com/docs/en/plugins/code-intelligence ; https://zed.dev/docs/ai/skills ;
  https://learn.chatgpt.com/docs/build-skills ;
  https://code.visualstudio.com/docs/agent-customization/agent-skills ;
  https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference ;
  https://cursor.com/docs/context/skills ; https://geminicli.com/docs/cli/skills/
- Specification: https://agentskills.io/specification
