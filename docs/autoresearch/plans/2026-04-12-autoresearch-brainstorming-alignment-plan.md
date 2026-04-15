# Autoresearch Brainstorming Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten `autoresearch-brainstorming` so it keeps the current stable controller flow while aligning more closely with the strongest non-visual design mechanics from `superpowers-origin/skills/brainstorming`.

**Architecture:** Keep the current ten-step controller skeleton, review loop, and terminal handoff to `autoresearch-planning`. Add only the missing upstream design principles and wording clarifications that materially improve downstream `planning` and `bootstrap` behavior. Do not reintroduce `Visual Companion`, and do not expand the skill into a new runtime stage machine.

**Tech Stack:** Markdown skill prompts, Markdown sidecar prompt, shell-based static/live test harnesses, ripgrep-based assertions

---

## File Map

- Modify: `skills/autoresearch-brainstorming/SKILL.md`
  Responsibility: Main controller prompt for repo diagnosis, questioning, design validation, spec writing, and handoff.
- Modify: `skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md`
  Responsibility: Optional higher-rigor spec review rubric aligned with the controller's expectations.
- Modify: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`
  Responsibility: Fast static contract checks for prompt wording and sidecar presence.
- Modify: `tests/claude-code/test-autoresearch-brainstorming-integration.sh`
  Responsibility: Live Claude check that the brainstorming skill produces the expected spec/state behavior.
- Modify: `tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh`
  Responsibility: Live Claude check that the spec-review sidecar catches seeded spec problems.
- Modify: `README.md`
  Responsibility: High-level user-facing description of what `autoresearch-brainstorming` guarantees.

## Task 1: Add Missing Upstream Design Principles To The Controller

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Test: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`

- [ ] **Step 1: Add an explicit “design for isolation and clarity” section to the brainstorming controller**

Insert a short section after the design-presentation step that carries over the upstream principles in autoresearch-specific language. The new section should say, in substance:

```md
### Design for Isolation and Clarity

- Prefer the thinnest possible compatibility layer that preserves the repo's real execution semantics.
- Keep the approved editable surface small, explicit, and stable across runs.
- Separate repo diagnosis, profile freezing, bootstrap scaffolding, and experiment execution into distinct responsibilities.
- For each introduced file or adapter, be able to explain: what it does, how the next skill uses it, and what existing repo surface it depends on.
- If a proposed change would require broad restructuring of unrelated code, reject it at brainstorming time and choose a narrower design.
```

- [ ] **Step 2: Add an explicit “working in existing codebases” section**

Add a short section immediately after the isolation section:

```md
### Working in Existing Research Repos

- Explore and follow the repo's existing training and logging patterns before proposing adaptation.
- Preserve the repo's real training entry semantics unless the approved approach explicitly introduces a thin wrapper.
- Include targeted cleanup only when it directly serves onboarding into the autoresearch workflow.
- Do NOT propose unrelated refactors during brainstorming.
```

- [ ] **Step 3: Run the brainstorming harness to verify the file still contains the existing controller contract**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
```

Expected: PASS with no regressions to the existing checklist/flow/review-loop assertions.

- [ ] **Step 4: Commit the prompt-principles change**

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
git add skills/autoresearch-brainstorming/SKILL.md tests/claude-code/test-autoresearch-brainstorming-harness.sh
git commit -m "docs: add autoresearch brainstorming design principles"
```

## Task 2: Clarify `v1-bootstrap-fit` Adapter Boundaries

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Modify: `skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md`
- Test: `tests/claude-code/test-autoresearch-brainstorming-harness.sh`

- [ ] **Step 1: Tighten the `v1-bootstrap-fit` definition in the controller**

Replace the current `v1-bootstrap-fit` paragraph with wording that makes the adapter boundary explicit:

```md
- **`v1-bootstrap-fit`**: Repo needs a thin compatibility layer, but the core training loop is still compatible with V1. Valid cases include: metric extraction needs a small wrapper, an entry command shim is needed, or a generated config/profile file is required. Invalid cases include: rewriting the core training loop, broad restructuring across unrelated files, or introducing orchestration that changes the repo's execution model. The spec must state exactly what the thin adapter is, why it is needed, and which file or generated artifact will carry it.
```

- [ ] **Step 2: Add a write-time requirement to the spec section**

In the “The spec MUST include” block, add one new bullet:

```md
- Adapter boundary (required for `v1-bootstrap-fit`: what thin adapter is needed, where it will live, and what it must NOT change)
```

- [ ] **Step 3: Add a matching reviewer-sidecar check**

Extend `skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md` by adding one line under the category table or the field-freeze section:

```md
| Scope | Spec covers more than one independent sub-target, or a `v1-bootstrap-fit` repo does not clearly bound the thin adapter surface |
```

and one explicit sentence below the profile-field block:

```md
If the spec uses `v1-bootstrap-fit`, verify it names the thin adapter boundary clearly enough that bootstrap can implement it without guessing or rewriting core training logic.
```

- [ ] **Step 4: Run the brainstorming harness again**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-harness.sh
```

Expected: PASS.

- [ ] **Step 5: Commit the bootstrap-fit contract change**

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
git add skills/autoresearch-brainstorming/SKILL.md skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md tests/claude-code/test-autoresearch-brainstorming-harness.sh
git commit -m "docs: clarify autoresearch bootstrap-fit adapter boundary"
```

## Task 3: Clarify Sidecar Status Without Turning It Into A Runtime Stage

**Files:**
- Modify: `skills/autoresearch-brainstorming/SKILL.md`
- Modify: `skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md`
- Test: `tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh`

- [ ] **Step 1: Add one line to the main controller explaining the sidecar’s status**

Under Step 8 or immediately after it, add:

```md
The spec-reviewer sidecar is an optional higher-rigor review resource. It is NOT a required control-flow stage in the main brainstorming loop.
```

- [ ] **Step 2: Align the sidecar intro with that status**

Update the first two lines of `spec-document-reviewer-prompt.md` so they read:

```md
Use this template when you want a higher-rigor review of an autoresearch spec document after it is written.

This template is a supporting review resource, not a mandatory runtime step in `autoresearch-brainstorming`.
```

- [ ] **Step 3: Run the spec-reviewer integration test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-spec-reviewer.sh
```

Expected: PASS. The seeded-bad-spec reviewer test should still succeed because the template remains usable even though it is optional in the controller flow.

- [ ] **Step 4: Commit the sidecar-status clarification**

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
git add skills/autoresearch-brainstorming/SKILL.md skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh
git commit -m "docs: clarify autoresearch spec reviewer sidecar status"
```

## Task 4: Keep User-Facing Docs Consistent With The Controller

**Files:**
- Modify: `README.md`
- Test: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Update the brainstorming section in the root README**

Replace the current `autoresearch-brainstorming` description paragraph with one that includes the two missing controller ideas:

```md
Inspects the repo, determines V1 compatibility (`v1-direct-fit`, `v1-bootstrap-fit`, or `v2-required`), decomposes multi-target onboarding requests before freezing scope, and produces a frozen spec under `docs/autoresearch/specs/`. For `v1-bootstrap-fit` repos, the spec must define the thin adapter boundary explicitly. Blocked repos (`v2-required`) get a diagnosis spec and a `stage_status: blocked` state — no planning or execution proceeds.
```

- [ ] **Step 2: Run the fast Claude harness suite**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh
```

Expected: PASS.

- [ ] **Step 3: Commit the README sync**

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
git add README.md
git commit -m "docs: sync autoresearch brainstorming README description"
```

## Task 5: Run Full Live Verification

**Files:**
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-integration.sh`
- Verify only: `tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh`
- Verify only: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Run the brainstorming live integration test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-integration.sh
```

Expected: PASS. The controller should still write the spec, advance state, preserve canonical git enums, and avoid premature bootstrap artifacts.

- [ ] **Step 2: Run the spec-reviewer live integration test**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --test test-autoresearch-brainstorming-spec-reviewer.sh
```

Expected: PASS.

- [ ] **Step 3: Run the full autoresearch live suite**

Run:

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

Expected: `Passed: 4`, `Failed: 0`, `STATUS: PASSED`.

- [ ] **Step 4: Commit the aligned brainstorming refinement**

```bash
cd /Users/chendongyao/Desktop/计算机顶会skill创建/autoresearch-skills-v1
git add skills/autoresearch-brainstorming/SKILL.md skills/autoresearch-brainstorming/spec-document-reviewer-prompt.md tests/claude-code/test-autoresearch-brainstorming-harness.sh tests/claude-code/test-autoresearch-brainstorming-integration.sh tests/claude-code/test-autoresearch-brainstorming-spec-reviewer.sh README.md
git commit -m "docs: refine autoresearch brainstorming alignment"
```

## Self-Review

- Spec coverage: This plan targets the remaining gaps identified in the review: missing design-principle blocks, weak `v1-bootstrap-fit` adapter boundary wording, ambiguous sidecar status, and README drift. It intentionally does not reintroduce `Visual Companion`, because that was a deliberate non-goal of the autoresearch fork.
- Placeholder scan: No `TBD`, `TODO`, or “similar to previous task” placeholders remain. Every task lists exact files and exact commands.
- Consistency: The plan keeps the same architectural boundary throughout: preserve the current controller skeleton, refine wording and review criteria, and re-verify with the existing harness/live suite.

## Execution Handoff

**Plan complete and saved to `docs/autoresearch/plans/2026-04-12-autoresearch-brainstorming-alignment-plan.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
