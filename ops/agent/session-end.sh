#!/usr/bin/env bash
# Safety net for a session that ends without a wrap-up. The model is already gone when
# SessionEnd fires, so this cannot write a summary. If the working tree has uncommitted
# changes and STATUS.md was not touched, end STATUS.md with a dated warning so the next
# session's briefing starts with it. The warning replaces any earlier one, so repeated unclean
# exits cannot push STATUS.md past its 60-line cap.
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
stamp="> Session ended without wrap-up on $(date '+%Y-%m-%d %H:%M'). Uncommitted: $files"
python3 - "$status" "$stamp" <<'PY'
import pathlib, sys
path, stamp = pathlib.Path(sys.argv[1]), sys.argv[2]
kept = [line for line in path.read_text().splitlines()
        if not line.startswith("> Session ended without wrap-up")]
while kept and not kept[-1].strip():
    kept.pop()
path.write_text("\n".join(kept + ["", stamp]) + "\n")
PY
