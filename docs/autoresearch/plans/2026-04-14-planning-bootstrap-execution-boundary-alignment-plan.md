# Planning Bootstrap Execution Boundary Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore a strict `planning -> bootstrap -> loop` pipeline by making `autoresearch-planning` stop after writing the approved plan and embedding `executing-plans` execution discipline into `autoresearch-bootstrap`.

**Architecture:** Keep `autoresearch-planning` as a pure plan-writing stage: it writes the plan, updates `active_plan_path`, sets `next_allowed_skills: [autoresearch-bootstrap]`, and tells the user the next step is to invoke `autoresearch-bootstrap`. Rebuild `autoresearch-bootstrap` as the sole executor of the approved bootstrap plan, embedding the core `executing-plans` discipline: critical plan review before action, TodoWrite task tracking derived from the approved plan's task list, and strict stop-on-blocker rules. Bootstrap remains a mid-pipeline stage — it exits to `autoresearch-loop`, not to branch finalization. No subagent sidecars are introduced — inline executing-plans discipline only.

**Tech Stack:** Markdown skill prompts, Bash static runner, Bash Claude harnesses, ripgrep assertions, existing autoresearch fixture tree

---

## File Map

- Modify: `skills/autoresearch-planning/SKILL.md`
  Responsibility: Pure plan-writing controller; no execution choice after exit.
- Modify: `skills/autoresearch-bootstrap/SKILL.md`
  Responsibility: Sole executor of the approved bootstrap plan, with embedded executing-plans discipline.
- Modify: `tests/autoresearch-skills/run-tests.sh`
  Responsibility: Static contract coverage for the new planning exit behavior and bootstrap executing-plans mechanics.
- Modify: `tests/claude-code/test-autoresearch-planning-harness.sh`
  Responsibility: Fast static checks for planning's strict exit-only behavior.
- Create: `tests/claude-code/test-autoresearch-bootstrap-harness.sh`
  Responsibility: Fast static contract checks for bootstrap executing-plans mechanics.
- Modify: `tests/claude-code/run-skill-tests.sh`
  Responsibility: Register the new bootstrap harness in the fast suite.
- Modify: `README.md`
  Responsibility: User-facing pipeline and skill-role description.

## Task 1: Make `autoresearch-planning` A Pure Plan-Writing Stage

**Files:**
- Modify: `skills/autoresearch-planning/SKILL.md`
- Modify: `tests/autoresearch-skills/run-tests.sh`
- Modify: `tests/claude-code/test-autoresearch-planning-harness.sh`

- [ ] **Step 1: Remove the `## Execution Handoff` section and replace it with `## Next Step`**

In `skills/autoresearch-planning/SKILL.md`, delete the entire `## Execution Handoff` section (from the `## Execution Handoff` heading through the end of the file) and replace it with:

```md
## Next Step

After saving the plan and updating `autoresearch/state.yaml`, stop planning work.

Tell the user:

> "Plan written to `<path>`. The planning stage is complete. The next step is to invoke `autoresearch-bootstrap`, which reads this approved plan and executes it."

The ONLY valid next skill is `autoresearch-bootstrap`. Planning does not execute bootstrap tasks itself.
```

- [ ] **Step 2: Update static runner assertions for planning**

In `tests/autoresearch-skills/run-tests.sh`, find and replace the four lines that check for the old execution handoff:

Old (remove these four lines):
```bash
require_pattern "Plan complete and saved to" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "1. Subagent-Driven \\(recommended\\)" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "2. Inline Execution" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_pattern "Which approach\\?" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
```

New (add these four lines in their place):
```bash
require_pattern "The ONLY valid next skill is" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Subagent-Driven \\(recommended\\)" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Inline Execution" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
require_absent_pattern "Which approach" "$REPO_ROOT/skills/autoresearch-planning/SKILL.md"
```

- [ ] **Step 3: Update the fast planning harness**

In `tests/claude-code/test-autoresearch-planning-harness.sh`:

Replace Test 5 (the block from `echo "Test 5: Scripted execution handoff present..."` through its closing `echo ""`) with:

```bash
echo "Test 5: Strict pipeline handoff to bootstrap present..."
if { rg -q "next step is to invoke.*autoresearch-bootstrap" "$SKILL" || rg -q "The ONLY valid next skill is" "$SKILL"; } && \
   ! rg -q "Subagent-Driven" "$SKILL" && \
   ! rg -q "Inline Execution" "$SKILL"; then
    echo "  [PASS] Strict pipeline handoff present, execution modes absent"
else
    echo "  [FAIL] Pipeline handoff missing or execution modes still present"
    exit 1
fi
echo ""
```

Replace Test 10 (the block from `echo "Test 10: Execution handoff uses two-stage review wording..."` through its closing `echo ""`) with:

```bash
echo "Test 10: ONLY valid next skill constraint present..."
if rg -q "The ONLY valid next skill is" "$SKILL"; then
    echo "  [PASS] ONLY valid next skill constraint present"
else
    echo "  [FAIL] ONLY valid next skill constraint missing"
    exit 1
fi
echo ""
```

- [ ] **Step 4: Run the static and fast planning checks**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-planning-harness.sh
```

Expected: both PASS.

## Task 2: Embed `executing-plans` Discipline Into `autoresearch-bootstrap`

**Files:**
- Modify: `skills/autoresearch-bootstrap/SKILL.md`
- Modify: `tests/autoresearch-skills/run-tests.sh`
- Create: `tests/claude-code/test-autoresearch-bootstrap-harness.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Integrate critical plan review and TodoWrite into Step 1 of bootstrap**

In `skills/autoresearch-bootstrap/SKILL.md`, replace the current `### Step 1 — Read the approved plan` block with:

```md
### Step 1 — Load and review the approved plan

Read the file at `active_plan_path`. Review it critically before taking any action:
- Does the plan cover all six mandatory areas (profile generation, state scaffolding, log extraction, baseline verification, thin adapter if needed, loop-readiness check)?
- Are there any unclear steps, missing verification commands, or gaps that would block execution?
- Do file paths, field names, and commands in later tasks match what earlier tasks define?

If you find concerns, raise them with the user before starting. Do not silently work around gaps.

If no concerns, create a TodoWrite with one item per task in the approved plan (not per bootstrap prompt heading) and proceed.
```

- [ ] **Step 2: Add `## When To Stop And Ask` and `## Remember` sections after `## Hard Gates`**

In `skills/autoresearch-bootstrap/SKILL.md`, insert the following two sections immediately after the `## Hard Gates` section (before `## Exit Gate`):

```md
## When To Stop And Ask

STOP bootstrap execution immediately if:
- a plan step is unclear or conflicts with the spec
- a required verification command fails twice
- a generated artifact would exceed the approved adapter boundary
- the baseline run exits non-zero or times out (set `blocker_reason` and stop)
- log extraction fails after a successful run

Ask for clarification rather than guessing. Do not silently rewrite the plan in your head.

## Remember

- Review the plan critically before starting — raise concerns before taking action
- Follow plan steps exactly — do not skip verifications
- Stop when blocked — ask rather than guess
- Never start on main/master branch without explicit user consent
```

- [ ] **Step 3: Add static runner assertions for bootstrap executing-plans mechanics**

In `tests/autoresearch-skills/run-tests.sh`, add the following four lines immediately before `echo "[PASS] autoresearch-bootstrap static checks"`:

```bash
require_pattern "Review it critically" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "TodoWrite" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "STOP bootstrap execution immediately" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
require_pattern "Review the plan critically before starting" "$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"
```

- [ ] **Step 4: Create `tests/claude-code/test-autoresearch-bootstrap-harness.sh`**

Create the file with this exact content:

```bash
#!/usr/bin/env bash
# Fast harness: autoresearch-bootstrap static contract checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/autoresearch-bootstrap/SKILL.md"

echo "=== Test: autoresearch-bootstrap harness ==="
echo ""

echo "Test 1: Bootstrap skill file exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md present"
else
    echo "  [FAIL] SKILL.md missing"
    exit 1
fi
echo ""

echo "Test 2: Critical plan review step present..."
if rg -q "Review it critically" "$SKILL"; then
    echo "  [PASS] Critical review step present"
else
    echo "  [FAIL] Critical review step missing"
    exit 1
fi
echo ""

echo "Test 3: TodoWrite task tracking present..."
if rg -q "TodoWrite" "$SKILL"; then
    echo "  [PASS] TodoWrite tracking present"
else
    echo "  [FAIL] TodoWrite tracking missing"
    exit 1
fi
echo ""

echo "Test 4: Stop conditions present..."
if rg -q "STOP bootstrap execution immediately" "$SKILL"; then
    echo "  [PASS] Stop conditions present"
else
    echo "  [FAIL] Stop conditions missing"
    exit 1
fi
echo ""

echo "Test 5: Remember rules present..."
if rg -q "Review the plan critically before starting" "$SKILL" && rg -q "Stop when blocked" "$SKILL"; then
    echo "  [PASS] Remember rules present"
else
    echo "  [FAIL] Remember rules missing"
    exit 1
fi
echo ""

echo "=== All autoresearch-bootstrap harness tests passed ==="
```

- [ ] **Step 5: Register the new harness in `tests/claude-code/run-skill-tests.sh`**

In `tests/claude-code/run-skill-tests.sh`, make two edits:

First, replace the `fast_tests` array:

Old:
```bash
fast_tests=(
    "test-autoresearch-brainstorming-harness.sh"
    "test-autoresearch-loop-harness.sh"
    "test-autoresearch-planning-harness.sh"
)
```

New:
```bash
fast_tests=(
    "test-autoresearch-brainstorming-harness.sh"
    "test-autoresearch-loop-harness.sh"
    "test-autoresearch-planning-harness.sh"
    "test-autoresearch-bootstrap-harness.sh"
)
```

Second, in the `--help` output block, add `test-autoresearch-bootstrap-harness.sh` to the fast tests listing:

Old:
```bash
echo "Fast Tests (run by default):"
echo "  test-autoresearch-brainstorming-harness.sh   Static brainstorming contract checks"
echo "  test-autoresearch-loop-harness.sh            Static loop contract checks"
```

New:
```bash
echo "Fast Tests (run by default):"
echo "  test-autoresearch-brainstorming-harness.sh   Static brainstorming contract checks"
echo "  test-autoresearch-loop-harness.sh            Static loop contract checks"
echo "  test-autoresearch-bootstrap-harness.sh       Static bootstrap contract checks"
```

- [ ] **Step 6: Run the static runner and full fast suite**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```

Expected: PASS, including the new bootstrap harness.

## Task 3: Update Docs

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the `autoresearch-planning` description in `README.md`**

In `README.md`, replace the `### autoresearch-planning` paragraph (lines 51–53):

Old:
```md
Produces a low-ambiguity plan under `docs/autoresearch/plans/` using a rigid task template, exact file paths, exact verification commands, expected outputs, and a scripted execution handoff. It preserves the upstream `writing-plans` discipline while adapting the step shape to research-repo scaffolding, profile generation, baseline verification, log extraction, and loop-readiness checks.
```

New:
```md
Produces a low-ambiguity plan under `docs/autoresearch/plans/` using a rigid task template, exact file paths, exact verification commands, and expected outputs. After saving the plan and updating `autoresearch/state.yaml`, it stops — the only valid next skill is `autoresearch-bootstrap`. It does not offer execution modes.
```

- [ ] **Step 2: Update the `autoresearch-bootstrap` description in `README.md`**

In `README.md`, replace the `### autoresearch-bootstrap` paragraph (lines 57–58):

Old:
```md
Runs a single unified bootstrap pass: generates `autoresearch/profile.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`, and any thin adapters; runs the mandatory baseline; records `baseline_ref`. Exits to `autoresearch-loop`.
```

New:
```md
Reads and executes the approved plan using embedded `executing-plans` discipline: reviews the plan critically before acting, tracks the approved plan's tasks with TodoWrite, and stops on blockers rather than guessing. Generates `autoresearch/profile.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`, and any thin adapters; runs the mandatory baseline; records `baseline_ref`. Exits to `autoresearch-loop`.
```

- [ ] **Step 3: Verify the README changes**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
rg -n "autoresearch-planning|autoresearch-bootstrap|ONLY valid|executing-plans discipline" README.md
```

Expected: lines showing the updated planning description (no "scripted execution handoff"), the updated bootstrap description (with "executing-plans discipline"), and the pipeline diagram unchanged.

## Task 4: Run Full Verification

**Files:**
- Verify only: `tests/autoresearch-skills/run-tests.sh`
- Verify only: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Run the full static runner**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/autoresearch-skills/run-tests.sh
```

Expected: PASS.

- [ ] **Step 2: Run the full fast Claude suite**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh
```

Expected: PASS, including:
- `test-autoresearch-planning-harness.sh`
- `test-autoresearch-bootstrap-harness.sh`
- existing brainstorming and loop harnesses

- [ ] **Step 3: Run the full live autoresearch suite**

Run:
```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

Expected: PASS with all autoresearch live tests green after the planning/bootstrap boundary shift.

## Self-Review

Spec coverage:
- Planning-as-pure-plan-writer is covered by Task 1.
- Bootstrap-as-sole-executor with executing-plans discipline is covered by Task 2.
- Docs sync is covered by Task 3.
- Full verification closure is covered by Task 4.

Placeholder scan:
- No `TBD`, `TODO`, or deferred implementation wording remains in this plan.
- Every task contains exact files, concrete text requirements, and explicit verification commands.

Consistency check:
- This plan removes execution choice from `autoresearch-planning` and embeds executing-plans mechanics into `autoresearch-bootstrap`.
- No subagent-driven-development sidecars are introduced — inline executing-plans discipline only.
- `finishing-a-development-branch` is intentionally excluded: bootstrap is a mid-pipeline stage that exits to `autoresearch-loop`, not to branch finalization.
- The fixture plan file at `tests/autoresearch-skills/fixtures/trigger-projects/autoresearch-bootstrap/docs/autoresearch/plans/2026-04-10-autoresearch-plan.md` still references `subagent-driven-development` in its plan document header (this is the plan document template, not the skill execution flow — the static runner check at line 192 of `run-tests.sh` remains valid and does not need updating).
