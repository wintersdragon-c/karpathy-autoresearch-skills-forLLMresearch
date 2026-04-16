#!/usr/bin/env bash
# Fast harness: autoresearch-brainstorming static contract checks
# Verifies the SKILL.md contains required gates and forbidden patterns without invoking Claude.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"

echo "=== Test: autoresearch-brainstorming harness ==="
echo ""

echo "Test 1: Skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: No Visual Companion branch..."
if rg -q "Visual Companion" "$SKILL"; then
    echo "  [FAIL] Visual Companion found in skill"
    exit 1
else
    echo "  [PASS] No Visual Companion branch"
fi
echo ""

echo "Test 3: Autoresearch-native spec path (docs/autoresearch/specs/)..."
if rg -q "docs/autoresearch/specs/" "$SKILL"; then
    echo "  [PASS] Autoresearch-native spec path present"
else
    echo "  [FAIL] Autoresearch-native spec path missing"
    exit 1
fi
echo ""

echo "Test 4: No drift to docs/research/specs/..."
if rg -q "docs/research/specs" "$SKILL"; then
    echo "  [FAIL] Drift to docs/research/specs found"
    exit 1
else
    echo "  [PASS] No docs/research/specs drift"
fi
echo ""

echo "Test 5: Hard gate against code edits, scaffolding, bootstrap, and experiments..."
if rg -q "[Hh]ard gate" "$SKILL" && rg -q "no edits|no bootstrap|no runs|must not" "$SKILL"; then
    echo "  [PASS] Hard gate language present"
else
    echo "  [FAIL] Hard gate language missing"
    exit 1
fi
echo ""

echo "Test 6: v2-required blocked behavior present..."
if rg -q "v2-required" "$SKILL" && rg -q "blocked-v2-required" "$SKILL"; then
    echo "  [PASS] v2-required blocked behavior present"
else
    echo "  [FAIL] v2-required blocked behavior missing"
    exit 1
fi
echo ""

echo "Test 7: stage_status: blocked set for v2-required..."
if rg -q "stage_status: blocked" "$SKILL"; then
    echo "  [PASS] stage_status: blocked present"
else
    echo "  [FAIL] stage_status: blocked missing"
    exit 1
fi
echo ""

echo "Test 8: next_allowed_skills: [] set for v2-required blocked path..."
if rg -q 'next_allowed_skills: \[\]' "$SKILL"; then
    echo "  [PASS] next_allowed_skills: [] present"
else
    echo "  [FAIL] next_allowed_skills: [] missing"
    exit 1
fi
echo ""

echo "Test 9: Exit only to autoresearch-planning..."
if rg -q "autoresearch-planning" "$SKILL"; then
    echo "  [PASS] autoresearch-planning exit present"
else
    echo "  [FAIL] autoresearch-planning exit missing"
    exit 1
fi
echo ""

echo "Test 10: No exit to research-literature-positioning or writing-plans..."
if rg -q "research-literature-positioning|writing-plans" "$SKILL"; then
    echo "  [FAIL] Drift to research-literature-positioning or writing-plans found"
    exit 1
else
    echo "  [PASS] No upstream skill drift"
fi
echo ""

echo "Test 11: Spec-freeze contract includes runtime command..."
if rg -q "runtime" "$SKILL" && rg -q "entry_command" "$SKILL"; then
    echo "  [PASS] Runtime entry command in spec-freeze contract"
else
    echo "  [FAIL] Runtime entry command missing from spec-freeze contract"
    exit 1
fi
echo ""

echo "Test 12: Spec-freeze contract includes metric name and direction..."
if rg -q "metric_name" "$SKILL" && rg -q "metric_direction" "$SKILL"; then
    echo "  [PASS] Metric fields in spec-freeze contract"
else
    echo "  [FAIL] Metric fields missing from spec-freeze contract"
    exit 1
fi
echo ""

echo "Test 13: Ask user to review spec before advancing..."
if rg -q "ask them to review|ask.*review" "$SKILL"; then
    echo "  [PASS] User review gate present"
else
    echo "  [FAIL] User review gate missing"
    exit 1
fi
echo ""

echo "Test 14: spec-document-reviewer-prompt.md sidecar exists..."
SPEC_REVIEWER="$REPO_ROOT/skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md"
if [ -f "$SPEC_REVIEWER" ]; then
    echo "  [PASS] spec-document-reviewer-prompt.md present"
else
    echo "  [FAIL] spec-document-reviewer-prompt.md missing"
    exit 1
fi
echo ""

echo "Test 15: Sidecar has Completeness/Consistency/Clarity/Scope/YAGNI review categories..."
if rg -q "Completeness" "$SPEC_REVIEWER" && rg -q "Consistency" "$SPEC_REVIEWER" && rg -q "Clarity" "$SPEC_REVIEWER"; then
    echo "  [PASS] Sidecar has required review categories"
else
    echo "  [FAIL] Sidecar missing required review categories (Completeness, Consistency, Clarity)"
    exit 1
fi
echo ""

echo "Test 17: Sidecar documents canonical git strategy enum values..."
if rg -q "keep-current-commit" "$SPEC_REVIEWER" && rg -q "hard-reset-to-pre-run-commit" "$SPEC_REVIEWER"; then
    echo "  [PASS] Sidecar documents canonical git strategy enum values"
else
    echo "  [FAIL] Sidecar missing canonical git strategy enum values"
    exit 1
fi
echo ""

echo "Test 16: Sidecar contract allows documented null (no conflict with controller)..."
if rg -q "documented null" "$SPEC_REVIEWER"; then
    echo "  [PASS] Sidecar allows documented null — no contract conflict"
else
    echo "  [FAIL] Sidecar missing 'documented null' — may conflict with controller contract"
    exit 1
fi
echo ""

echo "Test 18: SKILL.md documents canonical git strategy enum values in spec-freeze contract..."
if rg -q "keep-current-commit" "$SKILL" && rg -q "hard-reset-to-pre-run-commit" "$SKILL"; then
    echo "  [PASS] SKILL.md documents canonical git strategy enum values"
else
    echo "  [FAIL] SKILL.md missing canonical git strategy enum values in spec-freeze contract"
    exit 1
fi
echo ""

echo "Test 19: SKILL.md contains design-for-isolation-and-clarity section..."
if rg -q "Design for Isolation and Clarity" "$SKILL"; then
    echo "  [PASS] Design for Isolation and Clarity section present"
else
    echo "  [FAIL] Design for Isolation and Clarity section missing"
    exit 1
fi
echo ""

echo "Test 20: SKILL.md contains working-in-existing-repos section..."
if rg -q "Working in Existing Research Repos" "$SKILL"; then
    echo "  [PASS] Working in Existing Research Repos section present"
else
    echo "  [FAIL] Working in Existing Research Repos section missing"
    exit 1
fi
echo ""

echo "Test 21: SKILL.md requires adapter boundary for v1-bootstrap-fit..."
if rg -q "adapter boundary|Adapter boundary" "$SKILL" && rg -q "v1-bootstrap-fit" "$SKILL"; then
    echo "  [PASS] v1-bootstrap-fit adapter boundary requirement present"
else
    echo "  [FAIL] v1-bootstrap-fit adapter boundary requirement missing"
    exit 1
fi
echo ""

echo "Test 22: SKILL.md and sidecar both state sidecar is optional (not a mandatory runtime step)..."
if rg -q "optional" "$SKILL" && rg -q "not a mandatory runtime step" "$SKILL"; then
    echo "  [PASS] Sidecar optionality stated in SKILL.md"
else
    echo "  [FAIL] Sidecar optionality not stated in SKILL.md"
    exit 1
fi
if rg -q "not a mandatory runtime step" "$SPEC_REVIEWER"; then
    echo "  [PASS] Sidecar optionality stated in spec-document-reviewer-prompt.md"
else
    echo "  [FAIL] Sidecar optionality not stated in spec-document-reviewer-prompt.md"
    exit 1
fi
echo ""

echo "Test 23: Hard gate explicitly forbids implementation-skill invocation before approval..."
if rg -q "Invoke any implementation skill before the spec is approved" "$SKILL" && \
   rg -q "no implementation-skill invocation" "$SKILL"; then
    echo "  [PASS] Implementation-skill prohibition present"
else
    echo "  [FAIL] Implementation-skill prohibition missing"
    exit 1
fi
echo ""

echo "Test 24: Inline spec self-review includes scope and ambiguity checks..."
if rg -q "Scope check:" "$SKILL" && rg -q "Ambiguity check:" "$SKILL"; then
    echo "  [PASS] Inline scope/ambiguity self-review checks present"
else
    echo "  [FAIL] Inline scope/ambiguity self-review checks missing"
    exit 1
fi
echo ""

echo "Test 25: Repo inspection includes docs and recent-history signals..."
if rg -q "Read repo documentation" "$SKILL" && rg -q "recent commits or other local history signals" "$SKILL"; then
    echo "  [PASS] Repo inspection breadth present"
else
    echo "  [FAIL] Repo inspection breadth missing"
    exit 1
fi
echo ""

echo "Test 26: Research metric freeze requires mechanical metric + extraction source..."
if rg -q "mechanical metric" "$SKILL" && \
   rg -q "single numeric value" "$SKILL" && \
   rg -q "metric extraction source" "$SKILL"; then
    echo "  [PASS] Research metric freeze contract present"
else
    echo "  [FAIL] Research metric freeze contract missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-brainstorming harness tests passed ==="
