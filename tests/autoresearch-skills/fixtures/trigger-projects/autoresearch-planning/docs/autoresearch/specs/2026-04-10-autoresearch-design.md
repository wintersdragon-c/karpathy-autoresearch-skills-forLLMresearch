# Autoresearch Repo Diagnosis Spec

**Date:** 2026-04-10
**Status:** approved
**Compatibility label:** v1-direct-fit

## Repository Summary

A small PyTorch language-model training repo. Contains `train.py` (GPT model, Muon+AdamW optimizer, training loop) and `prepare.py` (data prep, tokenizer, dataloader, evaluation). The repo is self-contained and requires no external services.

## Runtime

- **Command:** `uv run train.py`
- **Timeout:** 360s (hard kill)
- **Time budget:** 300s (soft target for a single training run)
- **Log file:** `run.log`

## Metric

- **Name:** `val_bpb`
- **Direction:** lower is better
- **Extraction:** `grep "^val_bpb:" run.log`

## Edit Scope

- `train.py` — editable by the agent
- `prepare.py` — readonly, never modify

## Baseline Policy

A clean baseline run must be committed before any experiments begin. The baseline `val_bpb` is recorded in `autoresearch/state.yaml` under `baseline_ref`.

## Git Policy

- Branch prefix: `autoresearch/`
- Keep improvement: `keep-current-commit`
- Discard regression: `hard-reset-to-pre-run-commit`
- Crash / timeout: `hard-reset-to-pre-run-commit`

## Logging

Stdout and stderr are redirected to `run.log`. The metric line format is `val_bpb: <float>` on its own line. Extract with `grep "^val_bpb:" run.log`.

## Frozen Profile Fields

- `runtime.manager: uv`
- `runtime.env_prep_command: uv sync`
- `runtime.entry_command: uv run train.py`
- `runtime.timeout_seconds: 360`
- `experiment.time_budget_seconds: 300`
- `experiment.metric_name: val_bpb`
- `experiment.metric_direction: lower`
- `baseline.must_run_first: true`
- `baseline.protocol: run \`uv run train.py > run.log 2>&1\`, extract \`grep "^val_bpb:" run.log\`, record result`
- `edit_scope.allowed_paths: [train.py]`
- `edit_scope.readonly_paths: [prepare.py]`
- `edit_scope.primary_edit_target: train.py`
- `git_policy.branch_prefix: autoresearch/`
- `git_policy.keep_commit_strategy: keep-current-commit`
- `git_policy.discard_strategy: hard-reset-to-pre-run-commit`
- `git_policy.crash_strategy: hard-reset-to-pre-run-commit`
- `logging.run_log_path: run.log`
- `logging.results_columns: commit, metric_value, memory_gb, status, description`
- `logging.summary_extract_command: grep "^val_bpb:" run.log`
