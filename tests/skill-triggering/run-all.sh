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

require_prompt "$PROMPTS_DIR/autoresearch-brainstorming.txt"
require_prompt "$PROMPTS_DIR/autoresearch-planning.txt"
require_prompt "$PROMPTS_DIR/autoresearch-bootstrap.txt"
require_prompt "$PROMPTS_DIR/autoresearch-loop.txt"

echo "[PASS] autoresearch skill-triggering prompts registered"
