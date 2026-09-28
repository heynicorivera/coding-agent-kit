#!/usr/bin/env python3
"""Pre-finish gate for the agent kit: the turn may end only if the changed code verifies.

Wired as Claude Code and Copilot CLI `Stop` (.claude/settings.json), Codex `Stop`
(.codex/hooks.json), Cursor `stop` (.cursor/hooks.json) and Copilot `agentStop`
(.github/hooks/agent-kit.json). Reads the hook payload on stdin and answers in the shape each
tool documents. Rules: fail-open on any internal error; an unconfigured ops/verify.sh disables
the test gate; three consecutive blocks let the turn end with a warning. State and a one-line
log per decision live in ~/.cache/agent-kit/<repo-key>/, never in the repository.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

MAX_STRIKES = 3
VERIFY_TIMEOUT = int(os.environ.get("AGENT_KIT_VERIFY_TIMEOUT", "300"))
MEMORY_PREFIX = "docs/agent/"
STATUS_GATE = os.environ.get("AGENT_KIT_STATUS_GATE", "1") != "0"
CLAIM = re.compile(
    r"\b(done|finished|completed?|implemented|fixed|resolved|ready|tests? (pass|passed|passes))\b", re.I
)


def git(root: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=root, capture_output=True, text=True, timeout=30).stdout


def changed_code_paths(root: Path) -> list[str]:
    paths = []
    for line in git(root, "status", "--porcelain").splitlines():
        path = line[3:].split(" -> ")[-1].strip().strip('"')
        if path and not path.startswith(MEMORY_PREFIX):
            paths.append(path)
    return paths


def change_digest(root: Path, paths: list[str]) -> str:
    digest = hashlib.sha256(git(root, "diff", "HEAD").encode())
    for path in paths:
        target = root / path
        if target.exists():
            stat = target.stat()
            digest.update(f"{path}:{stat.st_size}:{int(stat.st_mtime)}".encode())
    return digest.hexdigest()


def state_dir(root: Path) -> Path:
    key = hashlib.sha256(str(root).encode()).hexdigest()[:16]
    base = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    folder = base / "agent-kit" / key
    folder.mkdir(parents=True, exist_ok=True)
    return folder


def record(folder: Path, consumer: str, outcome: str) -> None:
    with (folder / "gate.log").open("a", encoding="utf-8") as log:
        log.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} · {consumer} · {outcome}\n")


def load_state(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def run_verify(root: Path) -> tuple[str, str]:
    script = root / "ops" / "verify.sh"
    if not script.exists() or "KIT-PLACEHOLDER" in script.read_text(errors="replace"):
        return "unconfigured", ""
    try:
        proc = subprocess.run([str(script)], cwd=root, capture_output=True, text=True, timeout=VERIFY_TIMEOUT)
    except subprocess.TimeoutExpired:
        return "fail", f"./ops/verify.sh timed out after {VERIFY_TIMEOUT}s"
    tail = "\n".join((proc.stdout + proc.stderr).splitlines()[-40:])
    return ("pass" if proc.returncode == 0 else "fail"), tail


def status_is_stale(root: Path, paths: list[str]) -> bool:
    status = root / MEMORY_PREFIX / "STATUS.md"
    existing = [root / p for p in paths if (root / p).exists()]
    if not existing:
        return False
    if not status.exists():
        return True
    return status.stat().st_mtime < max(p.stat().st_mtime for p in existing)


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


def gate(consumer: str, payload: dict) -> str | None:
    root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel").strip() or Path.cwd())
    paths = changed_code_paths(root)
    if not paths:
        return None
    folder = state_dir(root)
    store = folder / "stop-gate.json"
    state = load_state(store)
    digest = change_digest(root, paths)
    if state.get("last_pass") != digest:
        result, tail = run_verify(root)
        if result == "unconfigured":
            record(folder, consumer, "unconfigured")
            sys.stderr.write("stop-gate: ops/verify.sh is not configured; test gate skipped.\n")
        elif result == "fail":
            state["strikes"] = state.get("strikes", 0) + 1
            if state["strikes"] >= MAX_STRIKES:
                state["strikes"] = 0
                store.write_text(json.dumps(state))
                record(folder, consumer, "breaker")
                sys.stderr.write("stop-gate: verification failed 3 times in a row; letting the turn end. "
                                 "Run ./ops/verify.sh yourself.\n")
                return None
            store.write_text(json.dumps(state))
            record(folder, consumer, "block-verify")
            return ("./ops/verify.sh FAILED. Last lines:\n" + tail + "\n\nFix the failures, then finish. "
                    "Do not weaken or skip tests. Do not edit ops/verify.sh, the kit check, hooks or CI.")
        else:
            state.update(last_pass=digest, strikes=0)
            store.write_text(json.dumps(state))
    if not STATUS_GATE or state.get("status_blocked_for") == digest:
        record(folder, consumer, "allow")
        return None
    message = payload.get("last_assistant_message") or ""
    claims = bool(CLAIM.search(message)) if consumer in ("claude", "codex") else True
    if claims and status_is_stale(root, paths):
        state["status_blocked_for"] = digest
        store.write_text(json.dumps(state))
        record(folder, consumer, "block-status")
        return ("Code changed but docs/agent/STATUS.md is older than the changes. Before presenting, rewrite "
                "STATUS.md: what changed, verification: (verified | partial | failed) with the command and "
                "commit, and what is next. Keep it under 60 lines.")
    record(folder, consumer, "allow")
    return None


def main() -> None:
    consumer = sys.argv[sys.argv.index("--consumer") + 1] if "--consumer" in sys.argv else "claude"
    try:
        payload = json.loads(sys.stdin.read() or "{}") if not sys.stdin.isatty() else {}
    except ValueError:
        payload = {}
    try:
        respond(consumer, gate(consumer, payload))
    except SystemExit:
        raise
    except Exception as exc:  # fail-open: a broken gate must never trap the agent
        sys.stderr.write(f"stop-gate: internal error, letting the turn end: {exc}\n")
        sys.exit(0)


if __name__ == "__main__":
    main()
