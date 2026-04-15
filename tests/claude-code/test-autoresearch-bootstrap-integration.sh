#!/usr/bin/env bash
# Integration Test: autoresearch-bootstrap workflow
# Executes the autoresearch-bootstrap skill in a temp repo and verifies the four canonical artifacts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=================================================="
echo " Integration Test: autoresearch-bootstrap"
echo "=================================================="
echo ""
echo "This test verifies that autoresearch-bootstrap:"
echo "  1. Generates autoresearch/profile.yaml with profile_version: 1"
echo "  2. Creates autoresearch/results.tsv with the correct header"
echo "  3. Creates autoresearch/ledger.jsonl (empty, ready for append)"
echo "  4. Updates autoresearch/state.yaml with bootstrap exit gate values"
echo "  5. Sets next_allowed_skills to autoresearch-loop"
echo ""

TEST_NAME="$(basename "$0" .sh)"
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"
CLAUDE_OUTPUT_FILE="$OUTPUT_FILE"
trap 'cleanup_test_project "$TEST_PROJECT" "$?" "$TEST_NAME" "$CLAUDE_OUTPUT_FILE"' EXIT

mkdir -p \
    "$TEST_PROJECT/autoresearch" \
    "$TEST_PROJECT/docs/autoresearch/specs" \
    "$TEST_PROJECT/docs/autoresearch/plans"

# Frozen spec fixture — all 18 required profile fields per spec section 447
cat > "$TEST_PROJECT/docs/autoresearch/specs/2026-04-10-autoresearch-design.md" <<'EOF'
# Autoresearch Repo Diagnosis Spec

**Date:** 2026-04-10
**Status:** approved
**Compatibility label:** v1-direct-fit

## Frozen Profile Fields

- `runtime.manager: uv`
- `runtime.env_prep_command: uv sync`
- `runtime.entry_command: uv run train.py`
- `runtime.timeout_seconds: 360`
- `experiment.time_budget_seconds: 300`
- `experiment.metric_name: val_bpb`
- `experiment.metric_direction: lower`
- `edit_scope.allowed_paths: [train.py]`
- `edit_scope.readonly_paths: [prepare.py]`
- `edit_scope.primary_edit_target: train.py`
- `baseline.must_run_first: true`
- `baseline.protocol: uv run train.py > run.log 2>&1`
- `baseline.baseline_description: Unmodified train.py, default hyperparameters`
- `git_policy.branch_prefix: autoresearch/`
- `git_policy.commit_before_run: true`
- `git_policy.keep_commit_strategy: keep-current-commit`
- `git_policy.discard_strategy: hard-reset-to-pre-run-commit`
- `git_policy.crash_strategy: hard-reset-to-pre-run-commit`
- `logging.run_log_path: run.log`
- `logging.summary_extract_command: grep "^val_bpb:" run.log`
- `logging.results_columns: [commit, metric_value, memory_gb, status, description]`
EOF

# Approved plan fixture
cat > "$TEST_PROJECT/docs/autoresearch/plans/2026-04-10-autoresearch-plan.md" <<'EOF'
# Autoresearch Plan

## File Map

- train.py — editable by the agent
- prepare.py — readonly

## Profile Generation

Generate autoresearch/profile.yaml from the frozen spec.

## State/Results/Ledger Scaffolding

Create autoresearch/results.tsv, autoresearch/ledger.jsonl.

## Baseline

Run `uv run train.py > run.log 2>&1`, extract `grep "^val_bpb:" run.log`.
EOF

# Pre-bootstrap state
cat > "$TEST_PROJECT/autoresearch/state.yaml" <<'EOF'
schema_version: "1.0"
project_id: autoresearch-demo
current_stage: autoresearch-bootstrap
stage_status: in_progress
profile_status: spec-frozen
bootstrap_status: pending
baseline_status: pending
experiment_status: not-started
active_spec_path: docs/autoresearch/specs/2026-04-10-autoresearch-design.md
active_profile_path: null
active_plan_path: docs/autoresearch/plans/2026-04-10-autoresearch-plan.md
active_run_manifest: null
baseline_ref: null
best_ref: null
rejection_streak: 0
last_run_status: null
next_allowed_skills:
  - autoresearch-bootstrap
rollback_target: null
blocker_reason: null
EOF

# Minimal train.py that outputs the metric
cat > "$TEST_PROJECT/train.py" <<'EOF'
#!/usr/bin/env python3
"""Minimal training script for autoresearch bootstrap testing."""
import time

def train():
    time.sleep(1)
    print("val_bpb: 2.45")

if __name__ == "__main__":
    train()
EOF

cat > "$TEST_PROJECT/prepare.py" <<'EOF'
#!/usr/bin/env python3
"""Data preparation — readonly, never modify."""
pass
EOF

# Initialize git so bootstrap can record baseline_ref
cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial autoresearch bootstrap fixture" --quiet

PROMPT=$(cat <<EOF
Change to directory $TEST_PROJECT and use the autoresearch-bootstrap skill.

The approved spec and plan already exist. The training script is train.py.

Run the bootstrap now:
- Read the approved plan at docs/autoresearch/plans/2026-04-10-autoresearch-plan.md
- Read the frozen spec at docs/autoresearch/specs/2026-04-10-autoresearch-design.md
- Generate autoresearch/profile.yaml with profile_version: 1, populating every field from the frozen spec (including edit_scope.primary_edit_target, baseline.protocol, logging.results_columns as a list, git_policy.commit_before_run, etc.)
- Create autoresearch/results.tsv with the correct header
- Run the baseline using the entry_command from the frozen spec: uv run train.py > run.log 2>&1
- Extract the metric: grep "^val_bpb:" run.log
- Record the baseline result in results.tsv (status: keep) and ledger.jsonl with all required fields (schema_version, project_id, run_id, attempt_id, commit, status, status_reason, metric_name, metric_value, metric_direction, time_budget_seconds, runtime_seconds, peak_memory_mb, log_path, results_row_ref, profile_version)
- Set baseline_ref to the current git commit hash
- Set bootstrap_status: completed, baseline_status: validated
- Set next_allowed_skills to autoresearch-loop

Follow the autoresearch-bootstrap skill exactly. The runtime.entry_command in the generated profile must match the frozen spec value: uv run train.py
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
PROFILE_FILE="$TEST_PROJECT/autoresearch/profile.yaml"
RESULTS_FILE="$TEST_PROJECT/autoresearch/results.tsv"
LEDGER_FILE="$TEST_PROJECT/autoresearch/ledger.jsonl"

if [ -f "$PROFILE_FILE" ]; then
    echo "  [PASS] autoresearch/profile.yaml created"
else
    echo "  [FAIL] autoresearch/profile.yaml missing"
    FAILED=$((FAILED + 1))
fi

if [ -f "$PROFILE_FILE" ] && rg -q "profile_version: 1" "$PROFILE_FILE"; then
    echo "  [PASS] profile_version: 1 set"
else
    echo "  [FAIL] profile_version: 1 missing"
    FAILED=$((FAILED + 1))
fi

# Profile must preserve runtime.entry_command from the frozen spec (not guessed)
if [ -f "$PROFILE_FILE" ] && rg -q "entry_command.*uv run train.py" "$PROFILE_FILE"; then
    echo "  [PASS] profile runtime.entry_command matches frozen spec"
else
    echo "  [FAIL] profile runtime.entry_command missing or does not match frozen spec (uv run train.py)"
    FAILED=$((FAILED + 1))
fi

# Profile must include edit_scope.primary_edit_target
if [ -f "$PROFILE_FILE" ] && rg -q "primary_edit_target" "$PROFILE_FILE"; then
    echo "  [PASS] profile includes edit_scope.primary_edit_target"
else
    echo "  [FAIL] profile missing edit_scope.primary_edit_target"
    FAILED=$((FAILED + 1))
fi

# Profile must include baseline.protocol
if [ -f "$PROFILE_FILE" ] && rg -q "protocol:" "$PROFILE_FILE"; then
    echo "  [PASS] profile includes baseline.protocol"
else
    echo "  [FAIL] profile missing baseline.protocol"
    FAILED=$((FAILED + 1))
fi

# Profile must include baseline.baseline_description
if [ -f "$PROFILE_FILE" ] && rg -q "baseline_description" "$PROFILE_FILE"; then
    echo "  [PASS] profile includes baseline.baseline_description"
else
    echo "  [FAIL] profile missing baseline.baseline_description"
    FAILED=$((FAILED + 1))
fi

# Profile must include git_policy.commit_before_run
if [ -f "$PROFILE_FILE" ] && rg -q "commit_before_run" "$PROFILE_FILE"; then
    echo "  [PASS] profile includes git_policy.commit_before_run"
else
    echo "  [FAIL] profile missing git_policy.commit_before_run"
    FAILED=$((FAILED + 1))
fi

# Profile logging.results_columns must be a YAML list (not a scalar string)
if [ -f "$PROFILE_FILE" ] && rg -q "results_columns:" "$PROFILE_FILE" && rg -A1 "results_columns:" "$PROFILE_FILE" | rg -q "^\s*-"; then
    echo "  [PASS] profile logging.results_columns is a YAML list"
else
    echo "  [FAIL] profile logging.results_columns missing or not a YAML list"
    FAILED=$((FAILED + 1))
fi

if [ -f "$RESULTS_FILE" ]; then
    echo "  [PASS] autoresearch/results.tsv created"
else
    echo "  [FAIL] autoresearch/results.tsv missing"
    FAILED=$((FAILED + 1))
fi

if [ -f "$RESULTS_FILE" ] && rg -q "commit" "$RESULTS_FILE" && rg -q "metric_value|val_bpb|keep" "$RESULTS_FILE"; then
    echo "  [PASS] results.tsv has header and baseline row"
else
    echo "  [FAIL] results.tsv missing header or baseline row"
    FAILED=$((FAILED + 1))
fi

if [ -f "$RESULTS_FILE" ] && ! rg -q "baseline" "$RESULTS_FILE"; then
    echo "  [PASS] results.tsv does not use 'baseline' as status (uses keep)"
else
    if [ -f "$RESULTS_FILE" ] && rg -q "^[^#].*	baseline	" "$RESULTS_FILE"; then
        echo "  [FAIL] results.tsv uses 'baseline' as status (only keep/discard/crash allowed)"
        FAILED=$((FAILED + 1))
    else
        echo "  [PASS] results.tsv status column is valid"
    fi
fi

if [ -f "$LEDGER_FILE" ]; then
    echo "  [PASS] autoresearch/ledger.jsonl created"
else
    echo "  [FAIL] autoresearch/ledger.jsonl missing"
    FAILED=$((FAILED + 1))
fi

# Ledger must have a baseline entry with all 16 required canonical fields
required_ledger_fields=(
    "schema_version" "project_id" "run_id" "attempt_id" "commit"
    "status" "status_reason" "metric_name" "metric_value" "metric_direction"
    "time_budget_seconds" "runtime_seconds" "peak_memory_mb" "log_path"
    "results_row_ref" "profile_version"
)
ledger_missing=0
if [ -f "$LEDGER_FILE" ] && [ -s "$LEDGER_FILE" ]; then
    for field in "${required_ledger_fields[@]}"; do
        if ! rg -q "\"$field\"" "$LEDGER_FILE"; then
            echo "  [FAIL] ledger.jsonl missing required field: $field"
            ledger_missing=$((ledger_missing + 1))
        fi
    done
    if [ "$ledger_missing" -eq 0 ]; then
        echo "  [PASS] ledger.jsonl baseline entry has all 16 required fields"
    else
        FAILED=$((FAILED + ledger_missing))
    fi
else
    echo "  [FAIL] ledger.jsonl is empty — baseline entry was not appended"
    FAILED=$((FAILED + 1))
fi

# results_row_ref must be present in ledger
if [ -f "$LEDGER_FILE" ] && rg -q "results_row_ref" "$LEDGER_FILE"; then
    echo "  [PASS] ledger.jsonl contains results_row_ref"
else
    echo "  [FAIL] ledger.jsonl missing results_row_ref"
    FAILED=$((FAILED + 1))
fi

if rg -q '^bootstrap_status:[[:space:]]*completed' "$STATE_FILE"; then
    echo "  [PASS] bootstrap_status: completed"
else
    echo "  [FAIL] bootstrap_status not completed"
    FAILED=$((FAILED + 1))
fi

if rg -q '^baseline_status:[[:space:]]*validated' "$STATE_FILE"; then
    echo "  [PASS] baseline_status: validated"
else
    echo "  [FAIL] baseline_status not validated"
    FAILED=$((FAILED + 1))
fi

baseline_ref=$(yaml_scalar_value "$STATE_FILE" "baseline_ref")
if [ -n "$baseline_ref" ] && [ "$baseline_ref" != "null" ]; then
    echo "  [PASS] baseline_ref recorded: $baseline_ref"
else
    echo "  [FAIL] baseline_ref missing or null"
    FAILED=$((FAILED + 1))
fi

if state_path_matches_file "$TEST_PROJECT" "$STATE_FILE" "active_profile_path" "$PROFILE_FILE"; then
    echo "  [PASS] state active_profile_path points to generated profile"
else
    echo "  [FAIL] state active_profile_path missing, unreadable, or mismatched"
    FAILED=$((FAILED + 1))
fi

if yaml_list_equals_exactly "$STATE_FILE" "next_allowed_skills" "autoresearch-loop"; then
    echo "  [PASS] next skill updated to autoresearch-loop"
else
    echo "  [FAIL] next_allowed_skills is wrong"
    FAILED=$((FAILED + 1))
fi

# best_ref must remain null — bootstrap does not own it
best_ref=$(yaml_scalar_value "$STATE_FILE" "best_ref")
if [ "$best_ref" = "null" ] || [ -z "$best_ref" ]; then
    echo "  [PASS] best_ref remains null (loop owns best_ref)"
else
    echo "  [FAIL] best_ref was set by bootstrap (loop owns best_ref)"
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
