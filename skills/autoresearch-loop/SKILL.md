---
name: autoresearch-loop
description: "Use when an autoresearch profile and bootstrap surface are ready for bounded autonomous experiment iteration inside an approved editable scope."
---

## Overview

Autonomous experiment loop that runs inside a frozen profile. Each iteration proposes a change within the approved `edit_scope`, commits, runs the training script, extracts the metric, classifies the outcome as `keep`, `discard`, or `crash`, and updates state. The loop terminates on explicit stop conditions only.

## Entry Gate

All five conditions must be true before the loop starts:

1. `active_profile_path` is set and points to a readable profile artifact
2. `baseline_ref` is set (non-null)
3. `bootstrap_status: completed`
4. `baseline_status: validated`
5. Current git branch matches `git_policy.branch_prefix` — run `git branch --show-current` and verify the branch name starts with the prefix value from the profile

If any condition is false, set `stage_status: blocked` and `blocker_reason` explaining which gate failed. Do not proceed on the wrong branch.

## The Loop Cycle

Per-run steps (execute in order):

1. Read the profile from `active_profile_path`. Also read the key in-scope files listed in `edit_scope.allowed_paths` and `edit_scope.readonly_paths` to understand the current state of the code before proposing a change.
2. **Review history before proposing.** Git IS the memory — the agent must consult it before every proposal:
   - Read the last 10-20 results rows and recent ledger entries
   - Run `git log --oneline -20` to see recent experiment commits
   - If the previous accepted run was a keep, run `git diff HEAD~1` to understand what changed
   - Use `git show <commit-hash> --stat` to inspect earlier successful experiments when considering similar approaches
   - Do not repeat exact approaches that were already discarded or reverted
3. Propose a change within `edit_scope.allowed_paths`
3. If the proposed change requires files outside `edit_scope.allowed_paths`: **reject-and-record** (do NOT edit silently, do NOT ask for ad hoc permission); continue with another in-scope idea OR stop with `blocker_reason` if no valid in-scope ideas remain
4. Commit before the run; record `pre_run_commit` in the run manifest
5. Write run manifest to `autoresearch/runs/<run_id>.yaml`; set `active_run_manifest` in state.yaml
6. Execute `runtime.entry_command`, redirect output to `runtime.log_path`, enforce `runtime.timeout_seconds`
7. Extract metric using `logging.summary_extract_command`
8. Classify outcome: `keep`, `discard`, or `crash`
9. Append row to `autoresearch/results.tsv`
10. Append event to `autoresearch/ledger.jsonl`
11. Apply git strategy from profile (`keep_commit_strategy`, `discard_strategy`, or `crash_strategy`)
12. Update `last_run_status`, `best_ref` (if keep), `rejection_streak`
13. Update `active_run_manifest` in state.yaml

## Run Failure Handling

When a run crashes (non-zero exit, timeout, or metric extraction failure):

1. Read the last 50 lines of `runtime.log_path` to diagnose the failure
2. Judge whether the crash is fixable:
   - **Easy fix** (typo, missing import, off-by-one): apply the fix, increment `attempt_id`, re-run under the same `run_id` — up to `experiment.max_retry_on_crash` retries
   - **Fundamentally broken** (OOM on a too-large model, broken idea): do not retry; record final crash and move to the next idea
3. If retries are exhausted without success: record final crash status
4. On final crash: apply `crash_strategy` from profile, append crash row to `autoresearch/results.tsv`, append crash entry to `autoresearch/ledger.jsonl`

Each retry attempt gets its own `attempt_id` in the ledger entry. The `run_id` stays the same across retries for the same idea.

## Research Taste

The loop is not a mechanical optimizer. Apply these judgment rules at every keep/discard decision:

**Simplicity criterion:** All else being equal, simpler is better.
- A small metric improvement that adds significant complexity: weigh carefully, lean toward discard
- Equal or near-equal metric with simpler code: keep — this is a simplification win
- A metric improvement from deleting code: definitely keep
- A marginal improvement (e.g. 0.001) that adds 20 lines of hacky code: probably not worth it

**VRAM soft constraint:** `peak_memory_mb` is a secondary signal.
- Some VRAM increase is acceptable for meaningful metric gains
- Dramatic VRAM blowup with marginal metric gain: treat as a negative signal, lean toward discard even if metric improved
- VRAM increase that causes OOM: crash, not discard

**Equal performance:** If metric equals the current best and the change adds complexity, discard. If it simplifies the code, keep.

## Autonomous Operation

Once the loop has started, do NOT pause to ask the user if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The user may be away from their computer and expects the loop to run indefinitely until manually interrupted.

**If you run out of ideas:** Think harder. Re-read the in-scope files for new angles. Try combining previous near-misses. Try more radical architectural or optimizer changes. The loop runs until a stop condition is met or the user interrupts — not until you feel uncertain.

**results.tsv must not be committed to git.** It is an untracked working file. Never `git add autoresearch/results.tsv`.

## Periodic Summary Reporting

Every 10 iterations (or on bounded-run completion), print a brief progress summary:

```
Baseline: <baseline_metric>
Current best: <best_metric> (run <run_id>)
Keeps: N | Discards: N | Crashes: N
Last 5: keep, discard, keep, crash, keep
```

This is operator-facing output — it helps the user gauge progress without reading the full ledger.

## Editable-Surface Hard Gate

If a proposed change requires files outside `edit_scope.allowed_paths`:
- Reject the proposal
- Record rejection reason in ledger or run manifest
- Continue with another in-scope idea OR stop with `blocker_reason` if no valid in-scope ideas remain
- Do NOT ask for ad hoc permission once autonomy has begun

## Normal Termination

Stop when any of these occur:
- `experiment.max_experiments` is reached
- `experiment.max_consecutive_crashes` is reached
- User manually interrupts
- Profile defines another explicit stop condition and it is met
- If `experiment.max_experiments: null`, loop runs open-ended (must be explicit in profile, not implied)

`rejection_streak` is informational only — it tracks consecutive non-keep outcomes but does NOT trigger automatic stop in V1. Only `experiment.max_consecutive_crashes` triggers automatic stop.

### Exit Gate — Normal Termination

```yaml
current_stage: autoresearch-loop
stage_status: completed
experiment_status: stopped-completed
next_allowed_skills: []
```

### Exit Gate — Abnormal Termination

```yaml
current_stage: autoresearch-loop
stage_status: blocked
experiment_status: stopped-blocked
blocker_reason: <terminal reason>
next_allowed_skills: []
```

## State Ownership Contract

May write:
- `current_stage`, `stage_status`, `experiment_status`
- `active_run_manifest`, `best_ref`, `rejection_streak`, `last_run_status`
- `next_allowed_skills`, `rollback_target`, `blocker_reason`

May read but NOT write:
- `baseline_ref`, `active_profile_path`, `active_plan_path`

## Common Mistakes

| Mistake | Correct behavior |
|---|---|
| Importing typed proposal-class machinery from research-experiment-loop (named proposal categories, class-based reducers) | This skill has no proposal classes; propose changes freely within `edit_scope` |
| Stopping the loop when `rejection_streak` grows | `rejection_streak` is informational only; only `max_consecutive_crashes` triggers automatic stop |
| Editing files outside `edit_scope.allowed_paths` silently | Always reject-and-record; never silently edit out-of-scope files |
| Not committing before each run | Always commit before run; record `pre_run_commit` in run manifest |
| Asking for ad hoc permission mid-loop | Autonomy is granted at loop start; reject out-of-scope proposals, do not ask |

## Reference

See `profile-reference.md` for detailed field semantics: timeout vs time budget, crash retry policy, V1 git strategy enum values, `rejection_streak` informational semantics, `results_row_ref`, and `active_run_manifest`.
