# Autoresearch Plan Document Reviewer Prompt Template

Use this template when dispatching a higher-rigor review of an autoresearch plan document.

This template is a supporting review resource, not a mandatory runtime step in `autoresearch-planning`.

**Purpose:** Verify the plan is complete, matches the approved autoresearch spec, and has proper task decomposition for repository adaptation.

**Dispatch after:** The complete plan is written.

```
Task tool (general-purpose):
  description: "Review autoresearch plan document"
  prompt: |
    You are a plan document reviewer. Verify this autoresearch plan is complete and ready for implementation.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, incomplete tasks, missing verification steps, missing mandatory scope areas (profile generation, log extraction, loop-readiness check) |
    | Spec Alignment | Plan covers the approved compatibility label, frozen runtime command, metric, time budget, edit scope, and git/logging requirements |
    | Task Decomposition | Tasks have clear boundaries, each step is actionable, creation and verification are not silently bundled |
    | Buildability | Could an implementing agent follow this plan without guessing which artifact to create, which command to run, or what success looks like? |

    **Mandatory scope audit:** Autoresearch plans MUST cover all six areas. Check each one explicitly and flag any that are missing:
    1. Profile generation — `autoresearch/profile.yaml` created with all frozen spec fields
    2. State scaffolding — `autoresearch/state.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl` created
    3. Log extraction setup — `summary_extract_command` and `results_columns` wired up so the loop can parse run output
    4. Baseline verification — a step that runs the entry command and confirms it exits cleanly
    5. Thin adapter (if `v1-bootstrap-fit`) — adapter file created and verified
    6. Loop-readiness check — final verification that all required artifacts exist before handing off to bootstrap

    If any of these six areas has no corresponding task or step in the plan, flag it as an issue.

    **Verification step rule:** Every step that runs a command MUST have both a `Run:` line and an `Expected:` line. A step with `Run:` but no `Expected:` is an incomplete verification — the implementer cannot know whether the command succeeded. Flag any such step as an issue.

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    An implementer building the wrong scaffold, skipping a mandatory artifact, or getting stuck on an underspecified verification step is an issue.
    Minor wording, stylistic preferences, and "nice to have" suggestions are not.

    Approve unless there are serious gaps — missing mandatory scope areas, contradictory tasks, placeholder content, or verification steps missing their `Expected:` line.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
