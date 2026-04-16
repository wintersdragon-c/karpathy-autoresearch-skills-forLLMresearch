#!/usr/bin/env bash
# Fast harness: autoresearch-loop static contract checks
# Verifies the SKILL.md contains required gates and forbidden patterns without invoking Claude.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-loop/SKILL.md"

echo "=== Test: autoresearch-loop harness ==="
echo ""

echo "Test 1: Skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: Entry gate on validated bootstrap state..."
if rg -q "bootstrap_status" "$SKILL" && rg -q "baseline_status" "$SKILL" && rg -q "baseline_ref" "$SKILL"; then
    echo "  [PASS] Entry gate fields present"
else
    echo "  [FAIL] Entry gate fields missing"
    exit 1
fi
echo ""

echo "Test 3: keep/discard/crash vocabulary present..."
if rg -q "keep" "$SKILL" && rg -q "discard" "$SKILL" && rg -q "crash" "$SKILL"; then
    echo "  [PASS] keep/discard/crash vocabulary present"
else
    echo "  [FAIL] keep/discard/crash vocabulary missing"
    exit 1
fi
echo ""

echo "Test 4: Normal termination (stopped-completed) present..."
if rg -q "stopped-completed" "$SKILL"; then
    echo "  [PASS] stopped-completed present"
else
    echo "  [FAIL] stopped-completed missing"
    exit 1
fi
echo ""

echo "Test 5: Abnormal termination (stopped-blocked) present..."
if rg -q "stopped-blocked" "$SKILL"; then
    echo "  [PASS] stopped-blocked present"
else
    echo "  [FAIL] stopped-blocked missing"
    exit 1
fi
echo ""

echo "Test 6: Out-of-scope reject-and-record behavior present..."
if rg -q "edit_scope" "$SKILL" && rg -q "reject-and-record" "$SKILL"; then
    echo "  [PASS] reject-and-record behavior present"
else
    echo "  [FAIL] reject-and-record behavior missing"
    exit 1
fi
echo ""

echo "Test 7: rejection_streak is informational only (not in stop-condition logic)..."
if rg -q "rejection_streak" "$SKILL"; then
    if rg -q "stop.*rejection_streak" "$SKILL"; then
        echo "  [FAIL] rejection_streak appears in stop-condition logic"
        exit 1
    else
        echo "  [PASS] rejection_streak present but not in stop-condition logic"
    fi
else
    echo "  [FAIL] rejection_streak not mentioned at all"
    exit 1
fi
echo ""

echo "Test 8: No proposal-class machinery from research-experiment-loop..."
if rg -q "hyperparam-variation|frontier-probe|claim bundle|verification-before-claim|paper assets" "$SKILL"; then
    echo "  [FAIL] Proposal-class machinery found"
    exit 1
else
    echo "  [PASS] No proposal-class machinery"
fi
echo ""

echo "Test 9: profile-reference.md exists..."
PROFILE_REF="$REPO_ROOT/skills/autoresearch-loop/profile-reference.md"
if [ -f "$PROFILE_REF" ]; then
    echo "  [PASS] profile-reference.md present"
else
    echo "  [FAIL] profile-reference.md missing"
    exit 1
fi
echo ""

echo "Test 10: profile-reference.md documents rejection_streak semantics..."
if rg -q "rejection_streak" "$PROFILE_REF"; then
    echo "  [PASS] rejection_streak documented in profile-reference.md"
else
    echo "  [FAIL] rejection_streak missing from profile-reference.md"
    exit 1
fi
echo ""

echo "Test 11: profile-reference.md documents results_row_ref semantics..."
if rg -q "results_row_ref" "$PROFILE_REF"; then
    echo "  [PASS] results_row_ref documented in profile-reference.md"
else
    echo "  [FAIL] results_row_ref missing from profile-reference.md"
    exit 1
fi
echo ""

echo "Test 12: profile-reference.md documents active_run_manifest semantics..."
if rg -q "active_run_manifest" "$PROFILE_REF"; then
    echo "  [PASS] active_run_manifest documented in profile-reference.md"
else
    echo "  [FAIL] active_run_manifest missing from profile-reference.md"
    exit 1
fi
echo ""

echo "Test 13: Branch verification in entry gate..."
if rg -q "git branch --show-current" "$SKILL"; then
    echo "  [PASS] Branch verification present"
else
    echo "  [FAIL] Branch verification missing"
    exit 1
fi
echo ""

echo "Test 14: Crash retry sub-loop present..."
if rg -q "attempt_id" "$SKILL" && rg -q "max_retry_on_crash" "$SKILL" && rg -q "Easy fix" "$SKILL"; then
    echo "  [PASS] Crash retry sub-loop present"
else
    echo "  [FAIL] Crash retry sub-loop missing"
    exit 1
fi
echo ""

echo "Test 15: Research taste (simplicity criterion + VRAM) present..."
if rg -q "Simplicity criterion" "$SKILL" && rg -q "VRAM soft constraint" "$SKILL"; then
    echo "  [PASS] Research taste section present"
else
    echo "  [FAIL] Research taste section missing"
    exit 1
fi
echo ""

echo "Test 16: NEVER STOP principle present..."
if rg -q "do NOT pause to ask" "$SKILL"; then
    echo "  [PASS] NEVER STOP principle present"
else
    echo "  [FAIL] NEVER STOP principle missing"
    exit 1
fi
echo ""

echo "Test 17: results.tsv untracked rule present..."
if rg -q "results.tsv must not be committed" "$SKILL"; then
    echo "  [PASS] results.tsv untracked rule present"
else
    echo "  [FAIL] results.tsv untracked rule missing"
    exit 1
fi
echo ""

echo "Test 18: Git-as-memory protocol present..."
if rg -q "git log --oneline -20" "$SKILL" && \
   rg -q "git diff HEAD~1" "$SKILL" && \
   rg -q "Git IS the memory" "$SKILL"; then
    echo "  [PASS] Git-as-memory protocol present"
else
    echo "  [FAIL] Git-as-memory protocol missing"
    exit 1
fi
echo ""

echo "Test 19: Periodic summary reporting present..."
if rg -q "Every 10 iterations" "$SKILL" && rg -q "Baseline:" "$SKILL"; then
    echo "  [PASS] Periodic summary reporting present"
else
    echo "  [FAIL] Periodic summary reporting missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-loop harness tests passed ==="
