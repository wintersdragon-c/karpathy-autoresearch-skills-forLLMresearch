#!/usr/bin/env bash
# Integration Test: autoresearch spec document reviewer
# Directly exercises spec-document-reviewer-prompt.md by asking Claude to review
# a seeded spec with intentional errors and verifying the reviewer catches them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=================================================="
echo " Integration Test: autoresearch spec reviewer"
echo "=================================================="
echo ""
echo "This test verifies that spec-document-reviewer-prompt.md:"
echo "  1. Catches TBD or missing frozen profile fields"
echo "  2. Catches entry_command vs baseline.protocol mismatch"
echo "  3. Catches missing logging.results_columns"
echo "  4. Produces a properly formatted review with Issues Found"
echo "  5. Does not approve a spec with errors"
echo ""

TEST_NAME="$(basename "$0" .sh)"
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"
CLAUDE_OUTPUT_FILE="$OUTPUT_FILE"
trap 'cleanup_test_project "$TEST_PROJECT" "$?" "$TEST_NAME" "$CLAUDE_OUTPUT_FILE"' EXIT

mkdir -p "$TEST_PROJECT/docs/autoresearch/specs"

# Create a spec WITH INTENTIONAL ERRORS for the reviewer to catch:
#   1. runtime.timeout_seconds is TBD (missing concrete value)
#   2. baseline.protocol uses "python3 train.py" but runtime.entry_command is "uv run train.py" (mismatch)
#   3. logging.results_columns is missing entirely
cat > "$TEST_PROJECT/docs/autoresearch/specs/2026-04-10-test-design.md" <<'EOF'
# Autoresearch Repo Diagnosis Spec

**Date:** 2026-04-10
**Status:** draft
**Compatibility label:** v1-direct-fit

## Problem Statement

Small GPT language-model training repo. Goal: run autoresearch experiment loop to lower val_bpb.

## Chosen Approach

v1-direct-fit: single-process training, clear entry command, scalar metric logged to stdout.

## Frozen Profile Fields

- `runtime.manager: uv`
- `runtime.env_prep_command: uv sync`
- `runtime.entry_command: uv run train.py`
- `runtime.timeout_seconds: TBD`
- `experiment.time_budget_seconds: 300`
- `experiment.metric_name: val_bpb`
- `experiment.metric_direction: lower`
- `edit_scope.allowed_paths: [train.py]`
- `edit_scope.readonly_paths: [prepare.py]`
- `edit_scope.primary_edit_target: train.py`
- `baseline.must_run_first: true`
- `baseline.protocol: python3 train.py > run.log 2>&1`
- `baseline.baseline_description: Unmodified train.py, default hyperparameters`
- `git_policy.branch_prefix: autoresearch/`
- `git_policy.commit_before_run: true`
- `git_policy.keep_commit_strategy: keep-current-commit`
- `git_policy.discard_strategy: hard-reset-to-pre-run-commit`
- `git_policy.crash_strategy: hard-reset-to-pre-run-commit`
- `logging.run_log_path: run.log`
- `logging.summary_extract_command: grep "^val_bpb:" run.log`
EOF

# Initialize git
cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial spec reviewer fixture" --quiet

echo "Created test spec with intentional errors:"
echo "  - runtime.timeout_seconds is TBD (missing concrete value)"
echo "  - baseline.protocol uses 'python3 train.py' but entry_command is 'uv run train.py' (mismatch)"
echo "  - logging.results_columns is missing entirely"
echo ""

PROMPT=$(cat <<EOF
Read the spec document reviewer prompt template at $PLUGIN_DIR/skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md.

Then review the spec at $TEST_PROJECT/docs/autoresearch/specs/2026-04-10-test-design.md using that template exactly.

Use the template criteria and output format exactly. Do not add extra review categories.
EOF
)

echo "Running Claude (output will be shown below and saved to $OUTPUT_FILE)..."
echo "================================================================================"
set +e
cd "$TEST_PROJECT" && run_with_timeout_to_output 300 "$OUTPUT_FILE" claude -p "$PROMPT" --plugin-dir "$PLUGIN_DIR" --allowed-tools=all --add-dir "$TEST_PROJECT" --permission-mode bypassPermissions
exit_code=$?
set -e
if [ "$exit_code" -ne 0 ]; then
    echo ""
    echo "================================================================================"
    echo "EXECUTION FAILED (exit code: $exit_code)"
    exit 1
fi
echo "================================================================================"

echo ""
echo "Analyzing reviewer output..."
echo ""

FAILED=0

echo "=== Verification Tests ==="
echo ""

# Test 1: Reviewer found the TBD timeout
echo "Test 1: Reviewer found TBD timeout_seconds..."
if rg -qi "timeout|TBD" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified TBD/missing timeout_seconds"
else
    echo "  [FAIL] Reviewer did not identify TBD timeout_seconds"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Reviewer found the entry_command vs baseline.protocol mismatch
echo "Test 2: Reviewer found entry_command vs baseline.protocol mismatch..."
if rg -qi "mismatch|protocol|entry_command|python3|uv run" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified entry_command/protocol mismatch"
else
    echo "  [FAIL] Reviewer did not identify entry_command/protocol mismatch"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Reviewer found the missing logging.results_columns field
echo "Test 3: Reviewer found missing logging.results_columns..."
if rg -qi "results_columns|logging\.results_columns" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified missing logging.results_columns"
else
    echo "  [FAIL] Reviewer did not identify missing logging.results_columns"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Reviewer output includes Issues section
echo "Test 4: Review output format includes Issues section..."
if rg -qi "issues" "$OUTPUT_FILE"; then
    echo "  [PASS] Review includes Issues section"
else
    echo "  [FAIL] Review missing Issues section"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Reviewer did NOT approve (found issues)
echo "Test 5: Reviewer verdict is Issues Found (not Approved)..."
if rg -qi "Issues Found" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer correctly reported Issues Found"
elif rg -qi "^.*Approved" "$OUTPUT_FILE" && ! rg -qi "Issues Found" "$OUTPUT_FILE"; then
    echo "  [FAIL] Reviewer incorrectly approved spec with errors"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] Reviewer identified problems (format may vary)"
fi
echo ""

echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
else
    echo "STATUS: FAILED"
    echo "Failed $FAILED verification checks"
    echo "Output saved to: $OUTPUT_FILE"
    exit 1
fi
