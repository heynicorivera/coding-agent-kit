# Untested tool configurations

Configurations for tools the maintainer does not use daily. Each one is written from the tool's
documentation and has not been run against the real tool. They are inactive here: every tool
reads them only from the repository root.

To enable one, copy it to the same path at the root and run the kit check, which validates it
there:

    cp -R contrib/untested/.codex .                  # Codex
    ./ops/check-agent-kit.sh

| File | Tool | What it wires |
|---|---|---|
| `.codex/hooks.json` | Codex | session start, stop gate, session-end stamp |
| `.cursor/hooks.json` | Cursor | session start, stop gate |
| `.github/hooks/agent-kit.json` | Copilot cloud agent | stop gate (`agentStop`) |
| `.gemini/settings.json` | Gemini CLI | loads AGENTS.md |
| `.aider.conf.yml` | Aider | loads AGENTS.md and STATUS.md; runs `ops/verify.sh` after each edit |

Copilot CLI needs nothing from here: it reads `.claude/settings.json`. A file moves back to the
root of the kit only after a live test, recorded in README.md (see ROADMAP.md).
