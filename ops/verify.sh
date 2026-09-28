#!/usr/bin/env bash
# The one verification command. Agents run it before claiming work is done; the Stop gate runs it
# when the tree has uncommitted code; CI runs it on every push. Exit non-zero on any failure.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

./ops/check-agent-kit.sh

# KIT-PLACEHOLDER: replace this block with your stack's test and lint commands, for example
#   uv run pytest -q && uv run ruff check .
#   pnpm test -- --run && pnpm lint
echo "ops/verify.sh is not configured yet: replace the KIT-PLACEHOLDER block with real commands." >&2
exit 0
