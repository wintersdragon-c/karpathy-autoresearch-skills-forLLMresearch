# autoresearch-loop Profile Reference

Detailed field semantics for `profile.yaml` and `state.yaml` fields used by the autoresearch-loop skill.

---

## 1. timeout vs time budget

- `runtime.timeout_seconds` — hard process kill limit. If the training process is still running after this many seconds, the loop kills it and classifies the run as `crash`.
- `experiment.time_budget_seconds` — soft training budget passed inside the program (e.g., as a flag or environment variable). The program is expected to stop itself within this budget.

`timeout_seconds` must be greater than `time_budget_seconds`. The gap covers startup time, compilation, evaluation, log flush, and any other overhead outside the training loop itself. A gap of 30–60 seconds is typical for small repos.

---

## 2. Crash Retry Policy

- `experiment.max_retry_on_crash` — number of retry attempts under the same `run_id` before the run is recorded as a final crash. Each retry attempt gets its own `attempt_id` in the ledger.
- `experiment.max_consecutive_crashes` — if this many consecutive runs all end as `crash`, the loop stops automatically with `experiment_status: stopped-blocked`.

`rejection_streak` does NOT trigger automatic stop (see section 4).

---

## 3. V1 Git Strategy Allowed Values

### `keep_commit_strategy`
- `keep-current-commit` — leave the commit in place; HEAD advances
- `tag-current-commit-and-keep` — tag the commit before leaving HEAD advanced

### `discard_strategy`
- `hard-reset-to-pre-run-commit` — `git reset --hard <pre_run_commit>`
- `soft-reset-to-pre-run-commit` — `git reset --soft <pre_run_commit>`

### `crash_strategy`
- `hard-reset-to-pre-run-commit` — `git reset --hard <pre_run_commit>`
- `soft-reset-to-pre-run-commit` — `git reset --soft <pre_run_commit>`
- `keep-crash-commit-for-inspection` — leave the crash commit in place for debugging

Values outside this enum are not valid in V1 and must be rejected at loop start.

---

## 4. `rejection_streak` Semantics

`rejection_streak` is an informational counter of consecutive non-keep outcomes that still completed normally — such as discards or other rejected in-scope ideas. Crashes are handled separately by `experiment.max_consecutive_crashes` and do not increment `rejection_streak`. It is reset to 0 on each keep run.

It does NOT trigger automatic loop stop in V1. It is recorded in state.yaml for human visibility only. Only `experiment.max_consecutive_crashes` triggers automatic stop.

Do not add logic that stops the loop based on `rejection_streak` alone.

---

## 5. `results_row_ref` Semantics

`results_row_ref` in a ledger entry is the `commit` value from the corresponding row in `autoresearch/results.tsv`. It cross-references the human-readable TSV from the machine-readable ledger without introducing a second row-numbering scheme.

To find the TSV row for a ledger entry: look up the row in `results.tsv` where the `commit` column matches `results_row_ref`.

---

## 6. `active_run_manifest` Semantics

`active_run_manifest` in state.yaml is the path to the per-run scratch file (`autoresearch/runs/<run_id>.yaml`). It is overwritten for each new run.

It is NOT canonical history. `ledger.jsonl` is the canonical record of all runs. `active_run_manifest` is a convenience pointer to the most recent run's scratch file, useful for inspecting the current or last run without scanning the ledger.
