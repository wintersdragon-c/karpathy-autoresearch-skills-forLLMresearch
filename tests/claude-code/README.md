# Claude Code Skills Tests — Autoresearch Suite

Automated tests for the autoresearch skill suite.

## Overview

This suite verifies that the four autoresearch skills (`autoresearch-brainstorming`, `autoresearch-planning`, `autoresearch-bootstrap`, `autoresearch-loop`) are correctly wired and follow their contracts. Tests are split into fast harness checks (no Claude invocation) and live integration tests (invoke Claude CLI).

## Requirements

- `rg` (ripgrep) for fast harness tests
- Claude Code CLI installed and in PATH for live integration tests
- Local superpowers plugin installed for live integration tests

## Running Tests

### Run all fast harness tests (recommended):
```bash
./run-skill-tests.sh
```

### Run autoresearch live integration tests (slow, 10-30 minutes):
```bash
./run-skill-tests.sh --autoresearch-integration
```

### Run a specific test:
```bash
./run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
./run-skill-tests.sh --test test-autoresearch-loop-harness.sh
```

### Run with verbose output:
```bash
./run-skill-tests.sh --verbose
```

### Set custom timeout:
```bash
./run-skill-tests.sh --timeout 1800  # 30 minutes for integration tests
```

## Test Structure

### Fast Harness Tests (run by default)

#### test-autoresearch-brainstorming-harness.sh
Static contract checks for `autoresearch-brainstorming`:
- No Visual Companion branch
- Autoresearch-native spec path (`docs/autoresearch/specs/`)
- No drift to `docs/research/specs/`
- Hard gate against code edits, scaffolding, bootstrap, and experiments
- `v2-required` blocked behavior (`stage_status: blocked`, `next_allowed_skills: []`)
- Spec-freeze contract includes runtime entry command and metric fields
- User review gate present

#### test-autoresearch-loop-harness.sh
Static contract checks for `autoresearch-loop`:
- Entry gate on validated bootstrap state (`bootstrap_status`, `baseline_status`, `baseline_ref`)
- `keep`/`discard`/`crash` vocabulary
- Normal termination (`stopped-completed`) and abnormal termination (`stopped-blocked`)
- Out-of-scope `reject-and-record` behavior
- `rejection_streak` is informational only (not in stop-condition logic)
- No proposal-class machinery from `research-experiment-loop`
- `profile-reference.md` documents `rejection_streak`, `results_row_ref`, `active_run_manifest`

### Autoresearch Live Integration Tests (use --autoresearch-integration)

These tests invoke Claude CLI with a temp project and verify actual artifact generation. They are isolated from the generic `--integration` and `--research-integration` suites.

#### test-autoresearch-brainstorming-integration.sh
Brainstorming artifact generation (~5-15 minutes):
- Creates a temp repo with `train.py` and initial state
- Runs `autoresearch-brainstorming` through the real Claude CLI
- Verifies:
  - spec written under `docs/autoresearch/specs/`
  - `active_spec_path` points to the generated spec
  - `profile_status: spec-frozen`
  - `next_allowed_skills: [autoresearch-planning]`
  - spec includes `runtime.entry_command` and V1 canonical git strategy enum values
  - no `docs/research/specs/` drift
  - no bootstrap artifacts created prematurely

#### test-autoresearch-bootstrap-integration.sh
Bootstrap artifact generation (~5-15 minutes):
- Creates a temp repo with frozen spec, approved plan, and `train.py`
- Runs `autoresearch-bootstrap` through the real Claude CLI
- Verifies:
  - `autoresearch/profile.yaml` created with `profile_version: 1`
  - `autoresearch/results.tsv` created with header and baseline row
  - `autoresearch/ledger.jsonl` created
  - `baseline_ref` recorded
  - `active_profile_path` points to generated profile
  - `bootstrap_status: completed`, `baseline_status: validated`
  - `next_allowed_skills: [autoresearch-loop]`
  - `best_ref` remains null (loop owns `best_ref`)
  - results.tsv uses `keep` status (not `baseline`)

#### test-autoresearch-loop-integration.sh
Loop gate/contract execution (~5-15 minutes):
- Creates a temp repo with completed bootstrap state, profile, results.tsv, and ledger.jsonl
- Runs `autoresearch-loop` through the real Claude CLI for one iteration
- Verifies:
  - entry gate passes on validated bootstrap state
  - new row appended to `results.tsv`
  - new entry appended to `ledger.jsonl` with `results_row_ref`
  - run manifest created under `autoresearch/runs/` with all four required fields
  - `active_run_manifest` and `last_run_status` set in state
  - `prepare.py` not modified (readonly respected)
  - results.tsv uses valid status vocabulary (`keep`/`discard`/`crash`)

## Isolation

The `--autoresearch-integration` mode runs only the autoresearch live suite. It does NOT activate the generic `--integration` suite or the `--research-integration` suite. To run those, use the runner in `superpowers-main/tests/claude-code/`.

## Adding New Tests

1. Create `test-autoresearch-<skill>-harness.sh` for fast static checks
2. Create `test-autoresearch-<skill>-integration.sh` for live Claude invocation
3. Add to the appropriate array in `run-skill-tests.sh`
4. Make executable: `chmod +x test-autoresearch-*.sh`
5. Document in this README

## Notes

- Fast harness tests use `rg` (ripgrep) to check SKILL.md content — no Claude invocation needed
- Live integration tests require Claude CLI and the superpowers plugin
- `--autoresearch-integration` is isolated from other integration suites by design
- Tests verify skill contracts and artifact schemas, not full multi-run experiment outcomes
