#!/usr/bin/env bash
# shellcheck disable=SC2016  # test fixtures contain literal $(...) and backticks that must not expand
# Self-test for the agent kit. Copies the kit into temporary git repositories and proves that the
# check fails on each broken rule, that the session hooks behave, that the stop gate answers each
# tool in its documented shape and cannot be skipped by committing first or by changing gate files,
# that the pre-commit hook refuses failing commits, that change files are checked and nudged, that
# skills are checked, and that install.sh updates an adopter.
# Exit 1 if any case fails.
set -euo pipefail
kit="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/agent-kit-test.XXXXXX")"
export XDG_CACHE_HOME="$work/cache"
trap 'chmod -R u+w "$work" && rm -r -- "$work"' EXIT  # git objects are read-only; rm would ask
passed=0; failed=0; known=0
ok()  { passed=$((passed + 1)); echo "ok   $1"; }
bad() { failed=$((failed + 1)); echo "FAIL $1"; }
known_failure() {  # known_failure <name> <command...>: a ROADMAP finding that must still fail
  local name="$1"; shift
  if "$@"; then bad "$name now passes: make it a normal case and close its ROADMAP entry"
  else known=$((known + 1)); echo "known $name (ROADMAP Next)"; fi
}
# The copies' verification fails while a file named fail-verify exists, so no case edits verify.sh.
configured='test ! -e fail-verify  # verification configured by test-kit'

edit() {  # edit <file> <old> <new>: replace the first literal occurrence, fail if absent
  python3 - "$@" <<'PY'
import sys, pathlib
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path(path); text = p.read_text()
if old not in text:
    sys.exit(f"edit: {old!r} not found in {path}")
p.write_text(text.replace(old, new, 1))
PY
}

set_key() {  # set_key <file> <key> [value]: rewrite the first '<key>:' line, or drop it without a value
  python3 - "$@" <<'PY'
import re, sys, pathlib
path, key = pathlib.Path(sys.argv[1]), sys.argv[2]
line = "%s: %s\n" % (key, sys.argv[3]) if len(sys.argv) > 3 else ""
text, n = re.subn(r"(?m)^%s:.*\n" % re.escape(key), lambda _: line, path.read_text(), count=1)
if n != 1:
    sys.exit("set_key: no '%s:' line in %s" % (key, path))
path.write_text(text)
PY
}

status_add() {  # status_add <dir> <line>: add a line to STATUS.md, dropping a blank one: no growth
  python3 - "$1/docs/agent/STATUS.md" "$2" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); lines = p.read_text().splitlines()
lines.remove("")
p.write_text("\n".join(lines + [sys.argv[2]]) + "\n")
PY
}

fresh_copy() {  # fresh_copy <name> -> path of a configured kit copy with one commit
  local dir="$work/$1"
  mkdir -p "$dir"
  (cd "$kit" && tar --exclude=.git --exclude=research --exclude=settings.local.json -cf - .) | (cd "$dir" && tar -xf -)
  python3 - "$dir/ops/verify.sh" "$configured" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(re.sub(r"# KIT-PLACEHOLDER.*", lambda _: sys.argv[2] + "\n", t, flags=re.S))
PY
  edit "$dir/AGENTS.md" "<one sentence: what this software does and for whom>" "A test project"
  (cd "$dir" && git init -q -b main && git add -A && git -c user.name=kit -c user.email=kit@example.com commit -qm "init")
  echo "$dir"
}

commit_in() {  # commit_in <dir> <message>
  (cd "$1" && git add -A && git -c user.name=kit -c user.email=kit@example.com commit -qm "$2")
}

check_expect() {  # check_expect ok|fail <name> <dir> [check args...]
  local want="$1" name="$2" dir="$3"; shift 3
  local out rc=0
  out="$(cd "$dir" && ./ops/check-agent-kit.sh "$@" 2>&1)" || rc=$?
  if [ "$want" = ok ] && [ "$rc" -eq 0 ]; then ok "$name"
  elif [ "$want" = fail ] && [ "$rc" -ne 0 ] && grep -q '^FAIL:' <<<"$out"; then ok "$name"
  else bad "$name (exit $rc)"; printf '%s\n' "$out" | sed 's/^/     /'; fi
}

check_fails_with() {  # check_fails_with <name> <dir> <text>: the check fails with <text> in a FAIL line
  local name="$1" dir="$2" text="$3" out fails rc=0
  out="$(cd "$dir" && ./ops/check-agent-kit.sh 2>&1)" || rc=$?
  fails="$(grep '^FAIL:' <<<"$out" || true)"  # GAP lines quote change-file text and could match
  if [ "$rc" -ne 0 ] && grep -qF -- "$text" <<<"$fails"; then ok "$name"
  else bad "$name (exit $rc)"; printf '%s\n' "$out" | sed 's/^/     /'; fi
}

start() {  # start <dir> [payload-json]: run the session-start hook, which records the session base
  local payload="${2:-}"
  [ -n "$payload" ] || payload='{"source":"startup"}'
  (cd "$1" && printf '%s' "$payload" | ./ops/agent/session-start.sh >/dev/null)
}

gate() {  # gate <dir> <consumer> <payload-json>: sets rc, out, err
  local dir="$1" consumer="$2" payload="$3"
  rc=0
  out="$(cd "$dir" && printf '%s' "$payload" | python3 ops/agent/stop_gate.py --consumer "$consumer" 2>"$work/err")" || rc=$?
  err="$(cat "$work/err")"
}

claims_done() {  # claims_done <dir>: a Claude turn that ends with a completion claim
  gate "$1" claude '{"last_assistant_message":"Done."}'
}

blocked() {  # blocked <name> <pattern>: the last Claude gate call blocked with <pattern> in the reason
  if [ "$rc" -eq 2 ] && grep -q "$2" <<<"$err"; then ok "$1"; else bad "$1 (rc $rc: $err)"; fi
}

allowed() {  # allowed <name>: the last Claude gate call let the turn end
  if [ "$rc" -eq 0 ]; then ok "$1"; else bad "$1 (rc $rc: $err)"; fi
}

failing_commit() {  # failing_commit <dir>: commit a code change that makes verification fail
  mkdir -p "$1/src"; echo x > "$1/src/a.txt"; touch "$1/fail-verify"; commit_in "$1" "feat: failing"
}

change_file() {  # change_file <dir> <name> <open|closed> <test-path>: write a well-formed T1 change
  cat > "$1/docs/agent/changes/$2.md" <<EOF
# Demo change
status: $3

## Intent
Show that the kit accepts a well-formed change file.

## Tier
T1 · a feature

## Acceptance
- Given a kit copy, when the check runs, then it passes · test: \`$4\`

## Tasks
- [x] write the change file

## Out of scope
- everything else

## Evidence
- verification: verified — command: \`./ops/verify.sh\` — at: 2026-10-06, uncommitted
- last lines: OK: agent kit checks passed
EOF
}

add_delta() {  # add_delta <dir> <name> <delta-lines>: make a change T2 with Design and a Spec delta
  edit "$1/docs/agent/changes/$2.md" "T1 · a feature" "T2 · crosses modules"
  printf '\n## Design\nOne module owns the rule.\n\n## Spec delta\nspec: docs/agent/specs/demo.md\n%s\n' "$3" \
    >> "$1/docs/agent/changes/$2.md"
}

archive_expect() {  # archive_expect ok|fail <case> <dir> <name> <pattern>: archive one change file
  local want="$1" name="$2" dir="$3" change="$4" pattern="$5" out rc=0
  out="$(cd "$dir" && ./ops/agent/changes.py archive "docs/agent/changes/$change.md" 2>&1)" || rc=$?
  if { [ "$want" = ok ] && [ "$rc" -eq 0 ]; } || { [ "$want" = fail ] && [ "$rc" -ne 0 ]; }; then
    if grep -q "$pattern" <<<"$out"; then ok "$name"; return; fi
  fi
  bad "$name (exit $rc)"; printf '%s\n' "$out" | sed 's/^/     /'
}

echo "== shipped templates =="
if grep -qE '^updated: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} [A-Z0-9+:-]+ ' "$kit/docs/agent/STATUS.md"
then ok "the shipped STATUS.md dates its update with a time"
else bad "the shipped STATUS.md dates its update with a time"; fi

echo "== check-agent-kit.sh =="
d="$(fresh_copy pristine)"; check_expect ok "configured copy passes" "$d"
d="$(fresh_copy filled)"; python3 - "$d/AGENTS.md" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); p.write_text(re.sub(r"<[^<>]*>", "filled", p.read_text()))
PY
check_expect ok "fully filled AGENTS.md passes" "$d"
d="$(fresh_copy long)"; for i in $(seq 1 80); do echo "- filler $i" >> "$d/AGENTS.md"; done
check_expect fail "AGENTS.md over 100 lines" "$d"
d="$(fresh_copy rules)"; edit "$d/AGENTS.md" $'   production configuration.\n' $'   production configuration.\n8. One rule too many.\n'
check_expect fail "more than 7 rules" "$d"
d="$(fresh_copy include)"; echo "@docs/agent/STATUS.md" >> "$d/AGENTS.md"; check_expect fail "@path include in AGENTS.md" "$d"
d="$(fresh_copy claude)"; edit "$d/CLAUDE.md" "@AGENTS.md" "Please read AGENTS.md"; check_expect fail "CLAUDE.md without @AGENTS.md" "$d"
d="$(fresh_copy shadow)"; echo "rules" > "$d/.cursorrules"; check_expect fail ".cursorrules present" "$d"
d="$(fresh_copy hookpath)"; edit "$d/.claude/settings.json" "ops/agent/session-start.sh" "ops/agent/missing.sh"
check_expect fail "hook path missing" "$d"
d="$(fresh_copy projdir)"; edit "$d/.claude/settings.json" '$(git rev-parse --show-toplevel)' '${CLAUDE_PROJECT_DIR}'
check_expect fail "CLAUDE_PROJECT_DIR in hook" "$d"
d="$(fresh_copy optin)"; (cd "$d/contrib/untested" && tar --exclude=README.md -cf - .) | (cd "$d" && tar -xf -)
check_expect ok "untested configs pass the check once copied to the root" "$d"
edit "$d/.codex/hooks.json" '"timeout": 3 }' '"timeout": 10 }'; check_expect fail "Codex SessionEnd timeout over 3 s" "$d"
d="$(fresh_copy unconfigured)"; edit "$d/ops/verify.sh" "$configured" $'# KIT-PLACEHOLDER restored\ntrue'
check_expect fail "verify.sh unconfigured on a filled project" "$d"
d="$(fresh_copy cred)"; status_add "$d" "token: ghp_$(printf 'a%.0s' {1..36})"; check_expect fail "credential pattern" "$d"
d="$(fresh_copy stale)"; status_add "$d" '- see `src/nowhere/missing.py`'; check_expect fail "stale path reference" "$d"
d="$(fresh_copy noverif)"; python3 - "$d/docs/agent/STATUS.md" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); p.write_text(re.sub(r"^verification:", "checked:", p.read_text(), flags=re.M))
PY
check_expect fail "STATUS.md without verification line" "$d"
d="$(fresh_copy noevid)"; edit "$d/docs/agent/LEARNINGS.md" "## Active" $'## Active\n- 2026-01-01 · lesson without proof · why: none'
check_expect fail "learning without evidence" "$d"
d="$(fresh_copy decisions)"; python3 - "$d/docs/agent/DECISIONS.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); lines = p.read_text().splitlines(keepends=True); p.write_text("".join(lines[:-1]))
PY
check_expect fail "DECISIONS.md line removed" "$d" --range HEAD..
d="$(fresh_copy zerobase)"; check_expect ok "a zero push base skips the range rules" "$d" --range "$(printf '0%.0s' {1..40})..HEAD"
d="$(fresh_copy fresh)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; commit_in "$d" "feat: add file"
check_expect fail "code changed without STATUS.md in range" "$d" --range HEAD~1..HEAD
d="$(fresh_copy wip)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; commit_in "$d" "wip: scratch"
check_expect ok "wip commit exempt from freshness" "$d" --range HEAD~1..HEAD
d="$(fresh_copy freshok)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; status_add "$d" "- note"; commit_in "$d" "feat: with status"
check_expect ok "code and STATUS.md changed together" "$d" --range HEAD~1..HEAD
d="$(fresh_copy readme)"; echo "more" >> "$d/README.md"; commit_in "$d" "docs: readme"
check_expect ok "README-only push needs no STATUS.md" "$d" --range HEAD~1..HEAD
d="$(fresh_copy listed)"; echo "src" >> "$d/ops/agent/non-code-paths.txt"; commit_in "$d" "wip: list src"
mkdir -p "$d/src"; echo x > "$d/src/a.txt"; commit_in "$d" "feat: listed path"
check_expect ok "freshness reads ops/agent/non-code-paths.txt" "$d" --range HEAD~1..HEAD
d="$(fresh_copy nolist)"; rm "$d/ops/agent/non-code-paths.txt"; check_expect fail "non-code list missing" "$d"
d="$(fresh_copy hookx)"; chmod -x "$d/.githooks/pre-commit"; check_expect fail "pre-commit hook not executable" "$d"
d="$(fresh_copy hooktodo)"; out="$(cd "$d" && CI='' ./ops/check-agent-kit.sh)"
if grep -q 'core.hooksPath' <<<"$out"; then ok "reminds to enable the pre-commit gate"; else bad "reminds to enable the pre-commit gate"; fi
d="$(fresh_copy chopen)"; change_file "$d" demo open tests/not_written_yet.sh; check_expect ok "open change file passes" "$d"
d="$(fresh_copy chclosed)"; change_file "$d" demo closed ops/test-kit.sh; check_expect fail "a closed change must be archived" "$d"
d="$(fresh_copy chhead)"; change_file "$d" demo open x; edit "$d/docs/agent/changes/demo.md" "## Out of scope" "## Notes"
check_expect fail "change file missing a section" "$d"
d="$(fresh_copy chstatus)"; change_file "$d" demo open x; edit "$d/docs/agent/changes/demo.md" "status: open" "state: open"
check_expect fail "change file without status line" "$d"
d="$(fresh_copy chtest)"; change_file "$d" demo open x; edit "$d/docs/agent/changes/demo.md" ' · test: `x`' ""
check_expect fail "acceptance line without a test" "$d"
d="$(fresh_copy cht2)"; change_file "$d" demo open x; edit "$d/docs/agent/changes/demo.md" "T1 · a feature" "T2 · crosses modules"
check_expect fail "T2 change without Design and Spec delta" "$d"
d="$(fresh_copy specok)"; printf '# Demo spec\n\n## Requirements\n- DEMO-1: a\n- DEMO-2: b\n' > "$d/docs/agent/specs/demo.md"
check_expect ok "well-formed spec passes" "$d"
d="$(fresh_copy specdup)"; printf '# Demo spec\n\n## Requirements\n- DEMO-1: a\n- DEMO-1: b\n' > "$d/docs/agent/specs/demo.md"
check_expect fail "spec with a duplicate ID" "$d"
d="$(fresh_copy specid)"; printf '# Demo spec\n\n## Requirements\n- a rule without an ID\n' > "$d/docs/agent/specs/demo.md"
check_expect fail "spec requirement without an ID" "$d"
d="$(fresh_copy gap)"; change_file "$d" demo open tests/not_written_yet.sh; out="$(cd "$d" && ./ops/check-agent-kit.sh 2>&1)"
if grep -q 'GAP: .*not_written_yet.sh does not exist' <<<"$out"; then ok "GAP: an acceptance test not written yet"; else bad "GAP: missing test"; fi
d="$(fresh_copy gapold)"; change_file "$d" demo open ops/test-kit.sh; out="$(cd "$d" && ./ops/check-agent-kit.sh 2>&1)"
if grep -q 'GAP: .*ops/test-kit.sh is unchanged' <<<"$out"; then ok "GAP: an acceptance test unchanged since the base"; else bad "GAP: unchanged test"; fi

echo "== skills =="
template_skills() {  # template_skills <dir>: both kit skills, each linked, with SOURCE and LICENSE
  local s
  for s in kit-debug kit-explore; do
    [ "$(readlink "$1/.claude/skills/$s")" = "../../.agents/skills/$s" ] || return 1
    [ -s "$1/.agents/skills/$s/SOURCE" ] || return 1
    [ -s "$1/.agents/skills/$s/LICENSE" ] || return 1
  done
}
d="$(fresh_copy skills)"; check_expect ok "skills template passes" "$d"
if template_skills "$d"; then ok "skills template ships both skills, linked, with SOURCE and LICENSE"
else bad "skills template ships both skills, linked, with SOURCE and LICENSE"; fi
d="$(fresh_copy sknest)"; mkdir -p "$d/.agents/skills/kit-debug/more"
cp "$d/.agents/skills/kit-debug/SKILL.md" "$d/.agents/skills/kit-debug/more/SKILL.md"
check_fails_with "skills check refuses a nested skill" "$d" "kit-debug/more/SKILL.md is not directly in a skill folder"
d="$(fresh_copy skname)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" name Kit--Explore
check_fails_with "skills check refuses a bad name" "$d" "breaks the Agent Skills pattern"
d="$(fresh_copy sklong)"; long="$(printf 'a%.0s' $(seq 1 65))"; mkdir -p "$d/.agents/skills/$long"
printf -- '---\nname: %s\ndescription: A name one character too long.\n---\n' "$long" > "$d/.agents/skills/$long/SKILL.md"
ln -s "../../.agents/skills/$long" "$d/.claude/skills/$long"
check_fails_with "skills check refuses a 65-character name" "$d" "breaks the Agent Skills pattern"
d="$(fresh_copy skfolder)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" name kit-explorer
check_fails_with "skills check refuses a name unlike its folder" "$d" "differs from its folder"
d="$(fresh_copy sknodesc)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description
check_fails_with "skills check refuses a bad description: none" "$d" "the description has 0 characters"
d="$(fresh_copy skdesc)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description "$(printf 'a%.0s' $(seq 1 1025))"
check_fails_with "skills check refuses a bad description: 1,025 characters" "$d" "the description has 1025 characters"
d="$(fresh_copy skdesc24)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description "$(printf 'a%.0s' $(seq 1 1024))"
check_expect ok "skills check allows a 1,024-character description" "$d"
d="$(fresh_copy sknolink)"; rm "$d/.claude/skills/kit-explore"
check_fails_with "skills check refuses a missing or dangling link: missing" "$d" ".claude/skills/kit-explore does not lead to .agents/skills/kit-explore"
d="$(fresh_copy skdangle)"; ln -s ../../.agents/skills/kit-gone "$d/.claude/skills/kit-gone"
check_fails_with "skills check refuses a missing or dangling link: dangling" "$d" ".claude/skills/kit-gone points nowhere"
d="$(fresh_copy sklicense)"; rm "$d/.agents/skills/kit-debug/LICENSE"
check_fails_with "skills check refuses an unvetted copy: no LICENSE" "$d" "is a copied skill without LICENSE"
d="$(fresh_copy skpin)"; set_key "$d/.agents/skills/kit-debug/SOURCE" commit 8ca22db
check_fails_with "skills check refuses an unvetted copy: no 40-hex commit" "$d" "the full 40-hex upstream commit"
d="$(fresh_copy skexec)"; chmod +x "$d/.agents/skills/kit-debug/defense-in-depth.md"
check_fails_with "skills check refuses an unvetted copy: an executable file" "$d" "defense-in-depth.md is executable"
d="$(fresh_copy skhooks)"; edit "$d/.agents/skills/kit-debug/SKILL.md" $'name: kit-debug\n' $'name: kit-debug\nhooks:\n  Stop: echo stop\n'
check_fails_with "skills check refuses an unvetted copy: a hooks key" "$d" "has the frontmatter key(s) hooks"
d="$(fresh_copy skscript)"; mkdir -p "$d/.agents/skills/my-tool"
printf -- '---\nname: my-tool\ndescription: Runs the project tool.\n---\nRun ./run.sh.\n' > "$d/.agents/skills/my-tool/SKILL.md"
printf '#!/bin/sh\necho tool\n' > "$d/.agents/skills/my-tool/run.sh"; chmod +x "$d/.agents/skills/my-tool/run.sh"
ln -s ../../.agents/skills/my-tool "$d/.claude/skills/my-tool"
check_expect ok "skills check allows an adopter script" "$d"
d="$(fresh_copy skquote)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description '"An open quote'
check_fails_with "skills check refuses unreadable frontmatter: an open quote" "$d" "the frontmatter is unreadable"
d="$(fresh_copy skfence)"; edit "$d/.agents/skills/kit-debug/SKILL.md" $'fixes\n---\n' $'fixes\n'
check_fails_with "skills check refuses unreadable frontmatter: no closing line" "$d" "the frontmatter is unreadable"
d="$(fresh_copy skurl)"; set_key "$d/.agents/skills/kit-debug/SOURCE" url
check_fails_with "skills check refuses an unvetted copy: no url" "$d" "SOURCE needs 'url: https://"
d="$(fresh_copy skspdx)"; set_key "$d/.agents/skills/kit-debug/SOURCE" license
check_fails_with "skills check refuses an unvetted copy: no licence id" "$d" "SOURCE needs 'license:'"
d="$(fresh_copy sktwice)"; edit "$d/.agents/skills/kit-explore/SKILL.md" $'name: kit-explore\n' $'name: kit-explore\nname: kit-explore\n'
check_fails_with "skills check refuses unreadable frontmatter: a key twice" "$d" "'name' appears twice"
d="$(fresh_copy sktab)"; edit "$d/.agents/skills/kit-explore/SKILL.md" $'name: kit-explore\n' $'name: kit-explore\nmetadata:\n\tauthor: someone\n'
check_fails_with "skills check refuses unreadable frontmatter: a tab indent" "$d" "indented with a tab"
d="$(fresh_copy skcolon)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description "Use when: planning"
check_fails_with "skills check refuses unreadable frontmatter: ': ' in a plain value" "$d" "contains ': '"
d="$(fresh_copy skstray)"; edit "$d/.agents/skills/kit-explore/SKILL.md" $'name: kit-explore\n' $'name: kit-explore\njust a sentence\n'
check_fails_with "skills check refuses unreadable frontmatter: a line without a key" "$d" "is not 'key: value'"
d="$(fresh_copy skflow)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description "[plan, design]"
check_fails_with "skills check refuses a description it cannot read" "$d" "'description' is not a plain, quoted or block-scalar value"
d="$(fresh_copy skblock)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description $'>-\n  A relentless interview: folded\n  over two lines.'
check_expect ok "skills check reads a block-scalar description" "$d"
d="$(fresh_copy skquoted)"; set_key "$d/.agents/skills/kit-explore/SKILL.md" description "'A quoted description: with a colon'"
check_expect ok "skills check reads a quoted description" "$d"
d="$(fresh_copy skrule3)"; mv "$d/.agents/skills/kit-debug" "$d/.agents/skills/kit-fix"
check_fails_with "skills rule 3 path is checked" "$d" "AGENTS.md mentions .agents/skills/kit-debug/SKILL.md, which does not exist"

echo "== changes.py archive =="
d="$(fresh_copy aropen)"; change_file "$d" demo open ops/test-kit.sh; archive_expect fail "refuses an open change" "$d" demo "status: closed"
d="$(fresh_copy argone)"; change_file "$d" demo closed tests/missing_test.sh
archive_expect fail "refuses a closed change whose test is missing" "$d" demo "does not exist"
d="$(fresh_copy artask)"; change_file "$d" demo closed ops/test-kit.sh; edit "$d/docs/agent/changes/demo.md" "- [x]" "- [ ]"
archive_expect fail "refuses unchecked tasks" "$d" demo "unchecked tasks"
d="$(fresh_copy arnoev)"; change_file "$d" demo closed ops/test-kit.sh
edit "$d/docs/agent/changes/demo.md" "- verification: verified" "- verification: <verified | partial | failed>"
archive_expect fail "refuses a change without verified evidence" "$d" demo "verification: verified"
d="$(fresh_copy arfix)"; change_file "$d" demo closed ops/test-kit.sh; edit "$d/docs/agent/changes/demo.md" "T1 · a feature" "T1 fix · a bug"
archive_expect fail "a fix needs a test that failed first" "$d" demo "failed first"
echo "- failed first: ops/test-kit.sh exited 1 before the fix" >> "$d/docs/agent/changes/demo.md"
archive_expect ok "a fix with failed-first evidence archives" "$d" demo "archived"
d="$(fresh_copy art1)"; change_file "$d" demo closed ops/test-kit.sh; archive_expect ok "archives a closed T1 change" "$d" demo "archived"
if ls "$d"/docs/agent/changes/archive/*-demo.md >/dev/null 2>&1 && [ ! -e "$d/docs/agent/changes/demo.md" ]; then ok "the change file moves to archive/"
else bad "the change file moves to archive/"; fi
check_expect ok "the check passes after archiving" "$d"
d="$(fresh_copy art2)"; spec="$d/docs/agent/specs/demo.md"
change_file "$d" add closed ops/test-kit.sh; add_delta "$d" add $'### ADDED\n- DEMO-1: first rule\n- DEMO-2: second rule'
archive_expect ok "archive creates the spec from ADDED" "$d" add "merged the Spec delta"
change_file "$d" edit closed ops/test-kit.sh; add_delta "$d" edit $'### MODIFIED\n- DEMO-1: first rule, revised\n### REMOVED\n- DEMO-2'
archive_expect ok "archive applies MODIFIED and REMOVED" "$d" edit "merged the Spec delta"
if grep -q 'DEMO-1: first rule, revised' "$spec" && ! grep -q 'DEMO-2' "$spec"; then ok "the spec holds the merged requirements"
else bad "the spec holds the merged requirements"; sed 's/^/     /' "$spec"; fi
check_expect ok "merged spec and archive pass the check" "$d"
change_file "$d" dup closed ops/test-kit.sh; add_delta "$d" dup $'### ADDED\n- DEMO-1: again'
archive_expect fail "ADDED with an existing ID is refused" "$d" dup "already exists"
if [ -e "$d/docs/agent/changes/dup.md" ] && [ "$(grep -c 'DEMO-1' "$spec")" -eq 1 ]; then ok "a refused archive changes nothing"
else bad "a refused archive changes nothing"; fi
change_file "$d" ghost closed ops/test-kit.sh; add_delta "$d" ghost $'### MODIFIED\n- DEMO-9: nothing'
archive_expect fail "MODIFIED with an unknown ID is refused" "$d" ghost "not in the spec"

echo "== session hooks =="
d="$(fresh_copy stamp)"; (cd "$d" && echo y > dirty.txt && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then ok "stamps a dirty tree"; else bad "stamps a dirty tree"; fi
lines="$(wc -l < "$d/docs/agent/STATUS.md")"; commit_in "$d" "wip: stamped"
(cd "$d" && echo z > dirty2.txt && ./ops/agent/session-end.sh)
stamps="$(grep -c 'Session ended without wrap-up' "$d/docs/agent/STATUS.md")"
if [ "$stamps" -eq 1 ] && [ "$(wc -l < "$d/docs/agent/STATUS.md")" -eq "$lines" ]; then ok "a committed stamp is replaced, not repeated"
else bad "a committed stamp is replaced, not repeated ($stamps stamps)"; fi
d="$(fresh_copy nostamp)"; (cd "$d" && echo y > dirty.txt && echo "- touched" >> docs/agent/STATUS.md && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then bad "skips when STATUS.md was edited"; else ok "skips when STATUS.md was edited"; fi
d="$(fresh_copy clean)"; (cd "$d" && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then bad "skips a clean tree"; else ok "skips a clean tree"; fi
d="$(fresh_copy inject)"; out="$(cd "$d" && printf '{}' | ./ops/agent/session-start.sh)"
if grep -q 'Contents of docs/agent/STATUS.md' <<<"$out"; then ok "session start injects STATUS.md"; else bad "session start injects STATUS.md"; fi

echo "== stop_gate.py =="
d="$(fresh_copy gate)"
gate "$d" claude '{}'; allowed "clean tree allows"
mkdir -p "$d/src"; echo x > "$d/src/new.txt"; touch "$d/fail-verify"
claims_done "$d"; blocked "failing verify blocks (claude: exit 2)" FAILED
gate "$d" codex '{}'
if [ "$rc" -eq 0 ] && grep -q '"decision": "block"' <<<"$out"; then ok "failing verify blocks (codex: JSON)"; else bad "failing verify blocks codex (rc $rc: $out)"; fi
gate "$d" copilot '{}'
if [ "$rc" -eq 0 ] && grep -q '3 times' <<<"$err" && [ -z "$out" ]; then ok "three failures trip the breaker"; else bad "three failures trip the breaker (rc $rc: $out / $err)"; fi
gate "$d" cursor '{}'
if [ "$rc" -eq 0 ] && grep -q 'followup_message' <<<"$out"; then ok "failing verify blocks (cursor: follow-up)"; else bad "failing verify blocks cursor (rc $rc: $out)"; fi
rm "$d/fail-verify"; touch -t 202001010000 "$d/docs/agent/STATUS.md"
gate "$d" claude '{"last_assistant_message":"All done, tests pass."}'; blocked "stale STATUS.md blocks a completion claim" STATUS.md
claims_done "$d"; allowed "a nudge fires once per change set"
echo y >> "$d/src/new.txt"; sleep 1; touch "$d/docs/agent/STATUS.md"
claims_done "$d"; allowed "fresh STATUS.md allows"
d="$(fresh_copy gateunconf)"; edit "$d/ops/verify.sh" "$configured" $'# KIT-PLACEHOLDER restored\ntrue'; commit_in "$d" "chore: unconfigure"
echo x > "$d/new.txt"; gate "$d" claude '{}'
if [ "$rc" -eq 0 ] && grep -q 'not configured' <<<"$err"; then ok "verify.sh unconfigured at the base skips the test gate"; else bad "unconfigured verify.sh skips (rc $rc: $err)"; fi
d="$(fresh_copy docsonly)"; touch "$d/fail-verify"; commit_in "$d" "chore: failing at base"; start "$d"
echo "more" >> "$d/README.md"; claims_done "$d"; allowed "README-only edit does not run verify"
d="$(fresh_copy pulled)"; start "$d"; up="$work/pulled-upstream"; git clone -q "$d" "$up"
mkdir -p "$up/src"; echo x > "$up/src/new.txt"; status_add "$up" "- src/new.txt added"
commit_in "$up" "feat: code with its STATUS.md"; git -C "$d" pull -q --ff-only "$up" main
touch -t 202001010000 "$d/docs/agent/STATUS.md"  # checkout wrote docs/ before src/
quiet_claim() { claims_done "$1"; [ "$rc" -eq 0 ]; }
known_failure "a pull that brings code with its STATUS.md does not nudge" quiet_claim "$d"

echo "== stop gate bypass probes =="
d="$(fresh_copy b1)"; start "$d"; failing_commit "$d"
claims_done "$d"; blocked "B1 commit, then stop: still verified" FAILED
d="$(fresh_copy b1up)"; (cd "$d" && git branch -q published && git branch -q -u published); failing_commit "$d"
claims_done "$d"; blocked "B1 without a session base: upstream merge-base" FAILED
d="$(fresh_copy compact)"; start "$d"; failing_commit "$d"; start "$d" '{"source":"compact"}'
claims_done "$d"; blocked "compaction keeps the session base" FAILED
start "$d"; claims_done "$d"; allowed "a new session starts from the current HEAD"
d="$(fresh_copy b2)"; start "$d"; echo x > "$d/new.txt"; echo '# KIT-PLACEHOLDER' >> "$d/ops/verify.sh"
claims_done "$d"; blocked "B2 placeholder added to verify.sh blocks" "Gate files changed"
d="$(fresh_copy b2commit)"; start "$d"; echo '# KIT-PLACEHOLDER' >> "$d/ops/verify.sh"; commit_in "$d" "chore: unconfigure"
claims_done "$d"; blocked "B2 committed placeholder blocks" "Gate files changed"
d="$(fresh_copy b3)"; start "$d"; echo x > "$d/new.txt"; chmod -x "$d/ops/verify.sh"
claims_done "$d"; blocked "B3 chmod -x verify.sh blocks" "Gate files changed"
d="$(fresh_copy b3mode)"; start "$d"; (cd "$d" && git config core.fileMode false); echo x > "$d/new.txt"
gate "$d" claude '{}'; allowed "passing verify allows (core.fileMode false)"
chmod -x "$d/ops/verify.sh"; gate "$d" claude '{}'; blocked "B3 chmod -x after a pass, core.fileMode false" "not executable"
d="$(fresh_copy b4)"; start "$d"; echo x > "$d/new.txt"; rm "$d/ops/verify.sh"
claims_done "$d"; blocked "B4 deleted verify.sh blocks" "Gate files changed"
d="$(fresh_copy b4mv)"; start "$d"; (cd "$d" && git mv ops/verify.sh ops/verify.off)
claims_done "$d"; blocked "B4 renamed verify.sh blocks" "Gate files changed"
d="$(fresh_copy listgame)"; start "$d"; echo "src" >> "$d/ops/agent/non-code-paths.txt"; failing_commit "$d"
claims_done "$d"; blocked "adding code to the non-code list blocks" "Gate files changed"

echo "== pre-commit =="
d="$(fresh_copy precommit)"; start "$d"; (cd "$d" && git config core.hooksPath .githooks)
if failing_commit "$d" >/dev/null 2>&1; then bad "pre-commit refuses a failing commit"; else ok "pre-commit refuses a failing commit"; fi
(cd "$d" && git -c user.name=kit -c user.email=kit@example.com commit -q --no-verify -m "feat: skip hooks")
claims_done "$d"; blocked "commit --no-verify, then stop: still blocked" FAILED
rm "$d/fail-verify"
if commit_in "$d" "fix: passing" >/dev/null 2>&1; then ok "pre-commit lets a passing commit through"; else bad "pre-commit lets a passing commit through"; fi

echo "== change-file nudge =="
d="$(fresh_copy nudge)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
touch "$d/docs/agent/STATUS.md"; claims_done "$d"; blocked "four files without a change file nudge" "no change file"
claims_done "$d"; allowed "the change-file nudge fires once per change set"
d="$(fresh_copy nudgelines)"; start "$d"; mkdir -p "$d/src"; seq 1 60 > "$d/src/big.txt"
touch "$d/docs/agent/STATUS.md"; claims_done "$d"; blocked "over 50 lines without a change file nudge" "no change file"
d="$(fresh_copy nudgetpl)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
echo "- edited" >> "$d/docs/agent/changes/_template.md"; touch "$d/docs/agent/STATUS.md"
claims_done "$d"; blocked "editing the template is not a change file" "no change file"
d="$(fresh_copy nudgesmall)"; start "$d"; echo x > "$d/small.txt"
touch "$d/docs/agent/STATUS.md"; claims_done "$d"; allowed "a small change needs no change file"
d="$(fresh_copy nudgeopen)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
change_file "$d" demo open src/f1.txt; touch "$d/docs/agent/STATUS.md"; claims_done "$d"; blocked "an open change file nudges on a claim" "still open"
d="$(fresh_copy nudgeclosed)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
change_file "$d" demo closed src/f1.txt; (cd "$d" && ./ops/agent/changes.py archive docs/agent/changes/demo.md >/dev/null)
touch "$d/docs/agent/STATUS.md"; claims_done "$d"; allowed "an archived change allows"
d="$(fresh_copy noclaim)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
gate "$d" claude '{"last_assistant_message":"Which option do you prefer?"}'; allowed "no completion claim, no nudge"

if find "$work/cache" -name gate.log | grep -q .; then ok "gate writes its log"; else bad "gate writes its log"; fi

echo "== learnings =="
active_learnings() {  # active_learnings <dir> <n>: replace the Active section with n one-line entries
  python3 - "$1/docs/agent/LEARNINGS.md" "$2" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); n = int(sys.argv[2])
entries = "".join(f"- 2026-10-07 · lesson {i} · evidence: test {i} · why: case\n" for i in range(1, n + 1))
p.write_text(re.sub(r"(## Active\n)(?:- .*\n)*", lambda m: m.group(1) + entries, p.read_text(), count=1))
PY
}
check_refuses() { ! (cd "$1" && ./ops/check-agent-kit.sh >/dev/null 2>&1); }
nothing_dropped() {  # nothing_dropped <dir> <n>: entry n reaches the session, or the check refuses
  check_refuses "$1" && return 0
  (cd "$1" && printf '{"source":"startup"}' | ./ops/agent/session-start.sh | grep -q "lesson $2 ")
}
d="$(fresh_copy learn21)"; active_learnings "$d" 21
known_failure "the check refuses a 21st active learning" check_refuses "$d"
d="$(fresh_copy learn41)"; active_learnings "$d" 41
known_failure "a 41st active learning is injected or refused" nothing_dropped "$d" 41

echo "== install.sh =="
v1_adopter() {  # v1_adopter <name> -> a committed v1.0.0 adopter, filled and trimmed like a real one
  local dir="$work/$1"
  mkdir -p "$dir"
  git -C "$kit" archive v1.0.0 | tar -x -C "$dir"
  python3 - "$dir/ops/verify.sh" "$configured" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(re.sub(r"# KIT-PLACEHOLDER.*", lambda _: sys.argv[2] + "\n", t, flags=re.S))
PY
  edit "$dir/AGENTS.md" "<one sentence: what this software does and for whom>" "An adopter"
  rm -r -- "$dir/research" "$dir/ops/test-kit.sh" "$dir/PRD.md" "$dir/LICENSE"
  cp "$kit/.github/workflows/agent-kit.yml" "$dir/.github/workflows/agent-kit.yml"
  printf '# Status\n\nverification: none — command: `./ops/verify.sh` — at: 2026-10-07\n' \
    > "$dir/docs/agent/STATUS.md"
  (cd "$dir" && git init -q -b main && git add -A && git -c user.name=kit -c user.email=kit@example.com commit -qm "adopt v1.0")
  echo "$dir"
}

install_run() {  # install_run <dir> [options...]: run install.sh against <dir>; sets rc, out
  local dir="$1"; shift
  rc=0
  out="$("$kit/install.sh" "$@" "$dir" 2>&1)" || rc=$?
}

expect() {  # expect <name> <command...>: ok when the command succeeds
  local name="$1"; shift
  if "$@"; then ok "$name"; else bad "$name (exit $rc)"; printf '%s\n' "$out" | sed 's/^/     /'; fi
}

says() { grep -qF -- "$1" <<<"$out"; }
refused() { [ "$rc" -eq 1 ] && grep -q '^install.sh: ' <<<"$out" && says "$1"; }
clean() { [ -z "$(git -C "$1" status --porcelain --untracked-files=all)" ]; }

kit_files_match() {  # kit_files_match <dir>: every kit-owned file equals the kit's, mode included
  local f
  for f in ops/check-agent-kit.sh ops/agent/stop_gate.py ops/agent/session-start.sh \
    ops/agent/session-end.sh ops/agent/changes.py .githooks/pre-commit docs/agent/ONBOARD.md \
    docs/agent/changes/_template.md docs/agent/specs/_template.md \
    ops/agent/non-code-paths.txt .claude/settings.json; do
    cmp -s "$kit/$f" "$1/$f" || { echo "     differs: $f"; return 1; }
    if [ -x "$kit/$f" ] && [ ! -x "$1/$f" ]; then echo "     not executable: $f"; return 1; fi
  done
}

nothing_unshipped() {  # nothing_unshipped <dir>: install.sh copied none of the kit-only files
  local f
  for f in ops/test-kit.sh install.sh PRD.md LICENSE research contrib \
    .github/workflows/kit-self-test.yml; do
    [ ! -e "$1/$f" ] || { echo "     shipped: $f"; return 1; }
  done
}

kit_skills_match() {  # kit_skills_match <dir>: every file of the kit's kit- skills is in <dir>, equal
  local f n=0
  while IFS= read -r -d '' f; do
    n=$((n + 1))
    cmp -s "$kit/$f" "$1/$f" || { echo "     differs: $f"; return 1; }
  done < <(git -C "$kit" ls-files -z --cached --others --exclude-standard -- '.agents/skills/kit-*')
  [ "$n" -gt 0 ]
}

kit_links_match() {  # kit_links_match <dir>: each kit- skill has its relative link in .claude/skills
  local s n=0
  for s in "$kit"/.agents/skills/kit-*/; do
    s="$(basename "$s")"; n=$((n + 1))
    [ "$(readlink "$1/.claude/skills/$s")" = "../../.agents/skills/$s" ] || { echo "     no link: $s"; return 1; }
  done
  [ "$n" -gt 0 ]
}

adopter_files_kept() {
  git -C "$1" diff --quiet HEAD -- AGENTS.md CLAUDE.md ops/verify.sh docs/agent .github .gitignore
}

hook_stays_out() {  # hook_stays_out <dir>: neither settings nor a sidecar brings SessionEnd back
  [ "$rc" -eq 0 ] \
    && ! grep -qsF '"SessionEnd"' "$1/.claude/settings.json" "$1/.claude/settings.json.kit-new"
}
no_pull_request_step() { [ "$rc" -eq 0 ] && ! says "open a pull request"; }
own_rules_respected() { [ "$rc" -eq 0 ] && ! says "make rules 1-3 say what the kit's say"; }

if git -C "$kit" rev-parse -q --verify 'v1.0.0^{commit}' >/dev/null; then
  d="$(v1_adopter upd)"; install_run "$d" --from v1.0.0
  expect "install update from v1.0.0: exits 0" test "$rc" -eq 0
  expect "install update from v1.0.0: adopter-owned files unchanged" adopter_files_kept "$d"
  expect "install update from v1.0.0: kit-owned files equal the kit's" kit_files_match "$d"
  expect "install update from v1.0.0: kit-only files not shipped" nothing_unshipped "$d"
  expect "install update from v1.0.0: version stamped" test -s "$d/ops/agent/KIT_VERSION"
  check_expect ok "install update from v1.0.0: the kit check passes" "$d"
  out="$(cd "$d" && ./ops/check-agent-kit.sh 2>&1)" || true
  expect "install update from v1.0.0: the check notes the version" says "NOTE: kit "

  commit_in "$d" "update the kit"; install_run "$d"
  expect "install is idempotent: second run writes nothing" says "Nothing to write"
  expect "install is idempotent: tree stays clean" clean "$d"

  d="$(v1_adopter side)"
  edit "$d/.claude/settings.json" '"Edit(ops/verify.sh)",' $'"Edit(ops/verify.sh)",\n      "Bash(git push --force *)",'
  commit_in "$d" "patch the deny list"; install_run "$d" --from v1.0.0
  expect "install writes a sidecar: patched file kept" git -C "$d" diff --quiet HEAD -- .claude/settings.json
  expect "install writes a sidecar: kit copy beside it" \
    cmp -s "$kit/.claude/settings.json" "$d/.claude/settings.json.kit-new"
  expect "install writes a sidecar: report names it" says ".claude/settings.json.kit-new"
  out="$(cd "$d" && ./ops/check-agent-kit.sh 2>&1)" && rc=0 || rc=$?
  expect "install writes a sidecar: the check fails until it is merged" \
    says "FAIL: .claude/settings.json.kit-new is the kit's copy"
  install_run "$d"; expect "install refuses: an unmerged sidecar" refused ".claude/settings.json.kit-new exists"

  d="$(v1_adopter dry)"; install_run "$d" --dry-run --from v1.0.0
  expect "install dry run: says would write" says "would write ops/agent/stop_gate.py"
  expect "install dry run: changes nothing" clean "$d"

  d="$(v1_adopter rep)"
  edit "$d/.codex/hooks.json" '"command": "python3 ' '"command": "AGENT_KIT_STATUS_GATE=0 python3 '
  commit_in "$d" "silence the status gate"; install_run "$d" --from v1.0.0
  expect "install report: core.hooksPath step" says "config core.hooksPath .githooks"
  expect "install report: AGENTS.md rules from the kit" says "Classify each change after reading the code"
  expect "install report: AGENT_KIT_STATUS_GATE hits" says ".codex/hooks.json"
  touch "$d/stray.txt"; install_run "$d"
  expect "install refuses: a dirty target" refused "has uncommitted changes; commit or stash them"

  nogit="$work/nogit"; mkdir -p "$nogit"; install_run "$nogit"
  expect "install refuses: not a git work tree" refused "$nogit is not a git work tree"
  install_run "$kit"; expect "install refuses: the kit itself" refused "is this kit's own repository"

  d="$(v1_adopter abs)"; (cd "$d" && git rm -q .github/workflows/agent-kit.yml); commit_in "$d" "drop CI"
  install_run "$d" --from v1.0.0
  expect "install absent shared files: optional one reported" says ".github/workflows/agent-kit.yml is absent"
  expect "install absent shared files: optional one not written" test ! -e "$d/.github/workflows/agent-kit.yml"
  expect "install absent shared files: required one written" test -f "$d/ops/agent/non-code-paths.txt"

  d="$(v1_adopter keep)"
  python3 - "$d/.claude/settings.json" <<'PY'
import json, re, sys, pathlib
p = pathlib.Path(sys.argv[1])
t, n = re.subn(r',\n    "SessionEnd": \[\n.*?\n    \]', "", p.read_text(), count=1, flags=re.S)
assert n == 1, "SessionEnd block not found"
json.loads(t)
p.write_text(t)
PY
  commit_in "$d" "leave out the session-end stamp"; install_run "$d" --from v1.0.0
  known_failure "install sidecar keeps a hook the adopter removed" hook_stays_out "$d"

  d="$(v1_adopter noremote)"; install_run "$d" --from v1.0.0
  known_failure "install closing steps fit a repository without a remote" no_pull_request_step

  d="$(v1_adopter ownrules)"
  python3 - "$d/AGENTS.md" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
t, n = re.subn(r"^1\. .*?(?=^2\. )", "1. Notes are append-only: add files, never edit one.\n",
               p.read_text(), count=1, flags=re.M | re.S)
assert n == 1, "rule 1 not found"
p.write_text(t)
PY
  commit_in "$d" "put our own rule first"; install_run "$d" --from v1.0.0
  known_failure "install AGENTS.md step fits an adopter with its own rules" own_rules_respected

  d="$(v1_adopter skills)"; mkdir -p "$d/.agents/skills/my-skill" "$d/.claude/skills"
  printf -- '---\nname: my-skill\ndescription: An adopter skill.\n---\nBody.\n' > "$d/.agents/skills/my-skill/SKILL.md"
  ln -s ../../.agents/skills/my-skill "$d/.claude/skills/my-skill"
  commit_in "$d" "add our own skill"; install_run "$d" --from v1.0.0
  expect "install skills: every kit- skill folder equals the kit's" kit_skills_match "$d"
  expect "install skills: every kit- skill gets its link" kit_links_match "$d"
  expect "install skills: the adopter's own skill stays byte-unchanged" \
    git -C "$d" diff --quiet HEAD -- .agents/skills/my-skill .claude/skills/my-skill
  check_expect ok "install skills: the kit check passes" "$d"
  commit_in "$d" "update the kit"; install_run "$d"
  expect "install skills: a second run writes nothing" says "Nothing to write"

  d="$(v1_adopter skilldir)"; mkdir -p "$d/.claude/skills/kit-debug"
  echo "a Claude-only copy" > "$d/.claude/skills/kit-debug/SKILL.md"
  commit_in "$d" "keep our own copy"; install_run "$d" --from v1.0.0
  expect "install skills keep a real directory: left alone" \
    git -C "$d" diff --quiet HEAD -- .claude/skills/kit-debug
  expect "install skills keep a real directory: reported" says ".claude/skills/kit-debug is a real file or directory"
else
  echo "skip install.sh cases: tag v1.0.0 is not in this clone (fetch tags to run them)"
fi

echo; echo "$passed passed, $failed failed, $known known failures (ROADMAP Next)"
[ "$failed" -eq 0 ]
