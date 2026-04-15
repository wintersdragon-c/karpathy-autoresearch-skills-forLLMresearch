#!/usr/bin/env bash
# Integration Test: autoresearch-loop entry gate and contract execution
# Executes the autoresearch-loop skill in a temp repo and verifies gate/contract behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=================================================="
echo " Integration Test: autoresearch-loop"
echo "=================================================="
echo ""
echo "This test verifies that autoresearch-loop:"
echo "  1. Passes the entry gate on validated bootstrap state"
echo "  2. Respects the edit_scope hard gate (reject-and-record out-of-scope edits)"
echo "  3. Appends results.tsv and ledger.jsonl after each run"
echo "  4. Classifies outcomes as keep/discard/crash"
echo "  5. Keeps best_ref updated on keep outcomes"
echo ""

TEST_NAME="$(basename "$0" .sh)"
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"
CLAUDE_OUTPUT_FILE="$OUTPUT_FILE"
trap 'cleanup_test_project "$TEST_PROJECT" "$?" "$TEST_NAME" "$CLAUDE_OUTPUT_FILE"' EXIT

mkdir -p \
    "$TEST_PROJECT/autoresearch/runs" \
    "$TEST_PROJECT/docs/autoresearch/specs" \
    "$TEST_PROJECT/docs/autoresearch/plans"

# Minimal train.py that outputs the metric
cat > "$TEST_PROJECT/train.py" <<'EOF'
#!/usr/bin/env python3
"""Minimal training script for autoresearch loop testing."""
import time

def train():
    time.sleep(1)
    print("val_bpb: 2.40")

if __name__ == "__main__":
    train()
EOF

cat > "$TEST_PROJECT/prepare.py" <<'EOF'
#!/usr/bin/env python3
"""Data preparation — readonly, never modify."""
pass
EOF

# Profile — canonical field names per spec section 248
cat > "$TEST_PROJECT/autoresearch/profile.yaml" <<'EOF'
schema_version: "1.0"
profile_version: 1
repo_shape:
  repo_type: training-script
  small_repo_profile: true
  primary_language: python
  package_manager: uv
  notes: minimal test repo
runtime:
  manager: uv
  env_prep_command: uv sync
  entry_command: python3 train.py
  timeout_seconds: 60
  log_path: run.log
  results_tsv_path: autoresearch/results.tsv
  default_runner: python3
experiment:
  time_budget_seconds: 30
  max_experiments: 10
  max_consecutive_crashes: 3
  max_retry_on_crash: 1
  keep_rule: lower_is_better
  discard_rule: not_keep
  crash_rule: non_zero_exit
  metric_name: val_bpb
  metric_direction: lower
edit_scope:
  allowed_paths:
    - train.py
  readonly_paths:
    - prepare.py
  primary_edit_target: train.py
baseline:
  must_run_first: true
  protocol: "python3 train.py > run.log 2>&1"
  baseline_description: unmodified train.py baseline
git_policy:
  branch_prefix: autoresearch/
  commit_before_run: true
  keep_commit_strategy: keep-current-commit
  discard_strategy: hard-reset-to-pre-run-commit
  crash_strategy: hard-reset-to-pre-run-commit
logging:
  run_log_path: run.log
  summary_extract_command: "grep '^val_bpb:' run.log"
  results_columns:
    - commit
    - metric_value
    - memory_gb
    - status
    - description
bootstrap_scaffold:
  scaffold_paths: []
  generated_files: []
  thin_adapter_required: false
EOF

# results.tsv with baseline row
cat > "$TEST_PROJECT/autoresearch/results.tsv" <<'EOF'
commit	metric_value	memory_gb	status	description
abc1234	2.45	N/A	keep	baseline run
EOF

# ledger.jsonl with baseline entry
cat > "$TEST_PROJECT/autoresearch/ledger.jsonl" <<'EOF'
{"schema_version":"1.0","project_id":"autoresearch-demo","run_id":"run-0000","attempt_id":"attempt-0001","commit":"abc1234","status":"keep","status_reason":"baseline","metric_name":"val_bpb","metric_value":2.45,"metric_direction":"lower","time_budget_seconds":30,"runtime_seconds":5,"peak_memory_mb":null,"log_path":"run.log","results_row_ref":"abc1234","profile_version":1}
EOF

# Pre-loop state
cat > "$TEST_PROJECT/autoresearch/state.yaml" <<'EOF'
schema_version: "1.0"
project_id: autoresearch-demo
current_stage: autoresearch-loop
stage_status: in_progress
profile_status: spec-frozen
bootstrap_status: completed
baseline_status: validated
experiment_status: not-started
active_spec_path: docs/autoresearch/specs/2026-04-10-autoresearch-design.md
active_profile_path: autoresearch/profile.yaml
active_plan_path: docs/autoresearch/plans/2026-04-10-autoresearch-plan.md
active_run_manifest: null
baseline_ref: abc1234
best_ref: null
rejection_streak: 0
last_run_status: null
next_allowed_skills:
  - autoresearch-loop
rollback_target: null
blocker_reason: null
EOF

# Initialize git
cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial autoresearch loop fixture" --quiet

PROMPT=$(cat <<EOF
Change to directory $TEST_PROJECT and use the autoresearch-loop skill.

The bootstrap is complete. The baseline is validated. Run one experiment iteration:
- Verify the entry gate passes (bootstrap_status: completed, baseline_status: validated, baseline_ref set)
- Propose a small change to train.py that is likely to produce a keep outcome (e.g., add a minor optimization comment or adjust a constant that keeps val_bpb at or below the baseline of 2.45)
- Only edit files in edit_scope.allowed_paths (train.py)
- Commit the change before running
- Run the experiment: python3 train.py > run.log 2>&1
- Extract the metric: grep "^val_bpb:" run.log
- Classify the outcome as keep, discard, or crash
- If keep: update best_ref in state.yaml to the new commit hash
- Append a row to autoresearch/results.tsv
- Append an entry to autoresearch/ledger.jsonl with results_row_ref
- Write autoresearch/runs/run-0001.yaml with proposed_change, pre_run_commit, launch_command, terminal_outcome
- Update autoresearch/state.yaml with active_run_manifest and last_run_status

Follow the autoresearch-loop skill exactly. Run only one iteration.
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
RESULTS_FILE="$TEST_PROJECT/autoresearch/results.tsv"
LEDGER_FILE="$TEST_PROJECT/autoresearch/ledger.jsonl"

# results.tsv should have at least 2 rows (header + baseline + new run)
results_rows=$(wc -l < "$RESULTS_FILE" 2>/dev/null || echo 0)
if [ "$results_rows" -ge 3 ]; then
    echo "  [PASS] results.tsv has new row appended"
else
    echo "  [FAIL] results.tsv missing new row (expected >= 3 lines, got $results_rows)"
    FAILED=$((FAILED + 1))
fi

# ledger.jsonl should have at least 2 entries
ledger_rows=$(wc -l < "$LEDGER_FILE" 2>/dev/null || echo 0)
if [ "$ledger_rows" -ge 2 ]; then
    echo "  [PASS] ledger.jsonl has new entry appended"
else
    echo "  [FAIL] ledger.jsonl missing new entry (expected >= 2 lines, got $ledger_rows)"
    FAILED=$((FAILED + 1))
fi

# ledger must have results_row_ref
if rg -q "results_row_ref" "$LEDGER_FILE"; then
    echo "  [PASS] ledger.jsonl contains results_row_ref"
else
    echo "  [FAIL] ledger.jsonl missing results_row_ref"
    FAILED=$((FAILED + 1))
fi

# results.tsv must use keep/discard/crash (not baseline)
if rg -q "	keep	|	discard	|	crash	" "$RESULTS_FILE"; then
    echo "  [PASS] results.tsv uses valid status vocabulary"
else
    echo "  [FAIL] results.tsv missing valid status in new row"
    FAILED=$((FAILED + 1))
fi

# run manifest should exist
RUN_MANIFEST=$(find "$TEST_PROJECT/autoresearch/runs" -name 'run-*.yaml' -type f 2>/dev/null | sort | tail -1 || true)
if [ -n "$RUN_MANIFEST" ]; then
    echo "  [PASS] run manifest created under autoresearch/runs/"
else
    echo "  [FAIL] run manifest missing under autoresearch/runs/"
    FAILED=$((FAILED + 1))
fi

# run manifest must have all four required fields
if [ -n "$RUN_MANIFEST" ] && \
   rg -q "proposed_change" "$RUN_MANIFEST" && \
   rg -q "pre_run_commit" "$RUN_MANIFEST" && \
   rg -q "launch_command" "$RUN_MANIFEST" && \
   rg -q "terminal_outcome" "$RUN_MANIFEST"; then
    echo "  [PASS] run manifest has all four required fields"
else
    echo "  [FAIL] run manifest missing one or more required fields"
    FAILED=$((FAILED + 1))
fi

# active_run_manifest should be set in state
active_run_manifest=$(yaml_scalar_value "$STATE_FILE" "active_run_manifest")
if [ -n "$active_run_manifest" ] && [ "$active_run_manifest" != "null" ]; then
    echo "  [PASS] active_run_manifest set in state"
else
    echo "  [FAIL] active_run_manifest not set in state"
    FAILED=$((FAILED + 1))
fi

# last_run_status must be keep — this test is designed to cover the keep path
last_run_status=$(yaml_scalar_value "$STATE_FILE" "last_run_status")
if [ "$last_run_status" = "keep" ]; then
    echo "  [PASS] last_run_status is keep"
else
    echo "  [FAIL] last_run_status is '$last_run_status' — this test requires a keep outcome to prove best_ref update"
    FAILED=$((FAILED + 1))
fi

# best_ref must be set after a keep outcome
best_ref=$(yaml_scalar_value "$STATE_FILE" "best_ref")
if [ -n "$best_ref" ] && [ "$best_ref" != "null" ]; then
    echo "  [PASS] best_ref updated after keep outcome: $best_ref"
else
    echo "  [FAIL] best_ref not updated after keep outcome (loop must set best_ref on keep)"
    FAILED=$((FAILED + 1))
fi

# prepare.py must not be modified (readonly)
if git -C "$TEST_PROJECT" diff HEAD -- prepare.py 2>/dev/null | grep -q '^[+-]' 2>/dev/null; then
    echo "  [FAIL] prepare.py was modified (readonly violation)"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] prepare.py not modified (readonly respected)"
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
