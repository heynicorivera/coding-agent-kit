#!/usr/bin/env bash
# Updates the agent kit in an adopter repository from this kit checkout.
#   ./install.sh [--dry-run] [--from <kit tag or commit>] <target-repo>
# Kit-owned files are overwritten. Adopter-owned files are never written. A shared file is
# overwritten only if the adopter never patched it; otherwise the kit's copy lands next to it as
# <path>.kit-new for a human to merge. The kit version is stamped into ops/agent/KIT_VERSION, which
# is the default --from of the next run. The run ends with the steps left to a human.
set -euo pipefail

KIT_OWNED=(
  ops/check-agent-kit.sh ops/agent/stop_gate.py ops/agent/session-start.sh
  ops/agent/session-end.sh ops/agent/changes.py .githooks/pre-commit docs/agent/ONBOARD.md
  docs/agent/changes/_template.md docs/agent/specs/_template.md
)
SHARED_REQUIRED=(ops/agent/non-code-paths.txt)
SHARED_OPTIONAL=(.claude/settings.json .github/workflows/agent-kit.yml .gitignore)
ADOPTER_OWNED=(
  AGENTS.md CLAUDE.md ops/verify.sh docs/agent/STATUS.md docs/agent/DECISIONS.md
  docs/agent/LEARNINGS.md
)
STAMP=ops/agent/KIT_VERSION

kit="$(cd "$(dirname "$0")" && pwd)"
dry_run=0
from=""
target=""
written=()
sidecars=()
notes=()

usage() {
  echo "usage: ./install.sh [--dry-run] [--from <kit tag or commit>] <target-repo>" >&2
  exit 2
}

die() {
  echo "install.sh: $*" >&2
  exit 1
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1 ;;
      --from)
        [ "$#" -ge 2 ] || usage
        from="$2"
        shift
        ;;
      -h | --help) usage ;;
      -*) usage ;;
      *)
        [ -z "$target" ] || usage
        target="$1"
        ;;
    esac
    shift
  done
  [ -n "$target" ] || usage
}

common_dir() { git -C "$1" rev-parse --path-format=absolute --git-common-dir; }

check_target() {
  git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "$target is not a git work tree."
  target="$(git -C "$target" rev-parse --show-toplevel)"
  [ "$(common_dir "$target")" != "$(common_dir "$kit")" ] \
    || die "$target is this kit's own repository; run it against an adopter."
  local rel
  for rel in "${SHARED_REQUIRED[@]}" "${SHARED_OPTIONAL[@]}"; do
    [ ! -e "$target/$rel.kit-new" ] \
      || die "$rel.kit-new exists in $target; merge it into $rel, delete it, commit, then rerun."
  done
  [ -z "$(git -C "$target" status --porcelain --untracked-files=all)" ] \
    || die "$target has uncommitted changes; commit or stash them so the update is its own diff."
}

kit_version() { git -C "$kit" describe --tags --always --dirty; }

resolve_from() {  # sets from to a commit-ish in the kit, or "" when the old kit is unknown
  local given="$from"
  if [ -z "$from" ] && [ -f "$target/$STAMP" ]; then
    from="$(tr -d '[:space:]' <"$target/$STAMP")"
  fi
  from="${from%-dirty}"
  [ -n "$from" ] || return 0
  if ! git -C "$kit" rev-parse --verify -q "$from^{commit}" >/dev/null; then
    [ -z "$given" ] || die "--from $given is not a commit in $kit."
    notes+=("$STAMP names $from, unknown to this kit checkout; shared files count as patched.")
    from=""
  fi
}

same_file() {  # same_file <a> <b>: same content and same executable bit
  cmp -s "$1" "$2" || return 1
  if [ -x "$1" ]; then [ -x "$2" ]; else [ ! -x "$2" ]; fi
}

put() {  # put <source-file> <rel>: the only function that writes into the target
  local src="$1" rel="$2" dst="$target/$2" mode=644
  [ -e "$dst" ] && same_file "$src" "$dst" && return 0
  written+=("$rel")
  [ "$dry_run" -eq 0 ] || return 0
  [ -x "$src" ] && mode=755
  mkdir -p "$(dirname "$dst")"
  install -m "$mode" "$src" "$dst"
}

sync_owned() {
  local rel
  for rel in "${KIT_OWNED[@]}"; do put "$kit/$rel" "$rel"; done
}

old_copy() {  # old_copy <rel> <file>: the kit's file at --from; fails when unknown
  [ -n "$from" ] && git -C "$kit" cat-file -e "$from:$1" 2>/dev/null \
    && git -C "$kit" show "$from:$1" >"$2"
}

sync_one_shared() {  # sync_one_shared <rel> <required|optional> <scratch-dir>
  local rel="$1" kind="$2" old="$3/old" new="$kit/$1" dst="$target/$1"
  if [ ! -e "$dst" ] && [ "$kind" = required ]; then
    put "$new" "$rel"
    return 0
  fi
  if [ ! -e "$dst" ]; then
    notes+=("$rel is absent here and was not added; copy it from the kit if you want it.")
    return 0
  fi
  cmp -s "$dst" "$new" && return 0
  if old_copy "$rel" "$old"; then
    cmp -s "$old" "$new" && return 0
    if cmp -s "$dst" "$old"; then
      put "$new" "$rel"
      return 0
    fi
  fi
  sidecars+=("$rel")
  echo "--- $rel: local version vs the kit's (written to $rel.kit-new)"
  diff -u "$dst" "$new" || true
  [ "$dry_run" -eq 1 ] || install -m 644 "$new" "$dst.kit-new"
}

sync_shared() {
  local scratch rel
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/kit-install.XXXXXX")"
  for rel in "${SHARED_REQUIRED[@]}"; do sync_one_shared "$rel" required "$scratch"; done
  for rel in "${SHARED_OPTIONAL[@]}"; do sync_one_shared "$rel" optional "$scratch"; done
  rm -r -- "$scratch"
}

write_stamp() {
  local version scratch
  version="$(kit_version)"
  case "$version" in
    *-dirty) notes+=("This kit checkout has uncommitted changes; the stamp says $version.") ;;
  esac
  scratch="$(mktemp "${TMPDIR:-/tmp}/kit-version.XXXXXX")"
  echo "$version" >"$scratch"
  put "$scratch" "$STAMP"
  rm -- "$scratch"
}

before_v2() {  # true when the old kit is unknown or older than v2.0.0
  [ -z "$from" ] && return 0
  ! git -C "$kit" merge-base --is-ancestor v2.0.0 "$from" 2>/dev/null
}

report_files() {
  local verb=wrote rel
  [ "$dry_run" -eq 0 ] || verb="would write"
  echo
  echo "== Kit $(kit_version) into $target (from ${from:-unknown}) =="
  if [ "${#written[@]}" -eq 0 ]; then echo "Nothing to write; kit files are current."; fi
  for rel in ${written[@]+"${written[@]}"}; do echo "$verb $rel"; done
  for rel in ${sidecars[@]+"${sidecars[@]}"}; do
    echo "$verb $rel.kit-new (patched here and changed in the kit; diff above)"
  done
  for rel in "${ADOPTER_OWNED[@]}"; do
    [ -e "$target/$rel" ] || echo "MISSING $rel: adopter-owned; copy it from the kit, fill it in."
  done
  for rel in ${notes[@]+"${notes[@]}"}; do echo "NOTE: $rel"; done
}

report_steps() {
  local n=1 hits rel
  echo
  echo "== Left to you, in order =="
  for rel in ${sidecars[@]+"${sidecars[@]}"}; do
    echo "$n. Merge $rel.kit-new into $rel by hand, then delete the .kit-new file."
    n=$((n + 1))
  done
  if [ "$(git -C "$target" config core.hooksPath || true)" != .githooks ]; then
    echo "$n. Enable the pre-commit gate: git -C $target config core.hooksPath .githooks"
    n=$((n + 1))
  fi
  if before_v2; then
    echo "$n. AGENTS.md: make rules 1-3 say what the kit's say (keep your own wording elsewhere):"
    awk '/^## Rules/{p=1;next} /^4\. /{p=0} p' "$kit/AGENTS.md" | sed 's/^/     /'
    n=$((n + 1))
  fi
  hits="$( (cd "$target" && grep -rnI AGENT_KIT_STATUS_GATE -- .claude .codex .cursor .gemini \
    .github .aider.conf.yml 2>/dev/null) || true)"
  if [ -n "$hits" ]; then
    echo "$n. Rename AGENT_KIT_STATUS_GATE to AGENT_KIT_NUDGES in:"
    printf '%s\n' "$hits" | sed 's/^/     /'
    n=$((n + 1))
  fi
  echo "$n. Rewrite docs/agent/STATUS.md and append a dated entry to docs/agent/DECISIONS.md."
  echo "$((n + 1)). Run ./ops/verify.sh, commit on a branch, open a pull request."
  echo "$((n + 2)). Start agent sessions only after that commit; the stop gate blocks on gate"
  echo "   files that changed after a session began."
}

main() {
  parse_args "$@"
  check_target
  resolve_from
  sync_owned
  sync_shared
  write_stamp
  report_files
  report_steps
}

main "$@"
