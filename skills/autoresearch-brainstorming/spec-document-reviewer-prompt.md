# Autoresearch Spec Document Reviewer Prompt Template

Use this template when you want a higher-rigor review of an autoresearch spec document after it is written.

This template is a supporting review resource, not a mandatory runtime step in `autoresearch-brainstorming`.

**Dispatch after:** Spec document is written to `docs/autoresearch/specs/`

```
Task tool (general-purpose):
  description: "Review autoresearch spec document"
  prompt: |
    You are a spec document reviewer. Verify this autoresearch spec is complete and ready for planning.

    **Spec to review:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", missing profile fields, undocumented nulls |
    | Consistency | entry_command vs baseline.protocol mismatch; primary_edit_target not in allowed_paths |
    | Clarity | Profile field values ambiguous enough to cause bootstrap to build the wrong thing |
    | Scope | Spec covers more than one independent sub-target (should be split), or a `v1-bootstrap-fit` repo does not clearly bound the thin adapter surface |
    | YAGNI | Over-engineered adapters, unnecessary complexity in the approach |

    ## Profile Field Freeze Check

    Verify each of the following fields is present with a concrete value or a documented null
    with justification. Flag only if the field is missing, blank, or left as TBD/TODO:

    runtime.manager, runtime.env_prep_command, runtime.entry_command, runtime.timeout_seconds,
    experiment.time_budget_seconds, experiment.metric_name, experiment.metric_direction,
    edit_scope.allowed_paths, edit_scope.readonly_paths, edit_scope.primary_edit_target,
    baseline.must_run_first, baseline.protocol, baseline.baseline_description,
    git_policy.branch_prefix, git_policy.commit_before_run, git_policy.keep_commit_strategy,
    git_policy.discard_strategy, git_policy.crash_strategy,
    logging.run_log_path, logging.summary_extract_command, logging.results_columns

    Also verify git strategy fields use canonical enum values:
    - keep_commit_strategy: keep-current-commit | tag-current-commit-and-keep
    - discard_strategy: hard-reset-to-pre-run-commit | soft-reset-to-pre-run-commit
    - crash_strategy: hard-reset-to-pre-run-commit | keep-crash-commit-for-inspection
    Free-form descriptions like "keep the commit" or "reset on failure" are NOT valid enum values.

    If the spec uses `v1-bootstrap-fit`, verify it names the thin adapter boundary clearly enough that bootstrap can implement it without guessing or rewriting core training logic.

    ## Calibration

    **Only flag issues that would cause real problems during planning or bootstrap.**
    A missing profile field, a protocol/command mismatch, or a requirement so ambiguous it
    could cause the wrong baseline to run — those are issues. Minor wording improvements,
    stylistic preferences, and sections less detailed than others are not.

    Approve unless there are serious gaps that would lead to a flawed plan or a broken bootstrap.

    ## Output Format

    ## Spec Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Field/Section]: [specific issue] - [why it matters for planning or bootstrap]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
