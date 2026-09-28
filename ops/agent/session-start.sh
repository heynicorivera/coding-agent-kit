#!/usr/bin/env bash
# Prints docs/agent/STATUS.md and the active learnings so a session-start hook can put them into
# the agent's context. Claude Code and Codex take plain stdout; Cursor takes JSON (--format cursor).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
format=plain
[ "${1:-}" = "--format" ] && format="${2:-plain}"
status="docs/agent/STATUS.md"
learnings="docs/agent/LEARNINGS.md"
body=""
if [ -f "$status" ]; then
  body="Injected by the agent kit. Contents of $status:"$'\n\n'"$(cat "$status")"
else
  body="session-start: $status not found; restore it from the starter kit"
fi
if [ -f "$learnings" ]; then
  active="$(awk '/^## Active/{p=1;next} /^## /{p=0} p' "$learnings" | head -40)"
  [ -n "$active" ] && body="$body"$'\n\n'"Active learnings ($learnings):"$'\n'"$active"
fi
case "$format" in
  cursor) printf '%s' "$body" | python3 -c 'import json,sys; print(json.dumps({"additional_context": sys.stdin.read()}))' ;;
  *) printf '%s\n' "$body" ;;
esac
