#!/usr/bin/env bash
# Integration Test: autoresearch-brainstorming workflow
# Executes the autoresearch-brainstorming skill in a temp repo and verifies autoresearch-native spec drafting.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=================================================="
echo " Integration Test: autoresearch-brainstorming"
echo "=================================================="
echo ""
echo "This test verifies that autoresearch-brainstorming:"
echo "  1. Writes a spec under docs/autoresearch/specs/"
echo "  2. Updates autoresearch/state.yaml for autoresearch-planning"
echo "  3. Freezes all required profile fields in the spec"
echo "  4. Asks the user to review before advancing"
echo ""

TEST_NAME="$(basename "$0" .sh)"
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"
CLAUDE_OUTPUT_FILE="$OUTPUT_FILE"
trap 'cleanup_test_project "$TEST_PROJECT" "$?" "$TEST_NAME" "$CLAUDE_OUTPUT_FILE"' EXIT

mkdir -p "$TEST_PROJECT/autoresearch"

cat > "$TEST_PROJECT/autoresearch/state.yaml" <<'EOF'
schema_version: "1.0"
project_id: autoresearch-demo
current_stage: autoresearch-brainstorming
stage_status: in_progress
profile_status: pending
bootstrap_status: pending
baseline_status: pending
experiment_status: not-started
active_spec_path: null
active_profile_path: null
active_plan_path: null
active_run_manifest: null
baseline_ref: null
best_ref: null
rejection_streak: 0
last_run_status: null
next_allowed_skills:
  - autoresearch-brainstorming
rollback_target: null
blocker_reason: null
EOF

# Create a minimal train.py so the skill can inspect the repo
cat > "$TEST_PROJECT/train.py" <<'EOF'
#!/usr/bin/env python3
"""Minimal GPT training script for autoresearch testing."""
import time

def train():
    print("val_bpb: 2.45")

if __name__ == "__main__":
    train()
EOF

cat > "$TEST_PROJECT/prepare.py" <<'EOF'
#!/usr/bin/env python3
"""Data preparation — readonly, never modify."""
pass
EOF

PROMPT=$(cat <<EOF
Change to directory $TEST_PROJECT and use the autoresearch-brainstorming skill.

Here is the repo context:
- Small PyTorch language-model training repo
- Contains train.py (GPT model, training loop) and prepare.py (data prep, readonly)
- Entry command: uv run train.py
- Timeout: 360s, time budget: 300s
- Metric: val_bpb (lower is better), extracted with: grep "^val_bpb:" run.log
- Edit scope: train.py editable, prepare.py readonly
- Git policy frozen fields:
  - git_policy.keep_commit_strategy: keep-current-commit
  - git_policy.discard_strategy: hard-reset-to-pre-run-commit
  - git_policy.crash_strategy: hard-reset-to-pre-run-commit

Treat this prompt as approval to finalize the spec if it includes all required frozen profile fields.

Create the autoresearch-native spec artifact now under docs/autoresearch/specs/.

Follow the autoresearch-brainstorming skill exactly:
- diagnose the repo as v1-direct-fit
- freeze all required profile fields in the spec
- set active_spec_path to the generated spec
- set profile_status to spec-frozen
- set next_allowed_skills to autoresearch-planning
- do not create docs/research/specs or any other non-autoresearch path
- do not start planning, bootstrapping, or running experiments
EOF
)

echo "Running Claude (output will be shown below and saved to $OUTPUT_FILE)..."
echo "================================================================================"
set +e
cd "$TEST_PROJECT" && run_with_timeout_to_output 900 "$OUTPUT_FILE" claude -p "$PROMPT" --plugin-dir "$PLUGIN_DIR" --allowed-tools=all --add-dir "$TEST_PROJECT" --permission-mode bypassPermissions
exit_code=$?
set -e
if [ "$exit_code" -ne 0 ]; then
    echo ""
    echo "================================================================================"
    echo "EXECUTION FAILED (exit code: $exit_code)"
    exit 1
fi
echo "================================================================================"

FAILED=0
STATE_FILE="$TEST_PROJECT/autoresearch/state.yaml"
SPEC_FILE=$(find "$TEST_PROJECT/docs/autoresearch/specs" -name '*.md' -type f 2>/dev/null | sort | head -1 || true)

if [ -n "$SPEC_FILE" ]; then
    echo "  [PASS] autoresearch spec created under docs/autoresearch/specs/"
else
    echo "  [FAIL] no autoresearch spec created under docs/autoresearch/specs/"
    FAILED=$((FAILED + 1))
fi

if [ -n "$SPEC_FILE" ] && state_path_matches_file "$TEST_PROJECT" "$STATE_FILE" "active_spec_path" "$SPEC_FILE"; then
    echo "  [PASS] state active_spec_path points to generated spec"
else
    echo "  [FAIL] state active_spec_path missing, unreadable, or mismatched"
    FAILED=$((FAILED + 1))
fi

if rg -q '^profile_status:[[:space:]]*spec-frozen' "$STATE_FILE"; then
    echo "  [PASS] profile_status advanced to spec-frozen"
else
    echo "  [FAIL] profile_status did not advance to spec-frozen"
    FAILED=$((FAILED + 1))
fi

if yaml_list_equals_exactly "$STATE_FILE" "next_allowed_skills" "autoresearch-planning"; then
    echo "  [PASS] next skill updated to autoresearch-planning"
else
    echo "  [FAIL] next_allowed_skills is wrong"
    FAILED=$((FAILED + 1))
fi

if [ -n "$SPEC_FILE" ] && rg -q "runtime.entry_command" "$SPEC_FILE"; then
    echo "  [PASS] spec includes runtime.entry_command"
else
    echo "  [FAIL] spec missing runtime.entry_command"
    FAILED=$((FAILED + 1))
fi

if [ -n "$SPEC_FILE" ] && rg -q "keep-current-commit|hard-reset-to-pre-run-commit" "$SPEC_FILE"; then
    echo "  [PASS] spec uses V1 canonical git strategy enum values"
else
    echo "  [FAIL] spec missing V1 canonical git strategy enum values"
    FAILED=$((FAILED + 1))
fi

if [ -d "$TEST_PROJECT/docs/research/specs" ]; then
    echo "  [FAIL] docs/research/specs was created unexpectedly (drift)"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] docs/research/specs not created"
fi

if [ -d "$TEST_PROJECT/autoresearch" ] && [ ! -f "$TEST_PROJECT/autoresearch/profile.yaml" ]; then
    echo "  [PASS] bootstrap artifacts not created during brainstorming"
else
    echo "  [FAIL] bootstrap artifacts created prematurely"
    FAILED=$((FAILED + 1))
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
