# Autoresearch Loop Alignment Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `autoresearch-loop/SKILL.md` with the core philosophy of `autoresearch-master/program.md` by adding branch discipline enforcement, crash retry logic, research taste judgment, and the NEVER STOP autonomous operation principle.

**Architecture:** Four surgical additions to SKILL.md — each backed by a failing static assertion written first (TDD). Tests in `run-tests.sh` and `test-autoresearch-loop-harness.sh` are updated in lockstep with each skill change. No existing passing assertions are broken.

**Tech Stack:** Bash, ripgrep (`rg`), Markdown

---

## File Map

| File | Change |
|---|---|
| `skills/autoresearch-loop/SKILL.md` | Add branch gate (entry), crash retry sub-loop, Research Taste section, Autonomous Operation section, update loop step 1 |
| `tests/autoresearch-skills/run-tests.sh` | Add 7 new `require_pattern` assertions for loop (after line 270) |
| `tests/claude-code/test-autoresearch-loop-harness.sh` | Add Tests 13–17 before the final echo |

---

### Task 1: Branch verification in entry gate

**Files:**
- Modify: `tests/autoresearch-skills/run-tests.sh` (after line 270, before `echo "[PASS] autoresearch-loop static checks"`)
- Modify: `tests/claude-code/test-autoresearch-loop-harness.sh` (before final echo)
- Modify: `skills/autoresearch-loop/SKILL.md` (Entry Gate section, lines 12–19)

- [ ] **Step 1: Add failing assertion to run-tests.sh**

In `tests/autoresearch-skills/run-tests.sh`, insert before the `echo "[PASS] autoresearch-loop static checks"` line (currently line 270):

```bash
# Branch verification in entry gate
require_pattern "git branch --show-current" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
```

- [ ] **Step 2: Verify assertion fails**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep -A2 "autoresearch-loop"`
Expected: `[FAIL] Pattern 'git branch --show-current' not found in .../autoresearch-loop/SKILL.md`

- [ ] **Step 3: Update SKILL.md entry gate**

In `skills/autoresearch-loop/SKILL.md`, replace the Entry Gate section:

```markdown
## Entry Gate

All five conditions must be true before the loop starts:

1. `active_profile_path` is set and points to a readable profile artifact
2. `baseline_ref` is set (non-null)
3. `bootstrap_status: completed`
4. `baseline_status: validated`
5. Current git branch matches `git_policy.branch_prefix` — run `git branch --show-current` and verify the branch name starts with the prefix value from the profile

If any condition is false, set `stage_status: blocked` and `blocker_reason` explaining which gate failed. Do not proceed on the wrong branch.
```

- [ ] **Step 4: Verify assertion passes**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep -A2 "autoresearch-loop"`
Expected: `[PASS] autoresearch-loop static checks`

- [ ] **Step 5: Add harness test 13**

In `tests/claude-code/test-autoresearch-loop-harness.sh`, insert before `echo "=== All autoresearch-loop harness tests passed ==="`:

```bash
echo "Test 13: Branch verification in entry gate..."
if rg -q "git branch --show-current" "$SKILL"; then
    echo "  [PASS] Branch verification present"
else
    echo "  [FAIL] Branch verification missing"
    exit 1
fi
echo ""
```

- [ ] **Step 6: Verify harness passes**

Run: `bash tests/claude-code/test-autoresearch-loop-harness.sh`
Expected: `[PASS] Branch verification present` and `=== All autoresearch-loop harness tests passed ===`

- [ ] **Step 7: Commit**

```bash
git add skills/autoresearch-loop/SKILL.md tests/autoresearch-skills/run-tests.sh tests/claude-code/test-autoresearch-loop-harness.sh
git commit -m "feat(loop): enforce branch prefix verification in entry gate"
```

---

### Task 2: Crash retry sub-loop

**Files:**
- Modify: `tests/autoresearch-skills/run-tests.sh` (before `echo "[PASS] autoresearch-loop static checks"`)
- Modify: `tests/claude-code/test-autoresearch-loop-harness.sh` (before final echo)
- Modify: `skills/autoresearch-loop/SKILL.md` (Run Failure Handling section + loop step 7)

- [ ] **Step 1: Add failing assertions to run-tests.sh**

Insert before `echo "[PASS] autoresearch-loop static checks"`:

```bash
# Crash retry sub-loop
require_pattern "attempt_id" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "max_retry_on_crash" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "Easy fix" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
```

- [ ] **Step 2: Verify assertions fail**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep FAIL`
Expected: three `[FAIL]` lines for `attempt_id`, `max_retry_on_crash`, `Easy fix`

- [ ] **Step 3: Replace Run Failure Handling section in SKILL.md**

Replace the existing `## Run Failure Handling` section (lines 39–43) with:

```markdown
## Run Failure Handling

When a run crashes (non-zero exit, timeout, or metric extraction failure):

1. Read the last 50 lines of `runtime.log_path` to diagnose the failure
2. Judge whether the crash is fixable:
   - **Easy fix** (typo, missing import, off-by-one): apply the fix, increment `attempt_id`, re-run under the same `run_id` — up to `experiment.max_retry_on_crash` retries
   - **Fundamentally broken** (OOM on a too-large model, broken idea): do not retry; record final crash and move to the next idea
3. If retries are exhausted without success: record final crash status
4. On final crash: apply `crash_strategy` from profile, append crash row to `autoresearch/results.tsv`, append crash entry to `autoresearch/ledger.jsonl`

Each retry attempt gets its own `attempt_id` in the ledger entry. The `run_id` stays the same across retries for the same idea.
```

- [ ] **Step 4: Verify assertions pass**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep -A2 "autoresearch-loop"`
Expected: `[PASS] autoresearch-loop static checks`

- [ ] **Step 5: Add harness test 14**

In `tests/claude-code/test-autoresearch-loop-harness.sh`, insert before `echo "=== All autoresearch-loop harness tests passed ==="`:

```bash
echo "Test 14: Crash retry sub-loop present..."
if rg -q "attempt_id" "$SKILL" && rg -q "max_retry_on_crash" "$SKILL" && rg -q "Easy fix" "$SKILL"; then
    echo "  [PASS] Crash retry sub-loop present"
else
    echo "  [FAIL] Crash retry sub-loop missing"
    exit 1
fi
echo ""
```

- [ ] **Step 6: Verify harness passes**

Run: `bash tests/claude-code/test-autoresearch-loop-harness.sh`
Expected: `[PASS] Crash retry sub-loop present` and `=== All autoresearch-loop harness tests passed ===`

- [ ] **Step 7: Commit**

```bash
git add skills/autoresearch-loop/SKILL.md tests/autoresearch-skills/run-tests.sh tests/claude-code/test-autoresearch-loop-harness.sh
git commit -m "feat(loop): add crash retry sub-loop with attempt_id and easy-fix judgment"
```

---

### Task 3: Research Taste section

**Files:**
- Modify: `tests/autoresearch-skills/run-tests.sh` (before `echo "[PASS] autoresearch-loop static checks"`)
- Modify: `tests/claude-code/test-autoresearch-loop-harness.sh` (before final echo)
- Modify: `skills/autoresearch-loop/SKILL.md` (add new section after Run Failure Handling)

- [ ] **Step 1: Add failing assertions to run-tests.sh**

Insert before `echo "[PASS] autoresearch-loop static checks"`:

```bash
# Research taste
require_pattern "Simplicity criterion" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "VRAM soft constraint" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
```

- [ ] **Step 2: Verify assertions fail**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep FAIL`
Expected: two `[FAIL]` lines for `Simplicity criterion` and `VRAM soft constraint`

- [ ] **Step 3: Add Research Taste section to SKILL.md**

After the `## Run Failure Handling` section, insert:

```markdown
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
```

- [ ] **Step 4: Verify assertions pass**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep -A2 "autoresearch-loop"`
Expected: `[PASS] autoresearch-loop static checks`

- [ ] **Step 5: Add harness tests 15**

In `tests/claude-code/test-autoresearch-loop-harness.sh`, insert before `echo "=== All autoresearch-loop harness tests passed ==="`:

```bash
echo "Test 15: Research taste (simplicity criterion + VRAM) present..."
if rg -q "Simplicity criterion" "$SKILL" && rg -q "VRAM soft constraint" "$SKILL"; then
    echo "  [PASS] Research taste section present"
else
    echo "  [FAIL] Research taste section missing"
    exit 1
fi
echo ""
```

- [ ] **Step 6: Verify harness passes**

Run: `bash tests/claude-code/test-autoresearch-loop-harness.sh`
Expected: `[PASS] Research taste section present` and `=== All autoresearch-loop harness tests passed ===`

- [ ] **Step 7: Commit**

```bash
git add skills/autoresearch-loop/SKILL.md tests/autoresearch-skills/run-tests.sh tests/claude-code/test-autoresearch-loop-harness.sh
git commit -m "feat(loop): add Research Taste section with simplicity criterion and VRAM guidance"
```

---

### Task 4: Autonomous operation rules

**Files:**
- Modify: `tests/autoresearch-skills/run-tests.sh` (before `echo "[PASS] autoresearch-loop static checks"`)
- Modify: `tests/claude-code/test-autoresearch-loop-harness.sh` (before final echo)
- Modify: `skills/autoresearch-loop/SKILL.md` (update loop step 1; add Autonomous Operation section)

- [ ] **Step 1: Add failing assertions to run-tests.sh**

Insert before `echo "[PASS] autoresearch-loop static checks"`:

```bash
# Autonomous operation
require_pattern "do NOT pause to ask" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
require_pattern "results.tsv must not be committed" "$REPO_ROOT/skills/autoresearch-loop/SKILL.md"
```

- [ ] **Step 2: Verify assertions fail**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep FAIL`
Expected: two `[FAIL]` lines for `do NOT pause to ask` and `results.tsv must not be committed`

- [ ] **Step 3: Update loop step 1 in SKILL.md**

In the `## The Loop Cycle` section, replace step 1:

```markdown
1. Read the profile from `active_profile_path`. Also read the key in-scope files listed in `edit_scope.allowed_paths` and `edit_scope.readonly_paths` to understand the current state of the code before proposing a change.
```

- [ ] **Step 4: Add Autonomous Operation section to SKILL.md**

After the `## Research Taste` section, insert:

```markdown
## Autonomous Operation

Once the loop has started, do NOT pause to ask the user if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The user may be away from their computer and expects the loop to run indefinitely until manually interrupted.

**If you run out of ideas:** Think harder. Re-read the in-scope files for new angles. Try combining previous near-misses. Try more radical architectural or optimizer changes. The loop runs until a stop condition is met or the user interrupts — not until you feel uncertain.

**results.tsv must not be committed to git.** It is an untracked working file. Never `git add autoresearch/results.tsv`.
```

- [ ] **Step 5: Verify assertions pass**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1 | grep -A2 "autoresearch-loop"`
Expected: `[PASS] autoresearch-loop static checks`

- [ ] **Step 6: Add harness tests 16–17**

In `tests/claude-code/test-autoresearch-loop-harness.sh`, insert before `echo "=== All autoresearch-loop harness tests passed ==="`:

```bash
echo "Test 16: NEVER STOP principle present..."
if rg -q "do NOT pause to ask" "$SKILL"; then
    echo "  [PASS] NEVER STOP principle present"
else
    echo "  [FAIL] NEVER STOP principle missing"
    exit 1
fi
echo ""

echo "Test 17: results.tsv untracked rule present..."
if rg -q "results.tsv must not be committed" "$SKILL"; then
    echo "  [PASS] results.tsv untracked rule present"
else
    echo "  [FAIL] results.tsv untracked rule missing"
    exit 1
fi
echo ""
```

- [ ] **Step 7: Verify harness passes**

Run: `bash tests/claude-code/test-autoresearch-loop-harness.sh`
Expected: Tests 16 and 17 both `[PASS]` and `=== All autoresearch-loop harness tests passed ===`

- [ ] **Step 8: Commit**

```bash
git add skills/autoresearch-loop/SKILL.md tests/autoresearch-skills/run-tests.sh tests/claude-code/test-autoresearch-loop-harness.sh
git commit -m "feat(loop): add Autonomous Operation section and results.tsv untracked rule"
```

---

### Task 5: Full verification

**Files:** Read-only verification pass

- [ ] **Step 1: Run static runner**

Run: `bash tests/autoresearch-skills/run-tests.sh`
Expected:
```
[PASS] autoresearch static runner skeleton
[PASS] autoresearch-brainstorming static checks
[PASS] autoresearch-planning static checks
[PASS] autoresearch-bootstrap static checks
[PASS] autoresearch-loop static checks
```

- [ ] **Step 2: Run fast harness suite**

Run: `bash tests/claude-code/run-skill-tests.sh`
Expected:
```
STATUS: PASSED
Passed:  4
Failed:  0
Skipped: 0
```

- [ ] **Step 3: Verify loop harness test count**

Run: `bash tests/claude-code/test-autoresearch-loop-harness.sh | grep -c PASS`
Expected: `17`

- [ ] **Step 4: Spot-check SKILL.md structure**

Run: `grep "^## " skills/autoresearch-loop/SKILL.md`
Expected output (in order):
```
## Overview
## Entry Gate
## The Loop Cycle
## Run Failure Handling
## Research Taste
## Autonomous Operation
## Editable-Surface Hard Gate
## Normal Termination
## State Ownership Contract
## Common Mistakes
## Reference
```

---

## Self-Review

**Spec coverage:**
- Branch verification in entry gate → Task 1 ✓
- Crash retry sub-loop with attempt_id / easy-fix judgment → Task 2 ✓
- Simplicity criterion + VRAM soft constraint → Task 3 ✓
- NEVER STOP principle → Task 4 ✓
- results.tsv untracked → Task 4 ✓
- Read in-scope files at loop start → Task 4 (loop step 1 update) ✓
- Run out of ideas strategy → Task 4 (Autonomous Operation section) ✓
- Test coverage gap (Finding 4: discard/crash integration tests) → out of scope for this plan; requires separate test fixtures and integration test files

**Placeholder scan:** No TBD, TODO, or "similar to Task N" patterns present.

**Type consistency:** All pattern strings used in `require_pattern` assertions match exactly the text added to SKILL.md in the corresponding task.
