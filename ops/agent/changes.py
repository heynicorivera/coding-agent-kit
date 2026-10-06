#!/usr/bin/env python3
"""Change files and living specs for the agent kit.

    changes.py check [<base>]  Validate docs/agent/changes/*.md and docs/agent/specs/*.md. Prints
                               FAIL lines (exit 1) and advisory GAP lines: acceptance tests of open
                               changes that do not exist yet or are unchanged since <base>.
    changes.py archive <file>  For a closed change that passes the check: merge its Spec delta
                               into the living spec it names, then move the file to
                               docs/agent/changes/archive/<date>-<name>.md.

ops/check-agent-kit.sh runs `check`; the agent runs `archive` when a change is done. A Spec delta
lists requirement lines under ### ADDED (new ID, appended), ### MODIFIED (replaces the line with
the same ID) and ### REMOVED (deletes it). Requirement IDs look like AUTH-1.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHANGES = Path("docs/agent/changes")
SPECS = Path("docs/agent/specs")
TEMPLATE = "_template.md"
HEADINGS = ("Intent", "Tier", "Acceptance", "Tasks", "Out of scope", "Evidence")
DELTA_KINDS = ("ADDED", "MODIFIED", "REMOVED")
TEST_REF = re.compile(r"test: `([^`]+)`")
REQUIREMENT = re.compile(r"^- ([A-Z][A-Z0-9_]*-[0-9]+)\b")
PLACEHOLDER = re.compile(r"<[^<>]*>")
NEW_SPEC = (
    "# {name} spec\n"
    "<!-- Living spec created by {change}; see docs/agent/specs/{template}. -->\n\n"
    "## Requirements\n"
)


def git(*args: str) -> str:
    return subprocess.run(["git", *args], capture_output=True, text=True, timeout=30).stdout


def read(path: Path) -> str:
    return re.sub(r"<!--.*?-->", "", path.read_text(errors="replace"), flags=re.S)


def sections(text: str) -> dict[str, list[str]]:
    parts: dict[str, list[str]] = {}
    name = None
    for line in text.splitlines():
        if line.startswith("## "):
            name = line[3:].strip()
            parts[name] = []
        elif name:
            parts[name].append(line)
    return parts


def status_of(text: str) -> str | None:
    found = re.search(r"^status: (open|closed)\s*$", text, re.M)
    return found.group(1) if found else None


def tier_of(parts: dict[str, list[str]]) -> str:
    return next((line.strip() for line in parts.get("Tier", []) if line.strip()), "")


def criteria_of(parts: dict[str, list[str]]) -> list[str]:
    return [line for line in parts["Acceptance"] if line.startswith("- ")]


def delta_of(parts: dict[str, list[str]]) -> tuple[str, dict[str, list[str]]]:
    spec, kind = "", None
    delta: dict[str, list[str]] = {k: [] for k in DELTA_KINDS}
    for line in parts.get("Spec delta", []):
        if line.startswith("spec:"):
            spec = line[5:].strip().strip("`")
        elif line.startswith("### "):
            kind = line[4:].strip().upper()
        elif line.startswith("- ") and kind in delta:
            delta[kind].append(line)
    return spec, delta


def delta_problems(path: Path, parts: dict[str, list[str]]) -> list[str]:
    spec, delta = delta_of(parts)
    lines = [line for kind in DELTA_KINDS for line in delta[kind]]
    found = []
    if not re.fullmatch(r"docs/agent/specs/[A-Za-z0-9_.-]+\.md", spec) or spec.endswith(TEMPLATE):
        found.append(f"{path}: Spec delta needs a line 'spec: docs/agent/specs/<domain>.md'.")
    if not lines:
        found.append(f"{path}: Spec delta lists no requirement under ### ADDED, MODIFIED or "
                     "REMOVED.")
    found += [f"{path}: Spec delta line needs an ID like AUTH-1 and no <placeholders>: {line}"
              for line in lines if not REQUIREMENT.match(line) or PLACEHOLDER.search(line)]
    return found


def evidence_problems(path: Path, parts: dict[str, list[str]]) -> list[str]:
    evidence = "\n".join(parts["Evidence"])
    found = []
    if not re.search(r"^- verification: verified\b", evidence, re.M):
        found.append(f"{path} is closed without a '- verification: verified ...' line under "
                     "Evidence.")
    if PLACEHOLDER.search(evidence):
        found.append(f"{path} is closed with <placeholders> left under Evidence.")
    is_fix = tier_of(parts).startswith("T1 fix")
    if is_fix and not re.search(r"^- failed first: \S", evidence, re.M):
        found.append(f"{path} is a fix without a '- failed first: ...' line: name the test that "
                     "failed before the fix.")
    return found


def closed_problems(path: Path, parts: dict[str, list[str]]) -> list[str]:
    found = []
    for line in criteria_of(parts):
        for ref in TEST_REF.findall(line):
            if not Path(ref.split("::")[0]).exists():
                found.append(f"{path} is closed but its test {ref} does not exist.")
    if any(line.lstrip().startswith("- [ ]") for line in parts["Tasks"]):
        found.append(f"{path} is closed with unchecked tasks; tick them or reopen the change.")
    found += evidence_problems(path, parts)
    if "Spec delta" in parts:
        found += delta_problems(path, parts)
    return found


def change_problems(path: Path) -> list[str]:
    text = read(path)
    parts = sections(text)
    missing = ["## " + h for h in HEADINGS if h not in parts]
    if missing:
        return [f"{path} lacks {', '.join(missing)}; copy the headings from {CHANGES / TEMPLATE}."]
    status = status_of(text)
    if status is None:
        return [f"{path} needs a line 'status: open' or 'status: closed'."]
    criteria = criteria_of(parts)
    found = [] if criteria else [f"{path} has no acceptance criteria under ## Acceptance."]
    found += [f"{path}: acceptance line names no test: `path`: {line}"
              for line in criteria if not TEST_REF.search(line)]
    if tier_of(parts).startswith("T2"):
        found += [f"{path} is T2 and needs a ## {h} section." for h in ("Design", "Spec delta")
                  if h not in parts]
    if status == "closed":
        found += closed_problems(path, parts)
    return found


def spec_problems(path: Path) -> list[str]:
    parts = sections(read(path))
    if "Requirements" not in parts:
        return [f"{path} needs a ## Requirements section."]
    found, seen = [], set()
    for line in (line for line in parts["Requirements"] if line.startswith("- ")):
        match = REQUIREMENT.match(line)
        if not match:
            found.append(f"{path}: requirement needs an ID like AUTH-1: {line}")
        elif match.group(1) in seen:
            found.append(f"{path}: requirement ID {match.group(1)} appears twice.")
        else:
            seen.add(match.group(1))
    return found


def documents(folder: Path) -> list[Path]:
    return sorted(p for p in folder.glob("*.md") if p.name != TEMPLATE)


def changed_since(base: str) -> set[str]:
    tracked = git("diff", "--name-only", base).splitlines()
    untracked = git("ls-files", "--others", "--exclude-standard").splitlines()
    return set(tracked) | set(untracked)


def gaps(base: str) -> list[str]:
    changed = changed_since(base) if base else None
    found = []
    for path in documents(CHANGES):
        text = read(path)
        if status_of(text) != "open" or "Acceptance" not in sections(text):
            continue
        for line in criteria_of(sections(text)):
            for ref in TEST_REF.findall(line):
                test = ref.split("::")[0]
                if PLACEHOLDER.search(test):
                    found.append(f"{path}: an acceptance line still names a <placeholder> test.")
                elif not Path(test).exists():
                    found.append(f"{path}: test {test} does not exist yet.")
                elif changed is not None and test not in changed:
                    found.append(f"{path}: test {test} is unchanged since {base[:12]}; "
                                 f"does it cover: {line[2:60]}…?")
    return found


def check(base: str) -> int:
    problems = []
    for path in documents(CHANGES):
        problems += change_problems(path)
        if status_of(read(path)) == "closed":
            problems.append(f"{path} is closed; run ./ops/agent/changes.py archive {path} to merge "
                            "its Spec delta and move it to archive/.")
    for path in documents(SPECS):
        problems += spec_problems(path)
    for problem in problems:
        print("FAIL: " + problem)
    for gap in gaps(base):
        print("GAP: " + gap)
    return 1 if problems else 0


def merge(text: str, delta: dict[str, list[str]]) -> str:
    lines = text.rstrip("\n").splitlines()
    index = {}
    for number, line in enumerate(lines):
        match = REQUIREMENT.match(line)
        if match:
            index[match.group(1)] = number
    for kind in DELTA_KINDS:
        for line in delta[kind]:
            key = REQUIREMENT.match(line).group(1)
            if kind == "ADDED" and key in index:
                raise ValueError(f"ADDED {key} already exists; use MODIFIED")
            if kind != "ADDED" and key not in index:
                raise ValueError(f"{kind} {key} is not in the spec")
    for line in delta["MODIFIED"]:
        lines[index[REQUIREMENT.match(line).group(1)]] = line
    removed = {index[REQUIREMENT.match(line).group(1)] for line in delta["REMOVED"]}
    kept = [line for number, line in enumerate(lines) if number not in removed]
    return "\n".join(kept + delta["ADDED"]) + "\n"


def archive(path: Path) -> int:
    text = read(path)
    if path.parent != CHANGES or status_of(text) != "closed":
        print(f"FAIL: {path} must be a change file under {CHANGES}/ with 'status: closed'.")
        return 1
    problems = change_problems(path)
    for problem in problems:
        print("FAIL: " + problem)
    if problems:
        return 1
    target = CHANGES / "archive" / f"{time.strftime('%Y-%m-%d')}-{path.name}"
    if target.exists():
        print(f"FAIL: {target} already exists; rename {path} first.")
        return 1
    parts = sections(text)
    if "Spec delta" in parts:
        spec, delta = delta_of(parts)
        spec_path = Path(spec)
        current = spec_path.read_text() if spec_path.exists() else NEW_SPEC.format(
            name=spec_path.stem, change=target, template=TEMPLATE)
        try:
            merged = merge(current, delta)
        except ValueError as exc:
            print(f"FAIL: {path}: {exc} ({spec}).")
            return 1
        spec_path.write_text(merged)
        print(f"merged the Spec delta into {spec}")
    target.parent.mkdir(exist_ok=True)
    path.rename(target)
    print(f"archived {path} as {target}")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if args[:1] == ["check"] and len(args) <= 2:
        target = None
    elif args[:1] == ["archive"] and len(args) == 2:
        target = Path(args[1]).resolve()
    else:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    os.chdir(ROOT)
    if target is None:
        return check(args[1] if len(args) == 2 else "")
    if ROOT not in target.parents:
        print(f"FAIL: {target} is outside the repository {ROOT}.")
        return 1
    return archive(target.relative_to(ROOT))


if __name__ == "__main__":
    sys.exit(main())
