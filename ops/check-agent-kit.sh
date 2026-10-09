#!/usr/bin/env bash
# Checks the agent kit's own rules. Local: ./ops/check-agent-kit.sh
# CI: ./ops/check-agent-kit.sh --range <base>..HEAD   (adds append-only and freshness rules)
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
problem() { echo "FAIL: $*"; fail=1; }
range="${AGENT_KIT_RANGE:-}"
[ "${1:-}" = "--range" ] && range="${2:-}"
if [ -n "$range" ] && ! git rev-parse --verify -q "${range%%..*}^{commit}" >/dev/null 2>&1; then
  echo "NOTE: ${range%%..*} is not a commit here (the first push of a branch?); range rules skipped."
  range=""
fi

template_state() { [ -f AGENTS.md ] && grep -q '<one sentence: what this software does and for whom>' AGENTS.md; }

check_python() {
  command -v python3 >/dev/null 2>&1 \
    || problem "python3 is required by the hooks and this check. Install it from https://www.python.org/downloads/ or your package manager."
  return 0
}

check_agents_md() {
  [ -f AGENTS.md ] || { problem "AGENTS.md is missing."; return; }
  local lines chars rules total=0 f
  lines=$(wc -l < AGENTS.md | tr -d ' '); chars=$(wc -c < AGENTS.md | tr -d ' ')
  [ "$lines" -le 100 ] || problem "AGENTS.md has $lines lines; cap 100. Move detail into docs/ or a check."
  [ "$chars" -le 12000 ] || problem "AGENTS.md has $chars chars; Devin caps rule files at 12,000."
  rules=$(awk '/^## Rules/{p=1;next} /^## /{p=0} p && /^[0-9]+\. /' AGENTS.md | wc -l | tr -d ' ')
  [ "$rules" -le 7 ] || problem "AGENTS.md lists $rules rules; cap 7. Turn one into a check or drop it."
  if grep -nE '(^|[[:space:]])@[A-Za-z0-9_./~-]+' AGENTS.md | grep -v '`'; then
    problem "AGENTS.md uses an @path include (lines above); only some tools expand them."
  fi
  for f in AGENTS.md CLAUDE.md; do [ -f "$f" ] && total=$((total + $(wc -c < "$f"))); done
  [ "$total" -le 32768 ] || problem "AGENTS.md + CLAUDE.md are $total bytes; Codex stops adding at 32 KiB."
  return 0
}

check_memory_files() {
  local f lines
  for f in docs/agent/STATUS.md docs/agent/DECISIONS.md docs/agent/LEARNINGS.md; do
    [ -s "$f" ] || problem "$f is missing or empty. Restore it from the starter kit."
  done
  if [ -f docs/agent/STATUS.md ]; then
    lines=$(wc -l < docs/agent/STATUS.md | tr -d ' ')
    [ "$lines" -le 60 ] || problem "STATUS.md has $lines lines; cap 60. It is injected into every session."
    grep -qE '^verification: (none|verified|partial|failed)' docs/agent/STATUS.md \
      || problem "STATUS.md needs a line 'verification: none|verified|partial|failed — command … — at …'."
  fi
  if [ -f docs/agent/LEARNINGS.md ]; then
    lines=$(wc -l < docs/agent/LEARNINGS.md | tr -d ' ')
    [ "$lines" -le 100 ] || problem "LEARNINGS.md has $lines lines; cap 100. Archive or convert entries."
    if awk '/^## Active/{p=1;next} /^## /{p=0} p && /^- /' docs/agent/LEARNINGS.md | grep -vq 'evidence:'; then
      problem "Every active learning needs an 'evidence:' field (commit, test or PR)."
    fi
  fi
  return 0
}

check_pointer_files() {
  local f
  if [ -f CLAUDE.md ] && ! grep -qx '@AGENTS.md' CLAUDE.md; then
    problem "CLAUDE.md has no '@AGENTS.md' line; Claude Code would not load AGENTS.md."
  fi
  if [ -f .gemini/settings.json ] && ! grep -q '"AGENTS.md"' .gemini/settings.json; then
    problem ".gemini/settings.json must list \"AGENTS.md\" under context.fileName."
  fi
  if [ -f .aider.conf.yml ] && ! grep -qE '^read:.*AGENTS\.md' .aider.conf.yml; then
    problem ".aider.conf.yml must load AGENTS.md through 'read:'."
  fi
  for f in .rules .cursorrules .windsurfrules .clinerules .github/copilot-instructions.md AGENT.md GEMINI.md; do
    [ -e "$f" ] && problem "$f is present; Zed would read it instead of AGENTS.md, or it duplicates AGENTS.md. Delete it."
  done
  return 0
}

check_hooks() {
  local f path
  for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json .github/hooks/*.json; do
    [ -f "$f" ] || continue
    python3 -m json.tool "$f" >/dev/null 2>&1 || problem "$f is not valid JSON."
    grep -q 'CLAUDE_PROJECT_DIR' "$f" && problem "$f uses CLAUDE_PROJECT_DIR; use \$(git rev-parse --show-toplevel) so Copilot CLI and VS Code can run the same hooks."
    while IFS= read -r path; do
      [ -z "$path" ] && continue
      [ -x "$path" ] || problem "$f points at $path, which is missing or not executable; the hook would be silently disabled."
    done < <(grep -oE 'ops/[A-Za-z0-9_./-]+' "$f" | sort -u)
  done
  if [ -f .codex/hooks.json ]; then
    python3 - <<'PY' || problem ".codex/hooks.json: SessionEnd timeout must be 3 seconds or less (Codex caps it)."
import json, sys
hooks = json.load(open('.codex/hooks.json')).get('hooks', {})
for group in hooks.get('SessionEnd', []):
    for hook in group.get('hooks', []):
        if hook.get('timeout', 1) > 3:
            sys.exit(1)
PY
  fi
  return 0
}

check_verify_script() {
  [ -x ops/verify.sh ] || { problem "ops/verify.sh is missing or not executable."; return; }
  if grep -q 'KIT-PLACEHOLDER' ops/verify.sh && ! template_state; then
    problem "ops/verify.sh still contains the KIT-PLACEHOLDER block; add your test and lint commands."
  fi
  return 0
}

check_gate_files() {
  [ -f ops/agent/non-code-paths.txt ] \
    || problem "ops/agent/non-code-paths.txt is missing; the stop gate would treat every path as code. Restore it from the starter kit."
  if [ -e .githooks/pre-commit ] && [ ! -x .githooks/pre-commit ]; then
    problem ".githooks/pre-commit is not executable, so git skips it. Run: chmod +x .githooks/pre-commit"
  fi
  local sidecar
  while IFS= read -r sidecar; do
    [ -n "$sidecar" ] || continue
    problem "$sidecar is the kit's copy from install.sh; merge it into ${sidecar%.kit-new}, then delete it."
  done < <(git ls-files --cached --others --exclude-standard -- '*.kit-new' 2>/dev/null)
  return 0
}

check_change_files() {  # change files and living specs; ops/agent/changes.py holds the rules
  local f base="${range%%..*}"
  for f in docs/agent/changes/_template.md docs/agent/specs/_template.md; do
    [ -f "$f" ] || problem "$f is missing. Restore it from the starter kit."
  done
  [ -n "$range" ] || base="$(git merge-base HEAD '@{upstream}' 2>/dev/null || git rev-parse --verify -q HEAD || true)"
  python3 ops/agent/changes.py check "$base" || fail=1
  return 0
}

check_skills() {  # Agent Skills in .agents/skills/<name>/, each linked from .claude/skills/<name>
  [ -d .agents/skills ] || [ -d .claude/skills ] || return 0
  python3 - <<'PY' || fail=1
import os, re, sys

ROOT, LINKS = ".agents/skills", ".claude/skills"
KEY = re.compile(r"([A-Za-z0-9_-]+):(?:[ \t]+(.*))?$")
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
COPY_KEYS = {"name", "description", "license", "metadata", "compatibility",
             "disable-model-invocation", "user-invocable", "argument-hint"}
failures = []


def fail(message):
    failures.append(message)
    print("FAIL: " + message)


class Unreadable(Exception):
    pass


def scalar(raw, block):  # the text of a value; None for a map, list, flow, anchor, alias or tag
    rows = [row.strip() for row in block if row.strip()]
    if re.fullmatch(r"[|>][-+0-9]*", raw):
        return ("\n" if raw[0] == "|" else " ").join(rows)
    if raw[:1] in ("'", '"'):
        if rows or len(raw) < 2 or raw[-1] != raw[0]:
            raise Unreadable("a quoted value does not close on its own line")
        return raw[1:-1]
    if raw[:1] in tuple("[{&*!%@`") or (not raw and rows):
        return None
    text = " ".join([raw] + rows).split(" #")[0].strip()
    if ": " in text:
        raise Unreadable("a plain value contains ': ', which YAML reads as a mapping; quote it")
    return text


def frontmatter(path):  # the top-level keys of a SKILL.md frontmatter
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().lstrip("\ufeff").splitlines()
    except (OSError, UnicodeError) as error:
        raise Unreadable(str(error))
    marks = [n for n, line in enumerate(lines) if line.rstrip() == "---"][:2]
    if marks[:1] != [0] or len(marks) < 2:
        raise Unreadable("it needs a '---' line before and after the frontmatter")
    fields, n = {}, 1
    while n < marks[1]:
        line, end = lines[n], n + 1
        if not line.strip() or line.startswith("#"):
            n = end
            continue
        match = KEY.match(line)
        if not match:
            raise Unreadable("line %d is not 'key: value'" % (n + 1))
        while end < marks[1] and lines[end][:1] in (" ", "\t", ""):
            end += 1
        key, block = match.group(1), lines[n + 1:end]
        if key in fields:
            raise Unreadable("'%s' appears twice" % key)
        if any("\t" in row[:len(row) - len(row.lstrip())] for row in block):
            raise Unreadable("a line under '%s' is indented with a tab" % key)
        fields[key] = scalar((match.group(2) or "").strip(), block)
        n = end
    return fields


def check_copy(base, fields):  # SOURCE marks third-party files: pinned, licensed, text only
    source = {}
    with open(os.path.join(base, "SOURCE"), encoding="utf-8", errors="replace") as handle:
        for line in handle:
            key, _, value = line.partition(":")
            source.setdefault(key.strip(), value.strip())
    if not source.get("url", "").startswith("https://"):
        fail("%s/SOURCE needs 'url: https://...' naming the upstream repository." % base)
    if not re.fullmatch(r"[0-9a-f]{40}", source.get("commit", "")):
        fail("%s/SOURCE needs 'commit:' with the full 40-hex upstream commit, so the copy is "
             "pinned." % base)
    if not source.get("license"):
        fail("%s/SOURCE needs 'license:' with the upstream licence's SPDX id." % base)
    if not os.path.isfile(os.path.join(base, "LICENSE")):
        fail("%s is a copied skill without LICENSE; copy the upstream licence text with its "
             "copyright line." % base)
    for folder, dirs, files in os.walk(base):
        dirs.sort()
        for path in sorted(os.path.join(folder, name) for name in files):
            if not os.path.islink(path) and os.stat(path).st_mode & 0o111:
                fail("%s is executable; a copied skill is text only. Run: chmod -x %s"
                     % (path, path))
    extra = sorted(set(fields) - COPY_KEYS)
    if extra:
        fail("%s/SKILL.md has the frontmatter key(s) %s; a copied skill may use only Agent Skills "
             "fields, so hooks or allowed-tools cannot bypass the kit's hook and permission files."
             % (base, ", ".join(extra)))


def check_skill(folder):
    base = os.path.join(ROOT, folder)
    path = os.path.join(base, "SKILL.md")
    try:
        fields = frontmatter(path)
    except Unreadable as error:
        fail("%s: the frontmatter is unreadable (%s)." % (path, error))
        return
    for key in ("name", "description"):
        if key in fields and fields[key] is None:
            fail("%s: '%s' is not a plain, quoted or block-scalar value." % (path, key))
            return
    name, description = fields.get("name", ""), fields.get("description", "")
    if len(name) > 64 or not NAME.fullmatch(name):
        fail("%s: name '%s' breaks the Agent Skills pattern: 1-64 lowercase letters, digits and "
             "single hyphens." % (path, name))
    elif name != folder:
        fail("%s: name '%s' differs from its folder '%s'; tools skip such a skill."
             % (path, name, folder))
    if not 1 <= len(description) <= 1024:
        fail("%s: the description has %d characters; it needs 1 to 1024."
             % (path, len(description)))
    link = os.path.join(LINKS, folder)
    if os.path.realpath(link) != os.path.realpath(base):
        fail("%s does not lead to %s, so Claude Code cannot see the skill. Run: mkdir -p %s && "
             "ln -s ../../%s %s" % (link, base, LINKS, base, link))
    if os.path.exists(os.path.join(base, "SOURCE")):
        check_copy(base, fields)


if os.path.isdir(ROOT):
    for folder, dirs, files in os.walk(ROOT):
        dirs.sort()
        depth = 0 if folder == ROOT else os.path.relpath(folder, ROOT).count(os.sep) + 1
        if "SKILL.md" in files and depth != 1:
            fail("%s/SKILL.md is not directly in a skill folder; tools find only "
                 "%s/<name>/SKILL.md." % (folder, ROOT))
    for folder in sorted(os.listdir(ROOT)):
        if os.path.isfile(os.path.join(ROOT, folder, "SKILL.md")):
            check_skill(folder)
if os.path.isdir(LINKS):
    for entry in sorted(os.listdir(LINKS)):
        link = os.path.join(LINKS, entry)
        if os.path.islink(link) and not os.path.exists(link):
            fail("%s points nowhere (%s); delete it or restore its skill."
                 % (link, os.readlink(link)))
sys.exit(1 if failures else 0)
PY
  return 0
}

check_stale_references() {
  local f ref
  for f in AGENTS.md docs/agent/STATUS.md docs/agent/LEARNINGS.md; do
    [ -f "$f" ] || continue
    # shellcheck disable=SC2016  # the pattern matches literal backticks; nothing is meant to expand
    while IFS= read -r ref; do
      case "$ref" in ''|http*|*'<'*|*'>'*|*'*'*) continue;; esac
      [ -e "$ref" ] || problem "$f mentions $ref, which does not exist. Fix the reference or restore the file."
    done < <(grep -oE '`[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+/?`' "$f" | tr -d '`' | sort -u)
  done
  return 0
}

check_credentials() {
  local pattern='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[abp]-[A-Za-z0-9-]{10,}'
  local f
  for f in AGENTS.md CLAUDE.md docs/agent/STATUS.md docs/agent/DECISIONS.md docs/agent/LEARNINGS.md; do
    [ -f "$f" ] || continue
    grep -nE "$pattern" "$f" && problem "$f looks like it contains a credential (lines above). Remove it and rotate the secret."
  done
  return 0
}

check_decisions_append_only() {
  local base="${range%%..*}"
  [ -n "$range" ] || base=HEAD
  git rev-parse --verify -q "$base" >/dev/null 2>&1 || return 0
  git cat-file -e "$base:docs/agent/DECISIONS.md" 2>/dev/null || return 0
  local removed
  removed=$( { diff <(git show "$base:docs/agent/DECISIONS.md") docs/agent/DECISIONS.md || true; } | grep -c '^<' || true)
  [ "${removed:-0}" -gt 0 ] \
    && problem "docs/agent/DECISIONS.md lost lines since $base. It is append-only: add a new dated bullet instead."
  return 0
}

non_code_pathspecs() {  # one ':!<path>' per entry of the list the stop gate also reads
  [ -f ops/agent/non-code-paths.txt ] || return 0
  awk '{ sub(/^[ \t\r]+/, ""); sub(/[ \t\r]+$/, "") } $0 != "" && $0 !~ /^#/ { print ":!" $0 }' \
    ops/agent/non-code-paths.txt
}

check_status_freshness() {
  [ -n "$range" ] || return 0
  local base="${range%%..*}" code_changed status_changed real_commits spec excludes=()
  git rev-parse --verify -q "$base" >/dev/null 2>&1 || return 0
  while IFS= read -r spec; do excludes+=("$spec"); done < <(non_code_pathspecs)
  code_changed=$(git diff --name-only "$range" -- . ${excludes[@]+"${excludes[@]}"} | wc -l | tr -d ' ')
  status_changed=$(git diff --name-only "$range" -- docs/agent/STATUS.md | wc -l | tr -d ' ')
  real_commits=$(git log --format=%s "$range" | grep -vc '^wip:' || true)
  if [ "$code_changed" -gt 0 ] && [ "$status_changed" -eq 0 ] && [ "$real_commits" -gt 0 ]; then
    problem "This push changes code but not docs/agent/STATUS.md. Rewrite STATUS.md, or prefix work-in-progress commits with 'wip:'."
  fi
  return 0
}

report_todos() {
  local n
  [ -f AGENTS.md ] || return 0
  n=$( (grep -o '<[^<>]*>' AGENTS.md || true) | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && echo "TODO: AGENTS.md has $n placeholder(s) in <angle brackets> left to fill."
  [ -f ops/verify.sh ] && grep -q 'KIT-PLACEHOLDER' ops/verify.sh \
    && echo "TODO: ops/verify.sh is not configured (replace the KIT-PLACEHOLDER block)."
  if [ -z "${CI:-}" ] && [ -x .githooks/pre-commit ] && [ "$(git config core.hooksPath || true)" != .githooks ]; then
    echo "TODO: commits do not run ops/verify.sh yet; enable the pre-commit gate: git config core.hooksPath .githooks"
  fi
  [ -f ops/agent/KIT_VERSION ] && echo "NOTE: kit $(head -n 1 ops/agent/KIT_VERSION), stamped by install.sh"
  return 0
}

check_python; check_agents_md; check_memory_files; check_pointer_files; check_hooks; check_verify_script
check_gate_files; check_change_files; check_skills; check_stale_references; check_credentials
check_decisions_append_only; check_status_freshness
report_todos
[ "$fail" -eq 0 ] && echo "OK: agent kit checks passed"
exit "$fail"
