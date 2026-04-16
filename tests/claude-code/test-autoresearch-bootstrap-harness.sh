#!/usr/bin/env bash
# Fast harness: autoresearch-bootstrap static contract checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"

echo "=== Test: autoresearch-bootstrap harness ==="
echo ""

echo "Test 1: Bootstrap skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: Critical plan review step present..."
if rg -q "Review it critically" "$SKILL"; then
    echo "  [PASS] Critical review step present"
else
    echo "  [FAIL] Critical review step missing"
    exit 1
fi
echo ""

echo "Test 3: TodoWrite task tracking present..."
if rg -q "TodoWrite" "$SKILL"; then
    echo "  [PASS] TodoWrite tracking present"
else
    echo "  [FAIL] TodoWrite tracking missing"
    exit 1
fi
echo ""

echo "Test 4: Stop conditions present..."
if rg -q "STOP bootstrap execution immediately" "$SKILL"; then
    echo "  [PASS] Stop conditions present"
else
    echo "  [FAIL] Stop conditions missing"
    exit 1
fi
echo ""

echo "Test 5: Remember rules present..."
if rg -q "Review the plan critically before starting" "$SKILL" && rg -q "Stop when blocked" "$SKILL"; then
    echo "  [PASS] Remember rules present"
else
    echo "  [FAIL] Remember rules missing"
    exit 1
fi
echo ""

echo "Test 6: env_prep_command execution present..."
if rg -q "env_prep_command" "$SKILL"; then
    echo "  [PASS] env_prep_command execution present"
else
    echo "  [FAIL] env_prep_command execution missing"
    exit 1
fi
echo ""

echo "Test 7: When To Revisit Earlier Steps present..."
if rg -q "When To Revisit Earlier Steps" "$SKILL"; then
    echo "  [PASS] Revisit mechanism present"
else
    echo "  [FAIL] Revisit mechanism missing"
    exit 1
fi
echo ""

echo "Test 8: Key in-scope repo files read before generating artifacts..."
if rg -q "key in-scope files" "$SKILL"; then
    echo "  [PASS] Repo file reading step present"
else
    echo "  [FAIL] Repo file reading step missing"
    exit 1
fi
echo ""

echo "Test 9: Git hygiene precondition checks present..."
if rg -q "git rev-parse --git-dir" "$SKILL" && \
   rg -q "git status --porcelain" "$SKILL" && \
   rg -q "detached HEAD" "$SKILL"; then
    echo "  [PASS] Git hygiene checks present"
else
    echo "  [FAIL] Git hygiene checks missing"
    exit 1
fi
echo ""

echo "Test 10: Baseline extractor dry-run and numeric-output validation present..."
if rg -q "summary_extract_command" "$SKILL" && \
   rg -q "must match the pattern" "$SKILL"; then
    echo "  [PASS] Extractor dry-run contract present"
else
    echo "  [FAIL] Extractor dry-run contract missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-bootstrap harness tests passed ==="
