#!/usr/bin/env bash
# Fast harness: autoresearch-planning static contract checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
REVIEWER="$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"

echo "=== Test: autoresearch-planning harness ==="
echo ""

echo "Test 1: Planning skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: Zero-context executor framing present..."
if rg -q "zero context.*questionable taste" "$SKILL"; then
    echo "  [PASS] Zero-context framing present"
else
    echo "  [FAIL] Zero-context framing missing"
    exit 1
fi
echo ""

echo "Test 3: Rigid task template present..."
if rg -q "Every task MUST follow this structure" "$SKILL" && rg -q "Run: " "$SKILL" && rg -q "Expected: " "$SKILL"; then
    echo "  [PASS] Rigid task template present"
else
    echo "  [FAIL] Rigid task template missing"
    exit 1
fi
echo ""

echo "Test 4: Full self-review contract present..."
if rg -q "Spec coverage:" "$SKILL" && rg -q "Artifact and identifier consistency:" "$SKILL" && rg -q "Verification coverage:" "$SKILL"; then
    echo "  [PASS] Self-review contract present"
else
    echo "  [FAIL] Self-review contract missing"
    exit 1
fi
echo ""

echo "Test 5: Strict pipeline handoff to bootstrap present..."
if { rg -q "next step is to invoke.*autoresearch-bootstrap" "$SKILL" || rg -q "The ONLY valid next skill is" "$SKILL"; } && \
   ! rg -q "Subagent-Driven" "$SKILL" && \
   ! rg -q "Inline Execution" "$SKILL"; then
    echo "  [PASS] Strict pipeline handoff present, execution modes absent"
else
    echo "  [FAIL] Pipeline handoff missing or execution modes still present"
    exit 1
fi
echo ""

echo "Test 6: Plan reviewer sidecar exists..."
if [ -f "$REVIEWER" ]; then
    echo "  [PASS] plan-document-reviewer-prompt.md present"
else
    echo "  [FAIL] plan-document-reviewer-prompt.md missing"
    exit 1
fi
echo ""

echo "Test 7: Plan reviewer sidecar categories present..."
if rg -q "Completeness" "$REVIEWER" && rg -q "Spec Alignment" "$REVIEWER" && rg -q "Task Decomposition" "$REVIEWER" && rg -q "Buildability" "$REVIEWER"; then
    echo "  [PASS] Plan reviewer categories present"
else
    echo "  [FAIL] Plan reviewer categories missing"
    exit 1
fi
echo ""

echo "Test 8: Plan reviewer sidecar explicitly requires Expected: for every Run: step..."
if rg -q "Run:.*Expected:|Expected:.*Run:|both.*Run.*Expected|Run.*and.*Expected|Expected.*line" "$REVIEWER"; then
    echo "  [PASS] Run:/Expected: pairing rule present in sidecar"
else
    echo "  [FAIL] Run:/Expected: pairing rule missing from sidecar"
    exit 1
fi
echo ""

echo "Test 9: No Placeholders section uses plan-failures framing with specific failure modes..."
if rg -q "plan failures" "$SKILL" && rg -q "Similar to Task N" "$SKILL" && rg -q "Steps that describe what to write" "$SKILL"; then
    echo "  [PASS] Upstream-strength No Placeholders contract present"
else
    echo "  [FAIL] No Placeholders contract missing plan-failures framing or specific failure modes"
    exit 1
fi
echo ""

echo "Test 10: ONLY valid next skill constraint present..."
if rg -q "The ONLY valid next skill is" "$SKILL"; then
    echo "  [PASS] ONLY valid next skill constraint present"
else
    echo "  [FAIL] ONLY valid next skill constraint missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-planning harness tests passed ==="
