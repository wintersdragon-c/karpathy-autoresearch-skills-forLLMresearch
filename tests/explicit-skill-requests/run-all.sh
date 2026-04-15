#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

require_prompt() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "[FAIL] Missing prompt file: $path"
        exit 1
    fi
    if [ ! -s "$path" ]; then
        echo "[FAIL] Empty prompt file: $path"
        exit 1
    fi
}

require_prompt "$PROMPTS_DIR/use-autoresearch-brainstorming.txt"
require_prompt "$PROMPTS_DIR/use-autoresearch-planning.txt"
require_prompt "$PROMPTS_DIR/use-autoresearch-bootstrap.txt"
require_prompt "$PROMPTS_DIR/use-autoresearch-loop.txt"

echo "[PASS] autoresearch explicit-skill-request prompts registered"
