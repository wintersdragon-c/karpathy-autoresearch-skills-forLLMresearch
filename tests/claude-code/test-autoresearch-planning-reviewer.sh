#!/usr/bin/env bash
# Integration Test: autoresearch plan document reviewer
# Directly exercises plan-document-reviewer-prompt.md by asking Claude to review
# a seeded plan with intentional errors and verifying the reviewer catches them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=================================================="
echo " Integration Test: autoresearch plan reviewer"
echo "=================================================="
echo ""
echo "This test verifies that plan-document-reviewer-prompt.md:"
echo "  1. Catches missing log extraction task (mandatory scope area omitted)"
echo "  2. Catches TBD placeholder value (runtime.timeout_seconds: TBD)"
echo "  3. Catches verification step with Run: but no Expected: line"
echo "  4. Produces a properly formatted review with Issues section"
echo "  5. Does not approve a plan with errors"
echo ""

TEST_NAME="$(basename "$0" .sh)"
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"
CLAUDE_OUTPUT_FILE="$OUTPUT_FILE"
trap 'cleanup_test_project "$TEST_PROJECT" "$?" "$TEST_NAME" "$CLAUDE_OUTPUT_FILE"' EXIT

SPEC_FIXTURE="$PLUGIN_DIR/tests/autoresearch-skills/fixtures/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"

mkdir -p "$TEST_PROJECT/docs/autoresearch/plans"

# Create a plan WITH INTENTIONAL ERRORS for the reviewer to catch:
#   1. Log extraction setup task is entirely missing (mandatory scope area omitted)
#   2. runtime.timeout_seconds: TBD (placeholder value)
#   3. A verification step has Run: but no Expected: line
cat > "$TEST_PROJECT/docs/autoresearch/plans/2026-04-13-test-plan.md" <<'EOF'
# Autoresearch Adaptation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the autoresearch experiment loop for the GPT language-model training repo.

**Architecture:** The repo uses uv for dependency management and a single train.py entry point. We create profile.yaml, state.yaml, results.tsv, and ledger.jsonl to make the loop ready.

**Tech Stack:** Python, PyTorch, uv, GPT model, Muon+AdamW optimizer

---

### Task 1: Generate autoresearch/profile.yaml

**Files:**
- Create: `autoresearch/profile.yaml`
- Verify: `autoresearch/profile.yaml`

- [ ] **Step 1: Write the profile artifact**

```yaml
runtime:
  manager: uv
  env_prep_command: uv sync
  entry_command: uv run train.py
  timeout_seconds: TBD
experiment:
  time_budget_seconds: 300
  metric_name: val_bpb
  metric_direction: lower
edit_scope:
  allowed_paths: [train.py]
  readonly_paths: [prepare.py]
  primary_edit_target: train.py
baseline:
  must_run_first: true
  protocol: "uv run train.py > run.log 2>&1"
  baseline_description: Unmodified train.py, default hyperparameters
git_policy:
  branch_prefix: autoresearch/
  commit_before_run: true
  keep_commit_strategy: keep-current-commit
  discard_strategy: hard-reset-to-pre-run-commit
  crash_strategy: hard-reset-to-pre-run-commit
logging:
  run_log_path: run.log
```

- [ ] **Step 2: Verify profile was written**

Run: `cat autoresearch/profile.yaml`

- [ ] **Step 3: Commit**

```bash
git add autoresearch/profile.yaml
git commit -m "chore: add autoresearch profile"
```

---

### Task 2: Scaffold state/results/ledger

**Files:**
- Create: `autoresearch/state.yaml`
- Create: `autoresearch/results.tsv`
- Create: `autoresearch/ledger.jsonl`

- [ ] **Step 1: Write state.yaml**

```yaml
current_stage: planning
stage_status: completed
active_spec_path: docs/autoresearch/specs/2026-04-10-autoresearch-design.md
active_plan_path: docs/autoresearch/plans/2026-04-13-test-plan.md
baseline_ref: null
best_ref: null
profile_status: null
next_allowed_skills:
  - autoresearch-bootstrap
```

- [ ] **Step 2: Write results.tsv header**

```
commit\tmetric_value\tmemory_gb\tstatus\tdescription
```

- [ ] **Step 3: Write empty ledger**

```
```

- [ ] **Step 4: Verify scaffolding**

Run: `ls autoresearch/`
Expected: `ledger.jsonl  profile.yaml  results.tsv  state.yaml`

- [ ] **Step 5: Commit**

```bash
git add autoresearch/state.yaml autoresearch/results.tsv autoresearch/ledger.jsonl
git commit -m "chore: scaffold autoresearch state, results, ledger"
```

---

### Task 3: Baseline run verification

**Files:**
- Verify: `run.log`

- [ ] **Step 1: Run baseline**

Run: `uv run train.py > run.log 2>&1`
Expected: Command exits within 360 seconds with exit code 0

- [ ] **Step 2: Extract metric**

Run: `grep "^val_bpb:" run.log`

- [ ] **Step 3: Commit baseline**

```bash
git add run.log
git commit -m "baseline: record initial val_bpb"
```

EOF

# Initialize git
cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial plan reviewer fixture" --quiet

echo "Created test plan with intentional errors:"
echo "  - Log extraction setup task is entirely missing (mandatory scope area omitted)"
echo "  - runtime.timeout_seconds: TBD (placeholder value)"
echo "  - Task 3 Step 2 has Run: but no Expected: line"
echo ""

PROMPT=$(cat <<EOF
Read the plan document reviewer prompt template at $PLUGIN_DIR/skills/autoresearch-planning/plan-document-reviewer-prompt.md.

Then review the plan at $TEST_PROJECT/docs/autoresearch/plans/2026-04-13-test-plan.md against the spec at $SPEC_FIXTURE using that template exactly.

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

# Test 1: Reviewer found the missing log extraction task
echo "Test 1: Reviewer found missing log extraction task..."
if rg -qi "log extraction|summary_extract|results_columns" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified missing log extraction task"
else
    echo "  [FAIL] Reviewer did not identify missing log extraction task"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Reviewer found the TBD placeholder
echo "Test 2: Reviewer found TBD placeholder value..."
if rg -qi "TBD|placeholder|timeout" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified TBD/placeholder value"
else
    echo "  [FAIL] Reviewer did not identify TBD placeholder"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Reviewer found the missing Expected line
echo "Test 3: Reviewer found missing Expected line in verification step..."
if rg -qi "Expected.*missing|no expected|missing.*expected|without.*expected|Expected.*absent|no.*Expected.*line|Expected.*line.*missing|lacks.*Expected|missing.*Expected.*line" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer identified missing Expected line"
else
    echo "  [FAIL] Reviewer did not identify missing Expected line"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Reviewer output includes a markdown Issues heading (distinct from Test 5 verdict check)
echo "Test 4: Review output contains markdown Issues heading..."
if rg -qi "\*\*Issues.*\*\*|\*\*.*Issues.*Found.*\*\*|## Issues|### Issues" "$OUTPUT_FILE"; then
    echo "  [PASS] Review includes markdown Issues heading"
else
    echo "  [FAIL] Review missing markdown Issues heading"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Reviewer verdict is Issues Found, not Approved
echo "Test 5: Reviewer verdict is Issues Found (not Approved)..."
if rg -qi "Issues Found" "$OUTPUT_FILE"; then
    echo "  [PASS] Reviewer correctly reported Issues Found"
else
    echo "  [FAIL] Reviewer did not report Issues Found"
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
