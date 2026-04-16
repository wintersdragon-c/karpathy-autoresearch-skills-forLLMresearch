#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v rg &>/dev/null; then
    for _rg_dir in \
        "$HOME/.nvm/versions/node"/*/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin \
        "$HOME/.nvm/versions/node"/*/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin \
        /usr/local/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin \
        /usr/local/lib/node_modules/@anthropic-ai/claude-code/vendor/ripgrep/x64-darwin; do
        if [ -x "$_rg_dir/rg" ]; then
            export PATH="$_rg_dir:$PATH"
            break
        fi
    done
fi

if ! command -v rg >/dev/null 2>&1; then
    echo "[FAIL] ripgrep (rg) is required to run autoresearch skill fixture checks."
    exit 1
fi

require_file() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "[FAIL] Missing file: $path"
        exit 1
    fi
}

require_pattern() {
    local pattern="$1"
    local path="$2"
    if ! rg -q -- "$pattern" "$path"; then
        echo "[FAIL] Pattern '$pattern' not found in $path"
        exit 1
    fi
}

require_absent_pattern() {
    local pattern="$1"
    local path="$2"
    if rg -q -- "$pattern" "$path"; then
        echo "[FAIL] Pattern '$pattern' unexpectedly found in $path"
        exit 1
    fi
}

require_directory() {
    local path="$1"
    if [ ! -d "$path" ]; then
        echo "[FAIL] Missing directory: $path"
        exit 1
    fi
}

require_missing_file() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "[FAIL] Unexpected file present: $path"
        exit 1
    fi
}

echo "[PASS] autoresearch static runner skeleton"

# Task 1: autoresearch-brainstorming static checks
require_file "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "Use when" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "one at a time" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "2 to 3" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_absent_pattern "Visual Companion" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "docs/autoresearch/specs/" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "autoresearch-planning" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_absent_pattern "writing-plans" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "v2-required" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "blocked-v2-required" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "next_allowed_skills: \[\]" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "stage_status: blocked" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "active_profile_path: null" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "baseline_ref: null" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "schema_version:" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "project_id: autoresearch-demo" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "ask them to review" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "rejection_streak: 0" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
require_pattern "stage_status: in_progress" "$FIXTURES_DIR/trigger-projects/autoresearch-brainstorming/autoresearch/state.yaml"
# Brainstorming: research metric and extractor freeze contract
require_pattern "mechanical metric" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "single numeric value" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "metric extraction source" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
require_pattern "stdout, log file, jsonl, or csv" "$REPO_ROOT/skills/autoresearch-brainstorming/SKILL.md"
echo "[PASS] autoresearch-brainstorming static checks"

# Task 2: autoresearch-planning static checks
require_file "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Use when" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "subagent-driven-development" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "docs/autoresearch/plans/" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "docs/research/plans" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "next_allowed_skills:.*research-planning" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "autoresearch-bootstrap" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"
require_pattern "active_spec_path: docs/autoresearch/specs/" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "active_profile_path: null" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "baseline_ref: null" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "active_run_manifest: null" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "schema_version:" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "project_id: autoresearch-demo" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "profile_status: spec-frozen" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "stage_status: in_progress" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "active_plan_path: null" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
require_pattern "rejection_streak: 0" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/autoresearch/state.yaml"
# Spec fixture: runtime.entry_command must be frozen
require_pattern "runtime.entry_command:" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"
# Spec fixture: git strategies must use V1 canonical enum values
require_pattern "keep-current-commit" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"
require_pattern "hard-reset-to-pre-run-commit" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"
require_absent_pattern "git reset --hard" "$FIXTURES_DIR/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md"
require_pattern "zero context.*questionable taste" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "This is where decomposition decisions get locked in" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Every task MUST follow this structure" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Run: " "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Expected: " "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Commit" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Spec coverage:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Artifact and identifier consistency:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Verification coverage:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "The ONLY valid next skill is" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Subagent-Driven \\(recommended\\)" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Inline Execution" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Which approach" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_file "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Completeness" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Spec Alignment" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Task Decomposition" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Buildability" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
# Planning: verify command must dry-run to one naked number
require_pattern "must match the pattern" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "85.2%" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "342ms" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "empty output" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "multi-line output" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
echo "[PASS] autoresearch-planning static checks"

# Task 3: autoresearch-bootstrap static checks
require_file "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "Use when" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Unified-pass wording
require_pattern "unified" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# No core-training rewrite loophole
require_pattern "must not rewrite" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Baseline run and metric extraction requirement
require_pattern "baseline" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "baseline_ref" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Exit only to autoresearch-loop
require_pattern "autoresearch-loop" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_absent_pattern "next_allowed_skills:.*autoresearch-planning" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# profile_version: 1 in profile template
require_file "$REPO_ROOT/skills/autoresearch-bootstrap/profile-template.yaml"
require_pattern "profile_version: 1" "$REPO_ROOT/skills/autoresearch-bootstrap/profile-template.yaml"
# V1 git strategy enum values in profile template
require_pattern "keep-current-commit" "$REPO_ROOT/skills/autoresearch-bootstrap/profile-template.yaml"
require_pattern "hard-reset-to-pre-run-commit" "$REPO_ROOT/skills/autoresearch-bootstrap/profile-template.yaml"
# state-template has canonical bootstrap defaults
require_file "$REPO_ROOT/skills/autoresearch-bootstrap/state-template.yaml"
require_pattern "bootstrap_status: completed" "$REPO_ROOT/skills/autoresearch-bootstrap/state-template.yaml"
require_pattern "baseline_status: validated" "$REPO_ROOT/skills/autoresearch-bootstrap/state-template.yaml"
require_pattern "experiment_status: not-started" "$REPO_ROOT/skills/autoresearch-bootstrap/state-template.yaml"
require_pattern "profile_version: 1" "$REPO_ROOT/skills/autoresearch-bootstrap/state-template.yaml"
# run-manifest-template has all four required fields
require_file "$REPO_ROOT/skills/autoresearch-bootstrap/run-manifest-template.yaml"
require_pattern "proposed_change" "$REPO_ROOT/skills/autoresearch-bootstrap/run-manifest-template.yaml"
require_pattern "pre_run_commit" "$REPO_ROOT/skills/autoresearch-bootstrap/run-manifest-template.yaml"
require_pattern "launch_command" "$REPO_ROOT/skills/autoresearch-bootstrap/run-manifest-template.yaml"
require_pattern "terminal_outcome" "$REPO_ROOT/skills/autoresearch-bootstrap/run-manifest-template.yaml"
# Bootstrap trigger fixture
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/docs/autoresearch/plans/2026-04-10-autoresearch-plan.md"
# Bootstrap trigger fixture: pre-bootstrap state (generated artifacts absent)
require_pattern "active_profile_path: null" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "baseline_ref: null" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "bootstrap_status: pending" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "baseline_status: pending" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
# Bootstrap trigger fixture: profile_status preserved from brainstorming
require_pattern "profile_status: spec-frozen" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
# Bootstrap trigger fixture: active_plan_path is set (not null)
require_pattern "active_plan_path: docs/autoresearch/plans/" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
# Bootstrap trigger fixture: loop-owned fields absent/null
require_pattern "best_ref: null" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "active_run_manifest: null" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
# Bootstrap trigger fixture: schema and project
require_pattern "schema_version:" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "project_id: autoresearch-demo" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "stage_status: in_progress" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "rejection_streak: 0" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "- autoresearch-bootstrap" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/autoresearch/state.yaml"
require_pattern "subagent-driven-development" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/docs/autoresearch/plans/2026-04-10-autoresearch-plan.md"
require_pattern "baseline" "$FIXTURES_DIR/trigger-projects/autoresearch-bootstrap/docs/autoresearch/plans/2026-04-10-autoresearch-plan.md"
# Bootstrap SKILL.md: baseline TSV status must be 'keep' (not 'baseline' — only keep/discard/crash allowed)
require_absent_pattern "status.*['\`]baseline['\`]" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Bootstrap SKILL.md: ledger schema must include required fields
require_pattern "schema_version.*project_id.*run_id" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "Review it critically" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "TodoWrite" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "STOP bootstrap execution immediately" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "Review the plan critically before starting" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "env_prep_command" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "When To Revisit Earlier Steps" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "key in-scope files" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Bootstrap: git hygiene precondition checks
require_pattern "git rev-parse --git-dir" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "git status --porcelain" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "index.lock" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "detached HEAD" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "pre-commit" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
# Bootstrap: extractor dry-run and numeric output validation
require_pattern "summary_extract_command" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "must match the pattern" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
echo "[PASS] autoresearch-bootstrap static checks"

# Task 4: autoresearch-loop static checks
require_file "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "Use when" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# No proposal-class machinery from research-experiment-loop
require_absent_pattern "hyperparam-variation" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_absent_pattern "frontier-probe" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_absent_pattern "claim bundle" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_absent_pattern "verification-before-claim" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_absent_pattern "paper assets" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Entry gate on validated bootstrap state
require_pattern "bootstrap_status" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "baseline_status" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "baseline_ref" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# keep/discard/crash vocabulary
require_pattern "keep" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "discard" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "crash" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Normal and abnormal termination
require_pattern "stopped-completed" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "stopped-blocked" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# rejection_streak is informational only (must not appear in stop-condition logic)
require_pattern "rejection_streak" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_absent_pattern "stop.*rejection_streak" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Editable-surface hard gate
require_pattern "edit_scope" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "reject-and-record" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# profile-reference.md exists
require_file "$REPO_ROOT/skills/autoresearch-loop/profile-reference.md"
require_pattern "rejection_streak" "$REPO_ROOT/skills/autoresearch-loop/profile-reference.md"
require_pattern "results_row_ref" "$REPO_ROOT/skills/autoresearch-loop/profile-reference.md"
require_pattern "active_run_manifest" "$REPO_ROOT/skills/autoresearch-loop/profile-reference.md"
# Loop trigger fixture
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/profile.yaml"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/results.tsv"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/ledger.jsonl"
require_file "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/runs/run-0001.yaml"
# Loop trigger fixture: pre-run state
require_pattern "profile_status: spec-frozen" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "bootstrap_status: completed" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "baseline_status: validated" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "experiment_status: not-started" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "active_profile_path: autoresearch/profile.yaml" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "baseline_ref: abc1234" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "active_run_manifest: null" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "schema_version:" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "project_id: autoresearch-demo" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "stage_status: in_progress" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
require_pattern "rejection_streak: 0" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
# Run manifest has all four required fields
require_pattern "proposed_change" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/runs/run-0001.yaml"
require_pattern "pre_run_commit" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/runs/run-0001.yaml"
require_pattern "launch_command" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/runs/run-0001.yaml"
require_pattern "terminal_outcome" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/runs/run-0001.yaml"
# results.tsv has header and at least one data row
require_pattern "commit" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/results.tsv"
require_pattern "keep" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/results.tsv"
# ledger.jsonl has results_row_ref
require_pattern "results_row_ref" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/ledger.jsonl"
# profile.yaml has profile_version: 1
require_pattern "profile_version: 1" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/profile.yaml"
# Loop trigger fixture: best_ref must be null pre-loop (loop owns best_ref, bootstrap does not)
require_pattern "best_ref: null" "$FIXTURES_DIR/trigger-projects/autoresearch-loop/autoresearch/state.yaml"
# Branch verification in entry gate
require_pattern "git branch --show-current" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Crash retry sub-loop
require_pattern "attempt_id" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "max_retry_on_crash" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "Easy fix" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Research taste
require_pattern "Simplicity criterion" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "VRAM soft constraint" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
# Autonomous operation
require_pattern "do NOT pause to ask" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "results.tsv must not be committed" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
echo "[PASS] autoresearch-loop static checks"
