#!/usr/bin/env python3
"""Pre-finish gate for the agent kit: the turn may end only if the changed code verifies.

Wired as Claude Code and Copilot CLI `Stop` (.claude/settings.json), Codex `Stop`
(.codex/hooks.json), Cursor `stop` (.cursor/hooks.json) and Copilot `agentStop`
(.github/hooks/agent-kit.json). Reads the hook payload on stdin and answers in the shape each
tool documents. `--save-base`, run by session-start.sh, records HEAD as the session base.

Changes are measured from the session base (else the merge-base with the upstream branch, else
HEAD), so commits made during the session count. Paths in ops/agent/non-code-paths.txt are not
code. A gate file changed since the base blocks like a failing ops/verify.sh, and whether
verify.sh is configured is read from the base, never from the working tree. Rules: fail-open on
any internal error; three consecutive blocks let the turn end with a warning; the STATUS.md and
change-file nudges block once per set of changes. State and a one-line log per decision live in
~/.cache/agent-kit/<repo-key>/, never in the repository.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

MAX_STRIKES = 3
VERIFY_TIMEOUT = int(os.environ.get("AGENT_KIT_VERIFY_TIMEOUT", "300"))
NUDGES = os.environ.get("AGENT_KIT_NUDGES", "1") != "0"
GATE_PATHS = (
    "ops/verify.sh", "ops/check-agent-kit.sh", "ops/agent", ".githooks", ".claude/settings.json",
    ".codex", ".cursor/hooks.json", ".github/hooks", ".github/workflows",
)
NON_CODE_LIST = "ops/agent/non-code-paths.txt"
STATUS_FILE = "docs/agent/STATUS.md"
CHANGES_DIR = "docs/agent/changes"
CHANGE_TEMPLATE = CHANGES_DIR + "/_template.md"
CHANGE_FILE_LIMIT = 3
CHANGE_LINE_LIMIT = 50
CLAIM = re.compile(
    r"\b(done|finished|completed?|implemented|fixed|resolved|ready|tests? (pass|passed|passes))\b",
    re.I,
)
OPEN_CHANGE = re.compile(r"^status:\s*open\b", re.M)
VERIFY_FAILED = (
    "./ops/verify.sh FAILED. Last lines:\n{tail}\n\nFix the failures, then finish. "
    "Do not weaken or skip tests. Do not edit ops/verify.sh, the kit check, hooks or CI."
)
GATE_FILES_CHANGED = (
    "Gate files changed since this session began (base {base}): {paths}. The gate does not run "
    "ops/verify.sh against changed gate files. If you changed them, restore them with "
    "`git checkout {base} -- <path>` and delete files you added. If the user asked for this "
    "change, tell them it needs their review and commit, and a new session."
)
STATUS_NUDGE = (
    "Code changed but docs/agent/STATUS.md is older than the changes. Before presenting, rewrite "
    "STATUS.md: what changed, verification: (verified | partial | failed) with the command and "
    "commit, and what is next. Keep it under 60 lines."
)
MISSING_CHANGE_NUDGE = (
    "This change touches {files} code file(s) and {lines} line(s), and no change file under "
    "docs/agent/changes/ was written or updated. If it is T1 or T2 (AGENTS.md rule 3), copy "
    "docs/agent/changes/_template.md, fill Intent, Tier, Acceptance and Tasks, and close it with "
    "Evidence. If it is T0, say so and finish."
)
OPEN_CHANGE_NUDGE = (
    "Change file(s) still open: {paths}. If the work is done, fill Evidence, tick the Tasks and "
    "set status: closed. If not, say what remains."
)


def git(root: Path, *args: str) -> str:
    proc = subprocess.run(["git", *args], cwd=root, capture_output=True, text=True, timeout=30)
    return proc.stdout


def repo_root() -> Path:
    return Path(git(Path.cwd(), "rev-parse", "--show-toplevel").strip() or Path.cwd())


def state_dir(root: Path) -> Path:
    key = hashlib.sha256(str(root).encode()).hexdigest()[:16]
    base = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    folder = base / "agent-kit" / key
    folder.mkdir(parents=True, exist_ok=True)
    return folder


def load_state(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def save_base(payload: dict) -> None:
    """Records HEAD as the session base. Compaction keeps the base of the running session."""
    if payload.get("source") == "compact":
        return
    root = repo_root()
    target = state_dir(root) / "session-base"
    head = git(root, "rev-parse", "--verify", "-q", "HEAD").strip()
    if head:
        target.write_text(head + "\n")
    elif target.exists():
        target.unlink()


def session_base(root: Path, folder: Path) -> str:
    saved = folder / "session-base"
    if saved.exists():
        commit = saved.read_text().strip() + "^{commit}"
        base = git(root, "rev-parse", "--verify", "-q", commit).strip()
        if base:
            return base
    upstream = git(root, "merge-base", "HEAD", "@{upstream}").strip()
    return upstream or git(root, "rev-parse", "--verify", "-q", "HEAD").strip()


def code_pathspecs(root: Path) -> list[str]:
    specs = ["."]
    listing = root / NON_CODE_LIST
    if listing.exists():
        for line in listing.read_text().splitlines():
            entry = line.strip()
            if entry and not entry.startswith("#"):
                specs.append(":(exclude)" + entry)
    return specs


def changed_paths(root: Path, base: str, pathspecs: list[str] | tuple[str, ...]) -> list[str]:
    tracked = git(root, "diff", "--name-only", "--no-renames", "-z", base, "--", *pathspecs)
    untracked = git(root, "ls-files", "--others", "--exclude-standard", "-z", "--", *pathspecs)
    return sorted({path for path in (tracked + "\0" + untracked).split("\0") if path})


def changed_lines(root: Path, base: str, pathspecs: list[str]) -> int:
    total = 0
    for row in git(root, "diff", "--numstat", "--no-renames", base, "--", *pathspecs).splitlines():
        added, deleted = row.split("\t")[:2]
        if added.isdigit() and deleted.isdigit():
            total += int(added) + int(deleted)
    untracked = git(root, "ls-files", "--others", "--exclude-standard", "-z", "--", *pathspecs)
    for path in filter(None, untracked.split("\0")):
        total += (root / path).read_bytes().count(b"\n")
    return total


def change_digest(root: Path, base: str, pathspecs: list[str], paths: list[str]) -> str:
    digest = hashlib.sha256(base.encode())
    digest.update(git(root, "diff", "--no-renames", base, "--", *pathspecs).encode())
    for path in paths:
        target = root / path
        if target.exists():
            stat = target.stat()
            digest.update(f"{path}:{stat.st_size}:{int(stat.st_mtime)}:{stat.st_mode}".encode())
    return digest.hexdigest()


def run_verify(root: Path, base: str) -> tuple[str, str]:
    at_base = git(root, "show", f"{base}:ops/verify.sh")
    if not at_base or "KIT-PLACEHOLDER" in at_base:
        return "unconfigured", ""
    script = root / "ops" / "verify.sh"
    if not os.access(script, os.X_OK):
        return "fail", "ops/verify.sh is missing or not executable."
    try:
        proc = subprocess.run(
            [str(script)], cwd=root, capture_output=True, text=True, timeout=VERIFY_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        return "fail", f"./ops/verify.sh timed out after {VERIFY_TIMEOUT}s"
    tail = "\n".join((proc.stdout + proc.stderr).splitlines()[-40:])
    return ("pass" if proc.returncode == 0 else "fail"), tail


def status_is_stale(root: Path, paths: list[str]) -> bool:
    status = root / STATUS_FILE
    existing = [root / p for p in paths if (root / p).exists()]
    if not existing:
        return False
    if not status.exists():
        return True
    return status.stat().st_mtime < max(p.stat().st_mtime for p in existing)


@dataclass
class Turn:
    root: Path
    folder: Path
    consumer: str
    base: str
    digest: str
    state: dict

    def save(self) -> None:
        (self.folder / "stop-gate.json").write_text(json.dumps(self.state))

    def log(self, outcome: str) -> None:
        with (self.folder / "gate.log").open("a", encoding="utf-8") as log:
            log.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} · {self.consumer} · {outcome}\n")


def verification_failure(turn: Turn, tampered: list[str]) -> str | None:
    if tampered:
        return GATE_FILES_CHANGED.format(base=turn.base[:12], paths=", ".join(tampered))
    if turn.state.get("last_pass") == turn.digest:
        return None
    result, tail = run_verify(turn.root, turn.base)
    if result == "unconfigured":
        turn.log("unconfigured")
        sys.stderr.write("stop-gate: ops/verify.sh is not configured; test gate skipped.\n")
        return None
    if result == "fail":
        return VERIFY_FAILED.format(tail=tail)
    turn.state.update(last_pass=turn.digest, strikes=0)
    turn.save()
    return None


def strike(turn: Turn, reason: str, outcome: str) -> str | None:
    turn.state["strikes"] = turn.state.get("strikes", 0) + 1
    if turn.state["strikes"] < MAX_STRIKES:
        turn.save()
        turn.log(outcome)
        return reason
    turn.state["strikes"] = 0
    turn.save()
    turn.log("breaker")
    sys.stderr.write(f"stop-gate: blocked {MAX_STRIKES} times in a row; letting the turn end. "
                     "Run ./ops/verify.sh and review gate-file changes yourself.\n")
    return None


def change_file_nudges(turn: Turn, code: list[str], pathspecs: list[str]) -> list[str]:
    touched = [p for p in changed_paths(turn.root, turn.base, [CHANGES_DIR])
               if p.endswith(".md") and p != CHANGE_TEMPLATE and (turn.root / p).exists()]
    if touched:
        still_open = [p for p in touched
                      if OPEN_CHANGE.search((turn.root / p).read_text(errors="replace"))]
        return [OPEN_CHANGE_NUDGE.format(paths=", ".join(still_open))] if still_open else []
    lines = changed_lines(turn.root, turn.base, pathspecs)
    if len(code) > CHANGE_FILE_LIMIT or lines > CHANGE_LINE_LIMIT:
        return [MISSING_CHANGE_NUDGE.format(files=len(code), lines=lines)]
    return []


def nudge(turn: Turn, payload: dict, code: list[str], pathspecs: list[str]) -> str | None:
    if not NUDGES or turn.state.get("nudged_for") == turn.digest:
        return None
    message = payload.get("last_assistant_message") or ""
    if turn.consumer in ("claude", "codex") and not CLAIM.search(message):
        return None
    reasons = change_file_nudges(turn, code, pathspecs)
    if status_is_stale(turn.root, code):
        reasons.append(STATUS_NUDGE)
    if not reasons:
        return None
    turn.state["nudged_for"] = turn.digest
    turn.save()
    turn.log("block-nudge")
    return "\n\n".join(reasons)


def gate(consumer: str, payload: dict) -> str | None:
    root = repo_root()
    folder = state_dir(root)
    base = session_base(root, folder)
    if not base:
        return None
    pathspecs = code_pathspecs(root)
    code = changed_paths(root, base, pathspecs)
    tampered = changed_paths(root, base, GATE_PATHS)
    if not code and not tampered:
        return None
    # verify.sh is always hashed: with core.fileMode=false git does not report a chmod.
    digest = change_digest(root, base, pathspecs, sorted({*code, *tampered, "ops/verify.sh"}))
    turn = Turn(root, folder, consumer, base, digest, load_state(folder / "stop-gate.json"))
    failure = verification_failure(turn, tampered)
    if failure is not None:
        return strike(turn, failure, "block-gate-files" if tampered else "block-verify")
    reason = nudge(turn, payload, code, pathspecs)
    if reason is None:
        turn.log("allow")
    return reason


def respond(consumer: str, reason: str | None) -> None:
    if reason is None:
        sys.exit(0)
    if consumer == "claude":
        sys.stderr.write(reason + "\n")
        sys.exit(2)
    shapes = {
        "cursor": {"followup_message": reason},
        "antigravity": {"decision": "continue", "reason": reason},
    }
    print(json.dumps(shapes.get(consumer, {"decision": "block", "reason": reason})))
    sys.exit(0)


def read_payload() -> dict:
    if sys.stdin.isatty():
        return {}
    try:
        return json.loads(sys.stdin.read() or "{}")
    except ValueError:
        return {}


def main() -> None:
    args = sys.argv[1:]
    consumer = args[args.index("--consumer") + 1] if "--consumer" in args else "claude"
    try:
        payload = read_payload()
        if "--save-base" in args:
            save_base(payload)
            sys.exit(0)
        respond(consumer, gate(consumer, payload))
    except SystemExit:
        raise
    except Exception as exc:  # fail-open: a broken gate must never trap the agent
        sys.stderr.write(f"stop-gate: internal error, letting the turn end: {exc}\n")
        sys.exit(0)


if __name__ == "__main__":
    main()
