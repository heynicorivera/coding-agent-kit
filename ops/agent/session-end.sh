#!/usr/bin/env bash
# Safety net for a session that ends without a wrap-up. The model is already gone when
# SessionEnd fires, so this cannot write a summary. If the working tree has uncommitted
# changes and STATUS.md was not touched, append a dated warning to STATUS.md so the next
# session's briefing starts with it.
set -euo pipefail
cd "$(dirname "$0")/../.."
status="docs/agent/STATUS.md"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -f "$status" ] || exit 0
changes="$(git status --porcelain)"
[ -n "$changes" ] || exit 0
if printf '%s\n' "$changes" | cut -c4- | grep -qx "$status"; then
  exit 0
fi
files="$(printf '%s\n' "$changes" | cut -c4- | tr '\n' ' ')"
printf '\n> Session ended without wrap-up on %s. Uncommitted: %s\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$files" >> "$status"
