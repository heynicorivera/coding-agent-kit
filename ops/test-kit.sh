#!/usr/bin/env bash
# shellcheck disable=SC2016  # test fixtures contain literal $(...) and backticks that must not expand
# Self-test for the agent kit. Copies the kit into temporary git repositories and proves that the
# check fails on each broken rule, that the session hooks behave, that the stop gate answers each
# tool in its documented shape and cannot be skipped by committing first or by changing gate files,
# that the pre-commit hook refuses failing commits, and that change files are checked and nudged.
# Exit 1 if any case fails.
set -euo pipefail
kit="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/agent-kit-test.XXXXXX")"
export XDG_CACHE_HOME="$work/cache"
trap 'rm -r -- "$work"' EXIT
passed=0; failed=0
ok()  { passed=$((passed + 1)); echo "ok   $1"; }
bad() { failed=$((failed + 1)); echo "FAIL $1"; }
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

change_file() {  # change_file <dir> <open|closed> <test-path>: write a well-formed change file
  cat > "$1/docs/agent/changes/demo.md" <<EOF
# Demo change
status: $2

## Intent
Show that the kit accepts a well-formed change file.

## Tier
T1 · a feature

## Acceptance
- Given a kit copy, when the check runs, then it passes · test: \`$3\`

## Tasks
- [x] write the change file

## Out of scope
- everything else

## Evidence
- verification: verified — command: \`./ops/verify.sh\` — at: 2026-10-06, uncommitted
- last lines: OK: agent kit checks passed
EOF
}

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
d="$(fresh_copy codexto)"; edit "$d/.codex/hooks.json" '"timeout": 3 }' '"timeout": 10 }'; check_expect fail "Codex SessionEnd timeout over 3 s" "$d"
d="$(fresh_copy unconfigured)"; edit "$d/ops/verify.sh" "$configured" $'# KIT-PLACEHOLDER restored\ntrue'
check_expect fail "verify.sh unconfigured on a filled project" "$d"
d="$(fresh_copy cred)"; echo "token: ghp_$(printf 'a%.0s' {1..36})" >> "$d/docs/agent/STATUS.md"; check_expect fail "credential pattern" "$d"
d="$(fresh_copy stale)"; echo '- see `src/nowhere/missing.py`' >> "$d/docs/agent/STATUS.md"; check_expect fail "stale path reference" "$d"
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
d="$(fresh_copy fresh)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; commit_in "$d" "feat: add file"
check_expect fail "code changed without STATUS.md in range" "$d" --range HEAD~1..HEAD
d="$(fresh_copy wip)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; commit_in "$d" "wip: scratch"
check_expect ok "wip commit exempt from freshness" "$d" --range HEAD~1..HEAD
d="$(fresh_copy freshok)"; mkdir -p "$d/src"; echo x > "$d/src/a.txt"; echo "- note" >> "$d/docs/agent/STATUS.md"; commit_in "$d" "feat: with status"
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
d="$(fresh_copy chopen)"; change_file "$d" open tests/not_written_yet.sh; check_expect ok "open change file passes" "$d"
d="$(fresh_copy chclosed)"; change_file "$d" closed ops/test-kit.sh; check_expect ok "closed change file with evidence passes" "$d"
d="$(fresh_copy chhead)"; change_file "$d" open x; edit "$d/docs/agent/changes/demo.md" "## Out of scope" "## Notes"
check_expect fail "change file missing a section" "$d"
d="$(fresh_copy chstatus)"; change_file "$d" open x; edit "$d/docs/agent/changes/demo.md" "status: open" "state: open"
check_expect fail "change file without status line" "$d"
d="$(fresh_copy chtest)"; change_file "$d" open x; edit "$d/docs/agent/changes/demo.md" ' · test: `x`' ""
check_expect fail "acceptance line without a test" "$d"
d="$(fresh_copy chgone)"; change_file "$d" closed tests/missing_test.sh; check_expect fail "closed change names a missing test" "$d"
d="$(fresh_copy chtask)"; change_file "$d" closed ops/test-kit.sh; edit "$d/docs/agent/changes/demo.md" "- [x]" "- [ ]"
check_expect fail "closed change with unchecked tasks" "$d"
d="$(fresh_copy chnoev)"; change_file "$d" closed ops/test-kit.sh
edit "$d/docs/agent/changes/demo.md" "- verification: verified" "- verification: <verified | partial | failed>"
check_expect fail "closed change without evidence" "$d"

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
change_file "$d" open src/f1.txt; touch "$d/docs/agent/STATUS.md"; claims_done "$d"; blocked "an open change file nudges on a claim" "still open"
d="$(fresh_copy nudgeclosed)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
change_file "$d" closed src/f1.txt; touch "$d/docs/agent/STATUS.md"; claims_done "$d"; allowed "a closed change file allows"
d="$(fresh_copy noclaim)"; start "$d"; mkdir -p "$d/src"; for i in 1 2 3 4; do echo x > "$d/src/f$i.txt"; done
gate "$d" claude '{"last_assistant_message":"Which option do you prefer?"}'; allowed "no completion claim, no nudge"

if find "$work/cache" -name gate.log | grep -q .; then ok "gate writes its log"; else bad "gate writes its log"; fi

echo; echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
