# Autoresearch Brainstorming Minimal Alignment Follow-Up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining three `autoresearch-brainstorming` alignment gaps against `superpowers-origin/skills/brainstorming` without changing the established autoresearch-specific flow.

**Architecture:** Keep the current ten-step controller, no-visual-companion scope, optional spec-review sidecar, and terminal handoff to `autoresearch-planning`. Tighten only the three remaining controller contracts: implementation-skill hard gate wording, inline self-review completeness, and repo-context inspection breadth. Lock each change with the existing brainstorming harness and finish with the targeted live reviewer checks.

**Tech Stack:** Markdown skill prompts, Markdown review sidecar, Bash Claude harnesses, ripgrep-based static assertions

---

## File Map

- Modify: `skills/autoresearch-brainstorming/SKILL.md`
  Responsibility: Main controller prompt for diagnosis, questioning, design validation, self-review, and handoff.
- Modify: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`
  Responsibility: Fast static contract coverage for the controller wording.
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh`
  Responsibility: Live Claude proof that the optional sidecar still works after the controller wording change.

## Task 1: Tighten The Hard Gate To Match Upstream Implementation-Skill Semantics

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Modify: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`

- [ ] **Step 1: Replace the current hard-gate block with an upstream-strength version**

In `skills/autoresearch-brainstorming/SKILL.md`, replace the current `## Hard Gate` body with:

```md
## Hard Gate

**Do NOT:**
- Invoke any implementation skill before the spec is approved
- Edit any files in the target repo
- Write any scaffolding, adapters, or bootstrap files
- Execute any training runs or experiments
- Start planning before the spec is approved

**Hard gate: no implementation-skill invocation, no edits, no bootstrap, no runs, no planning — until the spec is approved. This applies to EVERY repo regardless of perceived simplicity.**
```

- [ ] **Step 2: Add a static harness assertion that specifically locks the implementation-skill prohibition**

In `tests/claude-code/test-autoresearch-brainstorming-harness.sh`, add one new test block after the existing hard-gate check:

```bash
echo "Test 5b: Hard gate explicitly forbids implementation-skill invocation before approval..."
if rg -q "Invoke any implementation skill before the spec is approved" "$SKILL" && \
   rg -q "no implementation-skill invocation" "$SKILL"; then
    echo "  [PASS] Implementation-skill prohibition present"
else
    echo "  [FAIL] Implementation-skill prohibition missing"
    exit 1
fi
echo ""
```

- [ ] **Step 3: Run the brainstorming harness**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
```

Expected: PASS with the new hard-gate assertion green.

## Task 2: Restore Upstream Scope-Check And Ambiguity-Check Semantics To Inline Self-Review

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Modify: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`

- [ ] **Step 1: Rewrite the Step 8 checklist so the controller itself carries the full review loop**

In `skills/autoresearch-brainstorming/SKILL.md`, replace the current Step 8 bullet list with:

```md
### Step 8: Spec Self-Review

Before presenting to the user, review the spec yourself:
- Is the compatibility label justified by evidence from the repo?
- Are all profile fields resolved with concrete values or documented null with justification?
- Are the key decisions justified?
- Do any sections contradict each other?
- Scope check: is this focused enough for a single planning/bootstrap cycle, or does it still hide multiple independent sub-targets?
- Ambiguity check: could any requirement be interpreted two different ways by planning or bootstrap? If so, pick one and make it explicit.
- Does it give enough context for planning and bootstrapping?
- Do `git_policy.keep_commit_strategy`, `git_policy.discard_strategy`, and `git_policy.crash_strategy` contain one of the canonical enum strings (`keep-current-commit`, `tag-current-commit-and-keep`, `hard-reset-to-pre-run-commit`, `soft-reset-to-pre-run-commit`, `keep-crash-commit-for-inspection`)? If any of these fields contain a free-form description instead of an enum string, fix them before proceeding.

Fix any issues found inline. No need to re-review — just fix and move on.

The `spec-document-reviewer-prompt.md` sidecar is an optional higher-rigor review resource. It is not a mandatory runtime step in the main brainstorming loop.
```

- [ ] **Step 2: Lock the restored scope-check and ambiguity-check wording in the static harness**

In `tests/claude-code/test-autoresearch-brainstorming-harness.sh`, add one new test block:

```bash
echo "Test 23: Inline spec self-review includes scope and ambiguity checks..."
if rg -q "Scope check:" "$SKILL" && rg -q "Ambiguity check:" "$SKILL"; then
    echo "  [PASS] Inline scope/ambiguity self-review checks present"
else
    echo "  [FAIL] Inline scope/ambiguity self-review checks missing"
    exit 1
fi
echo ""
```

- [ ] **Step 3: Re-run the brainstorming harness**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
```

Expected: PASS.

## Task 3: Broaden Repo Inspection To Include Docs And Recent History

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Modify: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`

- [ ] **Step 1: Expand Step 1 inspection language to match upstream context-gathering breadth**

In `skills/autoresearch-brainstorming/SKILL.md`, replace the Step 1 bullet list with:

```md
### Step 1: Inspect the Repo

Before asking any questions, read the target repo thoroughly:
- Read the training entry point (e.g., `train.py`, `main.py`, `run.py`)
- Read any existing config files, `requirements.txt`, `pyproject.toml`, or `Makefile`
- Read repo documentation that explains setup, training flow, logging, or experiment conventions
- Check recent commits or other local history signals if available, especially when they clarify the current training entry path or intended workflow
- Check for distributed training markers (`torchrun`, `deepspeed`, `accelerate launch`, multi-node flags)
- Understand the training loop, optimizer, and metric logging
```

- [ ] **Step 2: Lock docs/history inspection in the harness**

In `tests/claude-code/test-autoresearch-brainstorming-harness.sh`, add one new test block:

```bash
echo "Test 24: Repo inspection includes docs and recent-history signals..."
if rg -q "Read repo documentation" "$SKILL" && rg -q "recent commits or other local history signals" "$SKILL"; then
    echo "  [PASS] Repo inspection breadth present"
else
    echo "  [FAIL] Repo inspection breadth missing"
    exit 1
fi
echo ""
```

- [ ] **Step 3: Run the brainstorming harness again**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
```

Expected: PASS.

## Task 4: Run Targeted Live Verification

**Files:**
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh`
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-integration.sh`

- [ ] **Step 1: Run the seeded-bad-spec reviewer integration test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-spec-reviewer.sh
```

Expected: PASS. The optional sidecar should still catch seeded spec defects after the Step 8 wording change.

- [ ] **Step 2: Run the live brainstorming integration test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-integration.sh
```

Expected: PASS. The controller should still write the spec, set `active_spec_path`, preserve canonical git enums, and exit only to `autoresearch-planning`.

- [ ] **Step 3: Re-run the full autoresearch live suite**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

Expected: `Passed: 4`, `Failed: 0`, `STATUS: PASSED`.

## Self-Review

Spec coverage against the three reviewed gaps:
- Gap 1, upstream-strength hard gate against implementation-skill invocation: covered by Task 1.
- Gap 2, inline self-review missing scope-check and ambiguity-check semantics: covered by Task 2.
- Gap 3, repo inspection missing docs and recent-history context sources: covered by Task 3.

Placeholder scan:
- No `TBD`, `TODO`, or deferred implementation wording remains in this plan.
- Every task has exact files, exact text to add or replace, and exact verification commands.

Type and naming consistency:
- The plan consistently uses `autoresearch-planning`, `spec-document-reviewer-prompt.md`, `Scope check`, `Ambiguity check`, and `implementation-skill invocation`.
