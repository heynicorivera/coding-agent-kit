#!/usr/bin/env bash
# shellcheck disable=SC2016  # test fixtures contain literal $(...) and backticks that must not expand
# Self-test for the agent kit. Copies the kit into temporary git repositories and proves that the
# check fails on each broken rule, that the session-end stamp fires only when it should, and that
# the stop gate answers each tool in its documented shape. Exit 1 if any case fails.
set -euo pipefail
kit="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/agent-kit-test.XXXXXX")"
export XDG_CACHE_HOME="$work/cache"
trap 'rm -r -- "$work"' EXIT
passed=0; failed=0
ok()  { passed=$((passed + 1)); echo "ok   $1"; }
bad() { failed=$((failed + 1)); echo "FAIL $1"; }

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
  python3 - "$dir/ops/verify.sh" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
p.write_text(re.sub(r"# KIT-PLACEHOLDER.*", "true  # verification configured by test-kit\n", t, flags=re.S))
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

gate() {  # gate <dir> <consumer> <payload-json>: sets rc, out, err
  local dir="$1" consumer="$2" payload="$3"
  rc=0
  out="$(cd "$dir" && printf '%s' "$payload" | python3 ops/agent/stop_gate.py --consumer "$consumer" 2>"$work/err")" || rc=$?
  err="$(cat "$work/err")"
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
d="$(fresh_copy unconfigured)"; edit "$d/ops/verify.sh" "true  # verification configured by test-kit" $'# KIT-PLACEHOLDER restored\ntrue'
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

echo "== session-end.sh =="
d="$(fresh_copy stamp)"; (cd "$d" && echo y > dirty.txt && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then ok "stamps a dirty tree"; else bad "stamps a dirty tree"; fi
d="$(fresh_copy nostamp)"; (cd "$d" && echo y > dirty.txt && echo "- touched" >> docs/agent/STATUS.md && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then bad "skips when STATUS.md was edited"; else ok "skips when STATUS.md was edited"; fi
d="$(fresh_copy clean)"; (cd "$d" && ./ops/agent/session-end.sh)
if grep -q 'Session ended without wrap-up' "$d/docs/agent/STATUS.md"; then bad "skips a clean tree"; else ok "skips a clean tree"; fi

echo "== stop_gate.py =="
d="$(fresh_copy gate)"
gate "$d" claude '{}'; if [ "$rc" -eq 0 ]; then ok "clean tree allows"; else bad "clean tree allows (rc $rc)"; fi
edit "$d/ops/verify.sh" "true  # verification configured by test-kit" "false  # failing verification"
mkdir -p "$d/src"; echo x > "$d/src/new.txt"
gate "$d" claude '{"last_assistant_message":"Done."}'
if [ "$rc" -eq 2 ] && grep -q 'FAILED' <<<"$err"; then ok "failing verify blocks (claude: exit 2)"; else bad "failing verify blocks (rc $rc)"; fi
gate "$d" codex '{}'
if [ "$rc" -eq 0 ] && grep -q '"decision": "block"' <<<"$out"; then ok "failing verify blocks (codex: JSON)"; else bad "failing verify blocks codex (rc $rc: $out)"; fi
gate "$d" copilot '{}'
if [ "$rc" -eq 0 ] && grep -q '3 times' <<<"$err" && [ -z "$out" ]; then ok "three failures trip the breaker"; else bad "three failures trip the breaker (rc $rc: $out / $err)"; fi
gate "$d" cursor '{}'
if [ "$rc" -eq 0 ] && grep -q 'followup_message' <<<"$out"; then ok "failing verify blocks (cursor: follow-up)"; else bad "failing verify blocks cursor (rc $rc: $out)"; fi
edit "$d/ops/verify.sh" "false  # failing verification" "true  # passing again"
touch -t 202001010000 "$d/docs/agent/STATUS.md"
gate "$d" claude '{"last_assistant_message":"All done, tests pass."}'
if [ "$rc" -eq 2 ] && grep -q 'STATUS.md' <<<"$err"; then ok "stale STATUS.md blocks a completion claim"; else bad "stale STATUS.md blocks (rc $rc: $err)"; fi
gate "$d" claude '{"last_assistant_message":"Done."}'
if [ "$rc" -eq 0 ]; then ok "STATUS block fires once per change set"; else bad "STATUS block fires once (rc $rc)"; fi
echo y >> "$d/src/new.txt"; sleep 1; touch "$d/docs/agent/STATUS.md"
gate "$d" claude '{"last_assistant_message":"Done."}'
if [ "$rc" -eq 0 ]; then ok "fresh STATUS.md allows"; else bad "fresh STATUS.md allows (rc $rc: $err)"; fi
d="$(fresh_copy gateunconf)"; edit "$d/ops/verify.sh" "true  # verification configured by test-kit" $'# KIT-PLACEHOLDER restored\ntrue'
echo x > "$d/new.txt"; gate "$d" claude '{}'
if [ "$rc" -eq 0 ] && grep -q 'not configured' <<<"$err"; then ok "unconfigured verify.sh skips the test gate"; else bad "unconfigured verify.sh skips (rc $rc: $err)"; fi
if find "$work/cache" -name gate.log | grep -q .; then ok "gate writes its log"; else bad "gate writes its log"; fi

echo; echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
