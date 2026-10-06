#!/usr/bin/env bash
# Checks the agent kit's own rules. Local: ./ops/check-agent-kit.sh
# CI: ./ops/check-agent-kit.sh --range <base>..HEAD   (adds append-only and freshness rules)
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
problem() { echo "FAIL: $*"; fail=1; }
range="${AGENT_KIT_RANGE:-}"
[ "${1:-}" = "--range" ] && range="${2:-}"

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
  return 0
}

check_change_files() {
  [ -d docs/agent/changes ] || return 0
  [ -f docs/agent/changes/_template.md ] \
    || problem "docs/agent/changes/_template.md is missing. Restore it from the starter kit."
  python3 - <<'PY' || fail=1
import pathlib, re, sys

HEADINGS = ("Intent", "Tier", "Acceptance", "Tasks", "Out of scope", "Evidence")
TEST_REF = re.compile(r"test: `([^`]+)`")


def sections(text):
    parts, name = {}, None
    for line in text.splitlines():
        if line.startswith("## "):
            name = line[3:].strip()
            parts[name] = []
        elif name:
            parts[name].append(line)
    return parts


def closed_problems(path, parts, criteria):
    found = []
    for line in criteria:
        for ref in TEST_REF.findall(line):
            if not pathlib.Path(ref.split("::")[0]).exists():
                found.append(f"{path} is closed but its test {ref} does not exist.")
    if any(line.lstrip().startswith("- [ ]") for line in parts["Tasks"]):
        found.append(f"{path} is closed with unchecked tasks; tick them or reopen the change.")
    evidence = "\n".join(parts["Evidence"])
    if not re.search(r"^- verification: verified\b", evidence, re.M):
        found.append(f"{path} is closed without a '- verification: verified ...' line under Evidence.")
    if re.search(r"<[^<>]*>", evidence):
        found.append(f"{path} is closed with <placeholders> left under Evidence.")
    return found


def problems_in(path):
    text = re.sub(r"<!--.*?-->", "", path.read_text(errors="replace"), flags=re.S)
    parts = sections(text)
    missing = ["## " + h for h in HEADINGS if h not in parts]
    if missing:
        return [f"{path} lacks {', '.join(missing)}; "
                "copy the headings from docs/agent/changes/_template.md."]
    status = re.search(r"^status: (open|closed)\s*$", text, re.M)
    if not status:
        return [f"{path} needs a line 'status: open' or 'status: closed'."]
    criteria = [line for line in parts["Acceptance"] if line.startswith("- ")]
    found = [] if criteria else [f"{path} has no acceptance criteria under ## Acceptance."]
    found += [f"{path}: acceptance line names no test: `path`: {line}"
              for line in criteria if not TEST_REF.search(line)]
    if status.group(1) == "closed":
        found += closed_problems(path, parts, criteria)
    return found


problems = []
for change in sorted(pathlib.Path("docs/agent/changes").glob("*.md")):
    if change.name != "_template.md":
        problems += problems_in(change)
for problem in problems:
    print("FAIL: " + problem)
sys.exit(1 if problems else 0)
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
  return 0
}

check_python; check_agents_md; check_memory_files; check_pointer_files; check_hooks; check_verify_script
check_gate_files; check_change_files; check_stale_references; check_credentials
check_decisions_append_only; check_status_freshness
report_todos
[ "$fail" -eq 0 ] && echo "OK: agent kit checks passed"
exit "$fail"
