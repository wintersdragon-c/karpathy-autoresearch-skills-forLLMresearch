# Autoresearch Planning Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `autoresearch-planning` up to the same core control quality as `superpowers-origin/skills/writing-plans`, while adapting the task template and review rubric to computer-science research repo onboarding rather than generic feature TDD.

**Architecture:** Reuse upstream `writing-plans` wherever the mechanism is domain-agnostic: zero-context executor framing, rigid plan header, low-freedom task template, anti-placeholder discipline, self-review structure, scripted execution handoff, and optional external review rubric. Adapt only the parts that are genuinely research-specific: task step shape centers on artifact generation, baseline verification, log extraction, and loop-readiness checks instead of feature-code failing tests. Do not introduce new planning stages or new downstream skills.

**Tech Stack:** Markdown skill prompts, Markdown review sidecar, shell-based static fixture runner, Bash Claude harnesses, ripgrep assertions

---

## File Map

- Modify: `skills/autoresearch-planning/SKILL.md`
  Responsibility: Main controller prompt for turning an approved autoresearch spec into a concrete repository-adaptation plan.
- Create: `skills/autoresearch-planning/plan-document-reviewer-prompt.md`
  Responsibility: Optional higher-rigor plan review rubric, forked from upstream `writing-plans` and adapted to autoresearch plan semantics.
- Modify: `tests/autoresearch-skills/run-tests.sh`
  Responsibility: Static coverage for the stricter planning prompt contract and the new sidecar file.
- Modify: `tests/claude-code/run-skill-tests.sh`
  Responsibility: Register a new planning harness and planning reviewer test in the fast/live Claude runner.
- Create: `tests/claude-code/test-autoresearch-planning-harness.sh`
  Responsibility: Fast static contract checks for `autoresearch-planning`.
- Create: `tests/claude-code/test-autoresearch-planning-reviewer.sh`
  Responsibility: Live Claude proof that the plan-review sidecar catches seeded plan defects.
- Modify: `README.md`
  Responsibility: Keep the public description of `autoresearch-planning` aligned with the stronger controller contract.

## Task 1: Rebuild The Main Controller Around Upstream Writing-Plans Mechanics

**Files:**
- Modify: `skills/autoresearch-planning/SKILL.md`
- Modify: `tests/autoresearch-skills/run-tests.sh`

- [ ] **Step 1: Rewrite the overview so it inherits the upstream zero-context executor framing directly**

In `skills/autoresearch-planning/SKILL.md`, replace the current overview block with:

```md
## Overview

Write comprehensive repository-adaptation plans assuming the implementing agent has zero context for this repo and questionable taste. Document everything they need to know: which files to touch, what artifacts to create, what commands to run, what outputs to expect, and how to verify loop readiness. Give them the whole plan as bite-sized tasks. DRY. YAGNI. Frequent commits.

Assume the implementing agent is skilled, but knows almost nothing about this specific repo, the autoresearch toolchain, or good verification design for research scaffolding.

**Announce at start:** "I'm using the autoresearch-planning skill to create the repository adaptation plan."

**Context:** This should run only after `autoresearch-brainstorming` has produced an approved spec. The spec path is recorded in `autoresearch/state.yaml` under `active_spec_path`.

**Do NOT use if:** `active_spec_path` in `autoresearch/state.yaml` is null — stop immediately and report the error. Do not proceed without an approved spec.

**Save plans to:** `docs/autoresearch/plans/YYYY-MM-DD-<topic>-plan.md`
- (User preferences for plan location override this default)
```

- [ ] **Step 2: Expand File Structure and task-granularity sections so they match upstream strictness, but with research-scaffold semantics**

In `skills/autoresearch-planning/SKILL.md`, replace the current `## File Structure` and `## Bite-Sized Task Granularity` sections with:

```md
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
```

- [ ] **Step 3: Replace the loose Task Structure section with a rigid research-adapted task template**

In `skills/autoresearch-planning/SKILL.md`, replace the current `## Task Structure` section with:

````md
## Task Structure

Every task MUST follow this structure:

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing-file`
- Verify: `exact/path/to/generated-or-checked-artifact`

- [ ] **Step 1: Write or update the artifact**

```yaml
# or bash / markdown / python / json as appropriate
exact content here
```

- [ ] **Step 2: Run verification command**

Run: `exact command here`
Expected: `exact expected output, matched line, file existence check, or exit behavior`

- [ ] **Step 3: Record any additional readiness check needed for this artifact**

Run: `exact command here`
Expected: `exact expected output`

- [ ] **Step 4: Commit**

```bash
git add exact/path/to/file exact/path/to/other-file
git commit -m "docs: align autoresearch planning task structure"
```
````

Use shorter tasks when Step 3 is unnecessary, but never omit the `Files:` block, verification command, expected result, or commit step.
````

- [ ] **Step 4: Upgrade the static runner so it locks the restored upstream mechanics**

In `tests/autoresearch-skills/run-tests.sh`, extend the planning section with assertions for:

```bash
require_pattern "zero context.*questionable taste" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "This is where decomposition decisions get locked in" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Every task MUST follow this structure" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Run: " "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Expected: " "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Commit" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
```

- [ ] **Step 5: Run the static fixture runner**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
```

Expected: PASS, including `autoresearch-planning static checks`.

## Task 2: Restore The Full Upstream Self-Review And Scripted Execution Handoff

**Files:**
- Modify: `skills/autoresearch-planning/SKILL.md`
- Modify: `tests/autoresearch-skills/run-tests.sh`

- [ ] **Step 1: Replace the current Self-Review block with an upstream-shape checklist adapted to research plans**

In `skills/autoresearch-planning/SKILL.md`, replace `## Self-Review` with:

```md
## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section and frozen field in the approved spec. Can you point to a task that implements or verifies it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — `TBD`, `TODO`, `implement later`, `fill in details`, `add validation`, `handle edge cases`, or any step that describes work without exact content or exact commands. Fix them.

**3. Artifact and identifier consistency:** Do file paths, field names, command names, and artifact references used in later tasks match what you defined in earlier tasks? A plan that says `autoresearch/profile.yaml` in Task 2 but `profile.yml` in Task 5 is a bug.

**4. Verification coverage:** Does every generated artifact or wrapper have a concrete verification command and an expected result? If not, add it.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.
```

- [ ] **Step 2: Replace the current Exit Gate tail with the full scripted two-option handoff**

In `skills/autoresearch-planning/SKILL.md`, keep the `## Exit Gate` heading and YAML state-update block unchanged. Delete only the trailing sentence `Then offer the user the choice between...`, then append this new section immediately after the YAML block:

```md
## Execution Handoff

After saving the plan and updating `autoresearch/state.yaml`, offer execution choice:

**"Plan complete and saved to `docs/autoresearch/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + review between tasks

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
```

- [ ] **Step 3: Add static assertions for self-review completeness and scripted handoff**

In `tests/autoresearch-skills/run-tests.sh`, extend the planning section with:

```bash
require_pattern "Spec coverage:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Artifact and identifier consistency:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Verification coverage:" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Plan complete and saved to" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "1. Subagent-Driven \\(recommended\\)" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "2. Inline Execution" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Which approach\\?" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
```

- [ ] **Step 4: Run the static fixture runner again**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
```

Expected: PASS.

## Task 3: Add The Optional Plan Reviewer Sidecar And A Planning Harness

**Files:**
- Create: `skills/autoresearch-planning/plan-document-reviewer-prompt.md`
- Create: `tests/claude-code/test-autoresearch-planning-harness.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/autoresearch-skills/run-tests.sh`

- [ ] **Step 1: Create an autoresearch plan reviewer sidecar by forking upstream and adapting its review categories**

Create `skills/autoresearch-planning/plan-document-reviewer-prompt.md` with this content:

```md
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
    | Completeness | TODOs, placeholders, incomplete tasks, missing verification steps, missing mandatory scope areas |
    | Spec Alignment | Plan covers the approved compatibility label, frozen runtime command, metric, time budget, edit scope, and git/logging requirements |
    | Task Decomposition | Tasks have clear boundaries, each step is actionable, creation and verification are not silently bundled |
    | Buildability | Could an implementing agent follow this plan without guessing which artifact to create, which command to run, or what success looks like? |

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    An implementer building the wrong scaffold, skipping a mandatory artifact, or getting stuck on an underspecified verification step is an issue.
    Minor wording, stylistic preferences, and "nice to have" suggestions are not.

    Approve unless there are serious gaps — missing mandatory scope areas, contradictory tasks, placeholder content, or verification steps so vague they cannot be acted on.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
```

- [ ] **Step 2: Add a fast harness for `autoresearch-planning`**

Create `tests/claude-code/test-autoresearch-planning-harness.sh` with static checks for:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
REVIEWER="$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"

echo "=== Test: autoresearch-planning harness ==="
echo ""

echo "Test 1: Planning skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: Zero-context executor framing present..."
if rg -q "zero context.*questionable taste" "$SKILL"; then
    echo "  [PASS] Zero-context framing present"
else
    echo "  [FAIL] Zero-context framing missing"
    exit 1
fi
echo ""

echo "Test 3: Rigid task template present..."
if rg -q "Every task MUST follow this structure" "$SKILL" && rg -q "Run: " "$SKILL" && rg -q "Expected: " "$SKILL"; then
    echo "  [PASS] Rigid task template present"
else
    echo "  [FAIL] Rigid task template missing"
    exit 1
fi
echo ""

echo "Test 4: Full self-review contract present..."
if rg -q "Spec coverage:" "$SKILL" && rg -q "Artifact and identifier consistency:" "$SKILL" && rg -q "Verification coverage:" "$SKILL"; then
    echo "  [PASS] Self-review contract present"
else
    echo "  [FAIL] Self-review contract missing"
    exit 1
fi
echo ""

echo "Test 5: Scripted execution handoff present..."
if rg -q "Plan complete and saved to" "$SKILL" && rg -q "Subagent-Driven" "$SKILL" && rg -q "Inline Execution" "$SKILL"; then
    echo "  [PASS] Scripted execution handoff present"
else
    echo "  [FAIL] Scripted execution handoff missing"
    exit 1
fi
echo ""

echo "Test 6: Plan reviewer sidecar exists..."
if [ -f "$REVIEWER" ]; then
    echo "  [PASS] plan-document-reviewer-prompt.md present"
else
    echo "  [FAIL] plan-document-reviewer-prompt.md missing"
    exit 1
fi
echo ""

echo "Test 7: Plan reviewer sidecar categories present..."
if rg -q "Completeness" "$REVIEWER" && rg -q "Spec Alignment" "$REVIEWER" && rg -q "Task Decomposition" "$REVIEWER" && rg -q "Buildability" "$REVIEWER"; then
    echo "  [PASS] Plan reviewer categories present"
else
    echo "  [FAIL] Plan reviewer categories missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-planning harness tests passed ==="
```

- [ ] **Step 3: Register the new harness in the Claude runner and add static-runner checks for the sidecar**

In `tests/claude-code/run-skill-tests.sh`, add `test-autoresearch-planning-harness.sh` to the fast suite.

In `tests/autoresearch-skills/run-tests.sh`, add:

```bash
require_file "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Completeness" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Spec Alignment" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Task Decomposition" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
require_pattern "Buildability" "$REPO_ROOT/skills/autoresearch-planning/plan-document-reviewer-prompt.md"
```

- [ ] **Step 4: Run both static suites**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-planning-harness.sh
```

Expected: both PASS.

## Task 4: Add A Live Reviewer Test For The New Sidecar

**Files:**
- Create: `tests/claude-code/test-autoresearch-planning-reviewer.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Create a seeded-bad-plan live reviewer test mirroring the upstream pattern**

Create `tests/claude-code/test-autoresearch-planning-reviewer.sh` that:
- writes a temporary bad autoresearch plan file with three intentional defects:
  - one mandatory scope area omitted
  - one placeholder such as `TBD`
  - one verification step missing an `Expected:` line
- points Claude at `skills/autoresearch-planning/plan-document-reviewer-prompt.md`
- asks it to review the bad plan against the planning spec fixture at `tests/autoresearch-skills/fixtures/trigger-projects/autoresearch-planning/docs/autoresearch/specs/2026-04-10-autoresearch-design.md`
- fails unless Claude returns `Issues Found` and mentions the seeded defects

Use the same shell style as the existing `test-autoresearch-brainstorming-spec-reviewer.sh`: create temp files under `/tmp`, invoke the runner once, and assert on concrete issue strings with `rg`.

- [ ] **Step 2: Register the reviewer test in the Claude runner**

In `tests/claude-code/run-skill-tests.sh`, add `test-autoresearch-planning-reviewer.sh` in two places:
- register it so it can be invoked explicitly with `--test`
- add it to the `autoresearch_integration_tests` array so `--autoresearch-integration` runs it automatically

- [ ] **Step 3: Run the live reviewer test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-planning-reviewer.sh
```

Expected: PASS, with the reviewer catching all seeded plan defects.

## Task 5: Sync README And Run Full Verification

**Files:**
- Modify: `README.md`
- Verify only: `tests/autoresearch-skills/run-tests.sh`
- Verify only: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Update the `autoresearch-planning` section in `README.md`**

Replace the current description paragraph with:

```md
Produces a low-ambiguity plan under `docs/autoresearch/plans/` using a rigid task template, exact file paths, exact verification commands, expected outputs, and a scripted execution handoff. It preserves the upstream `writing-plans` discipline while adapting the step shape to research-repo scaffolding, profile generation, baseline verification, log extraction, and loop-readiness checks.
```

- [ ] **Step 2: Run the full static and fast-Claude verification set**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```

Expected:
- static runner PASS
- fast Claude suite PASS, including the new `autoresearch-planning` harness

- [ ] **Step 3: Run the full live autoresearch suite**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

Expected: `Passed: 5`, `Failed: 0`, `STATUS: PASSED` after adding the new planning reviewer test to the current four-test autoresearch live surface.

## Self-Review

Spec coverage against the identified gaps:
- Missing rigid task template: covered by Task 1.
- Missing full self-review contract and scripted execution handoff: covered by Task 2.
- Missing external plan reviewer sidecar and planning-specific Claude coverage: covered by Tasks 3 and 4.
- Public docs drift after controller strengthening: covered by Task 5.

Placeholder scan:
- No `TBD`, `TODO`, or deferred implementation wording remains in this plan itself.
- Every task includes exact files, exact text or concrete content requirements, and exact verification commands.

Consistency check:
- This plan intentionally preserves upstream `writing-plans` mechanisms where they are domain-agnostic and only adapts the task step shape to research-repo scaffolding.
- The expected final live total is `5` because this plan adds one new planning live test on top of the current four-test autoresearch live surface; the new planning harness belongs only to the fast suite.
