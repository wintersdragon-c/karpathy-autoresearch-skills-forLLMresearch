---
name: autoresearch-planning
description: Use when an approved autoresearch repo-diagnosis spec must be converted into a concrete repository adaptation plan before touching code.
---

# Autoresearch Planning

## Overview

Write comprehensive repository-adaptation plans assuming the implementing agent has zero context for this repo and questionable taste. Document everything they need to know: which files to touch, what artifacts to create, what commands to run, what outputs to expect, and how to verify loop readiness. Give them the whole plan as bite-sized tasks. DRY. YAGNI. Frequent commits.

Assume the implementing agent is skilled, but knows almost nothing about this specific repo, the autoresearch toolchain, or good verification design for research scaffolding.

**Announce at start:** "I'm using the autoresearch-planning skill to create the repository adaptation plan."

**Context:** This should run only after `autoresearch-brainstorming` has produced an approved spec. The spec path is recorded in `autoresearch/state.yaml` under `active_spec_path`.

**Do NOT use if:** `active_spec_path` in `autoresearch/state.yaml` is null — stop immediately and report the error. Do not proceed without an approved spec.

**Save plans to:** `docs/autoresearch/plans/YYYY-MM-DD-<topic>-plan.md`
- (User preferences for plan location override this default)

## Scope Check

Read the approved spec before writing anything. If the spec covers multiple independent repos or incompatible compatibility labels, flag this and ask the user to split into separate specs. Each plan should produce a fully loop-ready repo on its own.

## Mandatory Plan Scope

Every autoresearch adaptation plan MUST cover all six areas:

1. **File map** — list every file to be created or modified and its responsibility
2. **Profile generation** — produce `autoresearch/profile.yaml` from the spec
3. **State/results/ledger scaffolding** — create `autoresearch/state.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`
4. **Thin adapters or wrappers** — add any shim needed to make `train.py` conform to the expected interface (only if the spec flags a mismatch)
5. **Log extraction setup** — verify the log extraction command (e.g. `grep "^val_bpb:" run.log`) works against a real or synthetic log sample
6. **Loop readiness checks** — confirm the full dry-run sequence: `uv run train.py` (or equivalent) completes within the time budget and the metric line is extractable

If any area is not applicable for this repo, state why explicitly — do not silently omit it.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing research repos, follow established patterns. If the repo already has a runner, config, or logging convention, adapt around it instead of inventing a parallel structure unless the spec explicitly requires a thin wrapper.
- Every introduced file must earn its keep: profile schema, state template, results table, ledger, thin adapter, log extractor, or readiness verifier.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

Autoresearch bootstrap and scaffold work is usually not feature-code TDD, so the plan should inherit upstream low-granularity discipline without forcing fake failing tests.

**Each step is one action (2-5 minutes):**
- "Write or update artifact `<path>`" — step
- "Run verification command: `<cmd>`" — step
- "Confirm output matches expected: `<expected>`" — step
- "Commit" — step

Never bundle artifact creation and verification into one step. If a task changes plan text, templates, wrapper scripts, or extraction commands, spell out the exact content and the exact verification command.

## Remember
- Exact file paths always
- Exact artifact content in every write step
- Exact commands with expected output
- DRY, YAGNI, frequent commits

## Metric Verify Validation

The plan's verify pipeline must produce a clean numeric output that downstream skills can parse mechanically:

- The verify pipeline must dry-run successfully before bootstrap executes it.
- The final extracted output must match the pattern `^-?[0-9]+\.?[0-9]*$`.
- Reject common bad outputs explicitly: `85.2%` (trailing unit), `342ms` (trailing unit), empty output, multi-line output, or prose such as `PASS`.
- Every plan must specify where the metric is extracted from: stdout, a log file, jsonl, or csv.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Repo Name] Autoresearch Adaptation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this scaffolds]

**Architecture:** [2-3 sentences about the adaptation approach]

**Tech Stack:** [Key technologies/libraries used by the target repo]

---
```

## Task Structure

Every task MUST follow this structure:

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing-file`
- Verify: `exact/path/to/generated-or-checked-artifact`

- [ ] **Step 1: Write or update the artifact**

(yaml/bash/markdown/python/json content here — exact content, not a placeholder)

- [ ] **Step 2: Run verification command**

Run: `exact command here`
Expected: `exact expected output, matched line, file existence check, or exit behavior`

- [ ] **Step 3: Record any additional readiness check needed for this artifact**

Run: `exact command here`
Expected: `exact expected output`

- [ ] **Step 4: Commit**

```bash
git add exact/path/to/file exact/path/to/other-file
git commit -m "chore: add artifact"
```
````

Use shorter tasks when Step 3 is unnecessary, but never omit the `Files:` block, verification command, expected result, or commit step.

## No Placeholders

Every step must contain the actual content the agent needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Similar to Task N" (repeat the artifact content — the agent may be reading tasks out of order)
- Steps that describe what to write without showing the exact content (YAML/bash/python blocks required for artifact steps)
- References to file paths, field names, or commands not defined in any task

If a runtime value is genuinely unknown at plan-writing time (e.g., a commit SHA that only exists after a run), state exactly which command produces it and where to read it from — do not leave a blank.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section and frozen field in the approved spec. Can you point to a task that implements or verifies it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — `TBD`, `TODO`, `implement later`, `fill in details`, `add validation`, `handle edge cases`, or any step that describes work without exact content or exact commands. Fix them.

**3. Artifact and identifier consistency:** Do file paths, field names, command names, and artifact references used in later tasks match what you defined in earlier tasks? A plan that says `autoresearch/profile.yaml` in Task 2 but `profile.yml` in Task 5 is a bug.

**4. Verification coverage:** Does every generated artifact or wrapper have a concrete verification command and an expected result? If not, add it.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## State Ownership Contract

This skill owns the following fields in `autoresearch/state.yaml`:
- **May write:** `current_stage`, `stage_status`, `active_plan_path`, `next_allowed_skills`, `rollback_target`, `blocker_reason`
- **May read but NOT write:** `baseline_ref`, `best_ref`, `profile_status`

## Exit Gate

After saving the plan, update `autoresearch/state.yaml`:

```yaml
stage_status: completed
active_plan_path: <path to approved plan>   # must be verified readable
next_allowed_skills:
  - autoresearch-bootstrap
```

## Next Step

After saving the plan and updating `autoresearch/state.yaml`, stop planning work.

Tell the user:

> "Plan written to `<path>`. The planning stage is complete. The next step is to invoke `autoresearch-bootstrap`, which reads this approved plan and executes it."

The ONLY valid next skill is `autoresearch-bootstrap`. Planning does not execute bootstrap tasks itself.
