---
name: autoresearch-bootstrap
description: Use when an approved autoresearch plan is ready to be turned into a runnable autoresearch compatibility layer for a small research repo.
---

# Autoresearch Bootstrap

## Overview

Run a single unified bootstrap pass that generates the minimal compatibility layer making the target repo operable as an autoresearch loop target. This is one atomic operation — no internal stage split in V1.

Bootstrap creates thin scaffolding only. It must not rewrite core training logic unless the approved plan explicitly identifies that rewrite as part of normalization.

**Announce at start:** "I'm using the autoresearch-bootstrap skill to generate the compatibility layer and validate the baseline."

**V1 runner assumption:** Prefer `uv` when the repo already uses it or is Python-first.

## Entry Gate

Before doing anything, read `autoresearch/state.yaml` and check both `active_plan_path` and `active_spec_path`.

If `active_plan_path` is null — stop immediately, report the error, and do not proceed. A plan must be approved before bootstrap can run.

If `active_spec_path` is null — stop immediately, report the error, and do not proceed. A frozen spec must exist before bootstrap can run.

## Repo Precondition Checks

Before generating any artifacts, verify the repo environment is safe for bootstrap:

- Verify the repo is a git repository: `git rev-parse --git-dir` must succeed
- Verify the working tree is clean: `git status --porcelain` must produce no output
- Detect stale `.git/index.lock` — if present, warn the user and stop
- Detect detached HEAD — bootstrap must run on a named branch
- Detect pre-commit or husky hooks that may block automated commits — if present, note them in the plan review but do not disable them

If any check fails, set `blocker_reason` in state.yaml and stop.

## The Process

### Step 1 — Load and review the approved plan

Read the file at `active_plan_path`. Review it critically before taking any action:
- Does the plan cover all six mandatory areas (profile generation, state scaffolding, log extraction, baseline verification, thin adapter if needed, loop-readiness check)?
- Are there any unclear steps, missing verification commands, or gaps that would block execution?
- Do file paths, field names, and commands in later tasks match what earlier tasks define?

If you find concerns, raise them with the user before starting. Do not silently work around gaps.

If no concerns, create a TodoWrite with one item per task in the approved plan (not per bootstrap prompt heading) and proceed.

### Step 2 — Read the approved spec and key repo files

Read the file at `active_spec_path`. Extract the frozen profile fields: `runtime.entry_command`, `runtime.env_prep_command`, `runtime.timeout_seconds`, `logging.summary_extract_command`, `experiment.metric_name`, `experiment.metric_direction`, git strategies, and all other profile-level values.

Also read the key in-scope files from the repo to understand the actual codebase before generating any artifacts:
- `README.md` — repo context and purpose
- The primary edit target named in the spec (e.g., `train.py`) — understand what the loop will modify
- Any readonly files named in the spec (e.g., `prepare.py`) — understand the fixed constraints

This context is required to judge whether a proposed thin adapter would exceed the approved boundary, and to verify that the entry command and log extraction command are consistent with the actual code.

### Step 3 — Generate `autoresearch/profile.yaml`

Populate `autoresearch/profile.yaml` using `profile-template.yaml` as the schema reference. Fill every field from the spec's frozen values. Set `profile_version: 1`. Do not leave any field as null unless the spec explicitly marks it optional.

### Step 4 — Generate `autoresearch/state.yaml`

Populate `autoresearch/state.yaml` from `state-template.yaml`. Preserve `active_spec_path` and `active_plan_path` from the current state. Set `bootstrap_status: completed`, `baseline_status: pending` (will be updated after baseline run), and `active_profile_path` to the verified path of the generated profile.

### Step 5 — Generate `autoresearch/results.tsv`

Create `autoresearch/results.tsv` with this exact header row:

```
commit	metric_value	memory_gb	status	description
```

### Step 6 — Generate `autoresearch/ledger.jsonl`

Create `autoresearch/ledger.jsonl` as an empty file, ready for append. Do not write any content — the loop will append entries.

### Step 7 — Generate thin adapters or wrappers

If the plan requires thin adapters or wrappers (e.g., a shim to normalize the entry point, a log extraction helper), generate them now. Do not rewrite core training logic. Do not add experiments. Do not start the loop.

### Step 8 — Prepare environment and run the baseline

If `runtime.env_prep_command` in `autoresearch/profile.yaml` is non-null, run it first:
- Execute `runtime.env_prep_command` and wait for it to complete
- If it exits non-zero, set `blocker_reason` in state.yaml and stop — the environment is not ready for the baseline run

Then execute `runtime.entry_command` with output redirected to `runtime.log_path`. Wait up to `runtime.timeout_seconds`. This is a mandatory execution — inspection alone is not sufficient.

After the run completes or reaches the timeout boundary:
- If the run exits non-zero, set `blocker_reason` in state.yaml and stop — do not proceed to step 9
- If the run times out (exceeds `runtime.timeout_seconds`), set `blocker_reason` in state.yaml and stop — do not proceed to step 9
- If the log file (`runtime.log_path`) is absent or empty before extraction is attempted, set `blocker_reason` in state.yaml and stop — do not proceed to step 9
- Extract the metric using `logging.summary_extract_command`
- If extraction fails, set `blocker_reason` in state.yaml and stop — do not proceed to step 9
- Dry-run `logging.summary_extract_command` against the generated baseline log before accepting the baseline. The extracted value must match the pattern `^-?[0-9]+\.?[0-9]*$`. If extraction returns `85.2%`, `342ms`, empty output, or multi-line output, set `blocker_reason` and stop.

### Step 9 — Record baseline result

Append the baseline result to `autoresearch/results.tsv` (one tab-separated row: commit hash, metric value, memory_gb if available else `N/A`, `keep`, description). The only allowed status values in results.tsv are `keep`, `discard`, and `crash` — use `keep` for the baseline run.

Append a JSON entry to `autoresearch/ledger.jsonl` with all required fields: `schema_version`, `project_id`, `run_id`, `attempt_id`, `commit`, `status`, `status_reason`, `metric_name`, `metric_value`, `metric_direction`, `time_budget_seconds`, `runtime_seconds`, `peak_memory_mb`, `log_path`, `results_row_ref`, `profile_version`.

### Step 10 — Set `baseline_ref`

Set `baseline_ref` to the git commit hash of the baseline run. If the repo has no git history, create an initial commit now and use that hash.

### Step 11 — Update `autoresearch/state.yaml` with exit gate values

Write the final state as specified in the Exit Gate section below.

## Hard Gates

- Bootstrap must not rewrite core training logic unless the approved plan explicitly says that is part of normalization.
- Bootstrap must not run any experiments beyond the single baseline run.
- Bootstrap must not start the autoresearch loop.
- Bootstrap must not modify `active_spec_path` or `active_plan_path` or `best_ref` in state.yaml.

## When To Stop And Ask

STOP bootstrap execution immediately if:
- a plan step is unclear or conflicts with the spec
- a required verification command fails twice
- a generated artifact would exceed the approved adapter boundary
- `runtime.env_prep_command` exits non-zero (set `blocker_reason` and stop)
- the baseline run exits non-zero or times out (set `blocker_reason` and stop)
- log extraction fails after a successful run

Ask for clarification rather than guessing. Do not silently rewrite the plan in your head.

## When To Revisit Earlier Steps

Return to Step 1 (Load and review the approved plan) if:
- the user updates the approved plan mid-execution
- reading the repo files reveals a fundamental mismatch with the plan's assumptions

Do not continue executing against a changed or rethought plan without re-reviewing it first.

## Remember

- Review the plan critically before starting — raise concerns before taking action
- Follow plan steps exactly — do not skip verifications
- Stop when blocked — ask rather than guess
- Never start on main/master branch without explicit user consent

## Exit Gate

After completing all steps, `autoresearch/state.yaml` must contain:

```yaml
stage_status: completed
bootstrap_status: completed
baseline_status: validated
active_profile_path: <path to generated profile>   # must be verified readable
baseline_ref: <commit hash from baseline run>
next_allowed_skills:
  - autoresearch-loop
```

Verify `active_profile_path` is readable before writing the exit state. If it is not readable, set `blocker_reason` and stop.

## State Ownership Contract

- **May write:** `current_stage`, `stage_status`, `bootstrap_status`, `baseline_status`, `active_profile_path`, `baseline_ref`, `next_allowed_skills`, `rollback_target`, `blocker_reason`
- **May read but NOT write:** `active_spec_path`, `active_plan_path`, `best_ref`

## Common Mistakes

| Mistake | Why it fails | Correct behavior |
|---|---|---|
| Skipping the baseline run and only inspecting commands | Baseline validation requires actual execution | Run the command, wait for completion or timeout, extract metric |
| Rewriting `train.py` or core training logic | Bootstrap is a thin layer only | Only create adapters/wrappers if the plan explicitly requires them |
| Setting `next_allowed_skills` to anything other than `autoresearch-loop` | Breaks pipeline ordering | Always set exactly `[autoresearch-loop]` at exit |
| Leaving `baseline_ref` null after a successful run | Loop cannot anchor experiments without a baseline | Always set `baseline_ref` from the actual commit hash |
| Writing `active_plan_path` or `active_spec_path` | These are read-only for bootstrap | Preserve existing values, never overwrite |
| Proceeding when `active_plan_path` is null | No plan means no approved scope | Stop and report the error immediately |
