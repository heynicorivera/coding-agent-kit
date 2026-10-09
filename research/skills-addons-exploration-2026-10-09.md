# Skill add-ons for the kit: exploration summary

> **Status: feature request, exploration phase.** Nothing here is decided, planned or built. It is
> not in `ROADMAP.md`, and neither `README.md` nor `AGENTS.md` promise any of it. Figures below come
> from third-party sources, most of them vendor claims; the measured ones are marked. Date:
> 2026-10-09. Delegation brief: `research/skills-addons-delegation-brief.md`.
> Verified the same day in `research/skills-addons-proposal.md`; its section 7 corrects figures here.

## 1. Summary

**Request.** Find the 3-5 most complementary skills for the kit that help it deliver efficient
code fast with few tokens. Candidates named by the maintainer: ponytail, superpowers.

**Bad news first**

| Finding | Evidence |
|---|---|
| Ponytail's measured saving is about a fifth of its advertised one | JetBrains: -10.3 % cost (80 paired tasks) vs the advertised -54 % |
| The full Ponytail plugin cost more than a one-sentence prompt | Project issue #685: +6.9 % cost, about 2.8k-token SessionStart injection |
| The full Superpowers plugin raised token use with no significant accuracy gain | Independent test, Codex, 500 tasks: 1.56M to 2.18M tokens per task; 228 vs 239 solved |
| Most "token saver" tools do not hold up when measured | RTK +7.6 % cost; caveman -8.5 % output tokens vs -65 % advertised |
| Models did not pick up installed skills on their own | JetBrains: 0 self-activations in 10 sessions |
| No independent measurement exists for the shortlisted pieces below | LSP plugins, ast-grep skills, Pocock skills, Superpowers v6.1+ |

**What the kit already covers** (read from the repository, 2026-10-09): ranked 7-rule AGENTS.md;
SessionStart injection of STATUS.md and active learnings; a Stop gate running `ops/verify.sh`;
T0/T1/T2 change tiers with change files; append-only DECISIONS.md; living specs; `install.sh`
for adopters. It ships no skills directory. Its PRD lists as non-goals: a repo index, a specs/plans
tree beyond its own, per-tool skills, subagent frameworks, LLM-judged checks, a framework CLI
dependency. `ROADMAP.md` already plans an OpenSpec-style flow as commands (explore, propose,
review, apply, archive).

**Candidate shortlist (proposal, not a decision)**

| # | Candidate | Role | Always-on cost | Independent evidence |
|---|---|---|---|---|
| 1 | Official `typescript-lsp` / `pyright-lsp` plugins, per project | Symbol navigation and post-edit type errors | Tool definitions only | None found for tokens |
| 2 | Ponytail reduced to one rule line plus `ponytail-review` skill | Stops over-building | About 1 rule line | JetBrains -10.3 % cost (full ruleset) |
| 3 | Superpowers `systematic-debugging`, copied in alone | Root-cause method; the kit has none | One description line | None for this skill |
| 4 | ast-grep `ast-grep` + `outline` skills | Structural search and cheap code outline across 20+ languages | Two description lines | None |
| 5 | Optional: Pocock `grill-me` + `grilling` | Body of the planned explore step, writes nothing | About 0 (model invocation disabled) | None |

**Not recommended:** full Superpowers or full Ponytail plugin, RTK, caveman, Serena (for now),
code-simplifier on autopilot, bulk installs from awesome lists.

## 2. Observed facts and comparisons

### 2.1 Ponytail (github.com/DietrichGebert/ponytail)
- MIT; created 2026-06-12; Ponytail 5 merged 2026-10-08 (PR #1061).
- One main SKILL.md plus five companions: review, audit, debt, gain, help.
- In Claude Code and Codex it runs Node lifecycle hooks (SessionStart, SubagentStart,
  UserPromptSubmit). The kit requires only bash, git and python3.

| Source | Setup | Code | Cost | Note |
|---|---|---|---|---|
| Ponytail 5 README (vendor) | Opus 5.5, 39 tasks x 5 | -53 % | -26 % | Vendor claim |
| JetBrains (independent) | Sonnet 5, 80 paired tasks, v4.8.4 | -15.4 % (p=0.088) | -10.3 % (p=0.004) | Cheaper on 46 tasks, dearer on 34 |
| Issue #685 (independent A/B) | Sonnet 5, vs one-sentence prompt | n/a | +6.9 % | Output tokens -12 % |

### 2.2 Superpowers (github.com/obra/superpowers, v6.4.2, 2026-09-25)
- MIT; 15 skills. Overlap with the kit:

| Superpowers skill | Kit mechanism |
|---|---|
| brainstorming, writing-plans | T1/T2 change files; planned propose command |
| test-driven-development | T1 rule: a fix needs a test that failed first |
| verification-before-completion | Stop gate running `ops/verify.sh` |
| using-git-worktrees, finishing-a-development-branch | Planned branch and archive commands |
| systematic-debugging | none (gap) |

- Writes to `docs/superpowers/specs/` and `docs/superpowers/plans/`, a second tree beside
  `docs/agent/specs/`.
- Bootstrap skill is 63 lines / 3.04 KB (about 750 tokens, estimated, not tokenizer-measured).
- Largest independent test (500 tasks, Codex, probably v5.x): +625k tokens per task, +74 s per
  task, accuracy 45.6 % vs 47.8 % (not significant).

### 2.3 Other tools measured by third parties
| Tool | Result |
|---|---|
| RTK (Bash-command rewriting proxy) | +7.6 % median cost at low effort, +0.1 % at high effort (JetBrains, 86 tasks) |
| caveman (terseness prompt) | -8.5 % output tokens vs -65 % advertised |
| Serena (MCP, symbol retrieval) | Anecdotal "up to 70 %" only; Python/uv; writes memories automatically |
| code-simplifier (official, Opus) | Runs proactively on recent changes; overlaps ponytail-review |

### 2.4 Portability
- Zed Stable 1.4.2 (2026-05-27) reads `<project>/.agents/skills/<name>/SKILL.md`, flat scan, no
  recursion. Claude Code reads `.claude/skills/`. One tree under `.agents/skills/` could serve both.
- LSP plugins are Claude Code only. ast-grep and Pocock skills are plain SKILL.md.

## 3. Proposed approach (not agreed)
1. Create `.agents/skills/` as the one skill tree; `install.sh` links or copies it to `.claude/skills/`.
2. Copy skills in, never install plugins; keep a `SOURCE` file (URL, commit, licence) per skill.
3. Add deterministic checks to the kit check: name matches folder, description length cap, SOURCE
   present, no `hooks/` directory inside a skill.
4. Fold "smallest complete change" into an existing AGENTS.md rule; stay at 7 rules or fewer.
5. Call skills from the planned commands explicitly (explore, apply on a bug, review).
6. Enable LSP plugins per project, not in the template.
7. Measure each addition on 5-10 own T1 tasks, with and without; keep only what wins.

## 4. Unverified or open
- Licences of `ast-grep/agent-skill` and Pocock's skills not read from their LICENSE files; RTK and
  Serena have conflicting licence reports.
- Whether the Ponytail 5 rewrite (about half as long) removed the overhead found in #685.
- Token savings of LSP plugins, ast-grep skills and Pocock skills: no independent data.
- Superpowers `systematic-debugging` cross-references `superpowers:` skills that dangle when
  copied alone (inference, not tested).
- Zed's Agent Skills behaviour was taken from documentation and a news summary, not run.
- Claude Code LSP plugin registration bug (anthropics/claude-code issue 16291, January 2026): check
  after install.
- Fit with ROADMAP "Next" (OpenSpec-style flow): the skills would be called from those commands, so
  sequencing is open.

## 5. References
- Ponytail: https://github.com/DietrichGebert/ponytail ; PR 1061 ; issue 685 (…/issues/685)
- JetBrains Ponytail test: https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/
- JetBrains RTK test: https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/
- Superpowers: https://github.com/obra/superpowers ; releases:
  https://github.com/obra/superpowers/releases ; v6.4 notes: https://blog.fsck.com/2026/09/21/superpowers-6.4/
- Superpowers token test write-up (Mejba): https://www.mejba.me/blog/superpowers-plugin-claude-code-review
- Official plugins (LSP, code-simplifier): https://github.com/anthropics/claude-plugins-official
- LSP registration bug: https://github.com/anthropics/claude-code/issues/16291
- ast-grep skills: https://github.com/ast-grep/agent-skill
- Serena: https://github.com/oraios/serena
- Pocock skills: https://github.com/mattpocock/skills (grill-me, grilling)
- Zed Agent Skills: https://github.com/zed-industries/zed/discussions/46936
- MCP tool search: https://code.claude.com/docs/en/agent-sdk/tool-search
