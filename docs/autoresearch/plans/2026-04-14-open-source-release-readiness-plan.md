# Autoresearch Open-Source Release Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `autoresearch-skills-v1` from "developer-usable local skill repo" to "publicly open-sourceable repo with documented install paths, honest CI verification, and explicit release posture."

**Architecture:** Keep the four-skill workflow unchanged. This plan only closes packaging, installation, CI, and release-surface gaps so the repository can be published honestly. Claude Code marketplace packaging is explicitly out of scope unless the repository also adds the required plugin/marketplace artifacts; the plan instead makes the support matrix explicit and verifiable. CI covers only real static/fast checks already present in this repo; prompt-registration scripts are documented as manual checks, not live trigger verification.

**Tech Stack:** Markdown, Bash, GitHub Actions YAML

---

## File Map

| File | Change |
|---|---|
| `README.md` | Rewrite installation/support matrix, publish honest platform support, add release-readiness verification section |
| `docs/README.codex.md` | Narrowly update verification guidance and URL-placeholder policy |
| `docs/README.opencode.md` | Tighten OpenCode install/update/uninstall instructions and document bootstrap limitation |
| `.github/workflows/skills-fast-checks.yml` | Add CI for static runner, trigger suite, explicit-request suite, fast harness suite |
| `CHANGELOG.md` | Add initial release changelog with `0.1.0` scope and known limitations |
| `tests/release-readiness/test-readme-install-surface.sh` | Add a fast check that docs and support-matrix claims stay aligned with actual files |
| `tests/release-readiness/README.md` | Document what the release-readiness checks verify |
| `tests/claude-code/run-skill-tests.sh` | Register release-readiness test in the default fast suite |

---

### Task 1: Publish an honest installation/support matrix

**Files:**
- Modify: `README.md`
- Modify: `docs/README.codex.md`
- Modify: `docs/README.opencode.md`
- Test: `tests/release-readiness/test-readme-install-surface.sh`

- [ ] **Step 1: Write the failing release-readiness test**

Create `tests/release-readiness/test-readme-install-surface.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
README="$REPO_ROOT/README.md"
CODEX_DOC="$REPO_ROOT/docs/README.codex.md"
OPENCODE_DOC="$REPO_ROOT/docs/README.opencode.md"

fail() {
  echo "[FAIL] $1"
  exit 1
}

[ -f "$README" ] || fail "README.md missing"
[ -f "$CODEX_DOC" ] || fail "docs/README.codex.md missing"
[ -f "$OPENCODE_DOC" ] || fail "docs/README.opencode.md missing"

rg -q "Platform Support Matrix" "$README" || fail "README missing platform support matrix"
rg -q "Claude Code" "$README" || fail "README missing Claude Code support statement"
rg -q "Codex" "$README" || fail "README missing Codex support statement"
rg -q "OpenCode" "$README" || fail "README missing OpenCode support statement"
rg -q "not yet ship a Claude Code marketplace package" "$README" || fail "README missing honest Claude limitation"
rg -q "\\.codex/INSTALL.md" "$README" || fail "README missing Codex install path"
rg -q "\\.opencode/INSTALL.md" "$README" || fail "README missing OpenCode install path"
rg -q "git clone" "$CODEX_DOC" || fail "Codex doc missing clone instructions"
rg -q "publish-time checklist item" "$CODEX_DOC" || fail "Codex doc missing URL placeholder policy"
rg -q "skills.paths" "$OPENCODE_DOC" || fail "OpenCode doc missing skills.paths instructions"
rg -q "does not inject a bootstrap system prompt" "$OPENCODE_DOC" || fail "OpenCode doc missing bootstrap limitation"

echo "[PASS] release-readiness install surface checks"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: FAIL because the current README does not yet contain a formal support matrix, an explicit "no Claude marketplace package" statement, or the OpenCode/Codex limitation language.

- [ ] **Step 3: Rewrite the root README installation section**

In `README.md`, replace the current `## Installation` section with:

```markdown
## Installation

### Platform Support Matrix

| Platform | Status | Install Path |
|---|---|---|
| Claude Code marketplace/plugin install | Not supported yet | No marketplace package or Claude plugin manifest is shipped in this repository |
| Codex | Supported now | Local install via `.codex/INSTALL.md` |
| OpenCode | Supported now | Local install via `.opencode/INSTALL.md` |

### Codex

Tell Codex:

```text
Open and follow the instructions in /path/to/autoresearch-skills-v1/.codex/INSTALL.md
```

Detailed guide: [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```text
Open and follow the instructions in /path/to/autoresearch-skills-v1/.opencode/INSTALL.md
```

Detailed guide: [docs/README.opencode.md](docs/README.opencode.md)

### Claude Code

This repository does not yet ship a Claude Code marketplace package, plugin manifest, or marketplace entry. Claude-side development tests exist, but they are not a public installation path.

If Claude Code distribution is required, add the missing plugin/marketplace packaging in a follow-up release rather than implying support prematurely.

### Verify Installation

Start a new session and explicitly ask for one of the skills, for example:

- `Use the autoresearch-brainstorming skill to diagnose this repo.`
- `Use the autoresearch-bootstrap skill to set up the experiment profile.`

Then run:

```bash
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```

`tests/skill-triggering/run-all.sh` and `tests/explicit-skill-requests/run-all.sh` are prompt-registration checks only. They do not invoke Claude and should not be interpreted as live trigger verification.
```

- [ ] **Step 4: Make targeted Codex and OpenCode doc edits**

In `docs/README.codex.md`, keep the existing install/update/uninstall structure and make two precise edits:

1. Insert the placeholder note immediately after the clone command block in `## Manual Installation`
2. Insert the new `## Verification` section immediately before the existing `## Updating` section

Add this note immediately after the clone command block:

```markdown
If this repository has not been published yet, `<your-repo-url>` is a publish-time checklist item and must be replaced with the final public clone URL before the release is announced.
```

Then insert this new section immediately before `## Updating`:

```markdown
## Verification

In a fresh session, ask:

```text
Use the autoresearch-brainstorming skill to diagnose this repo.
```

Then from the repo root run:

```bash
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```
```

In `docs/README.opencode.md`, keep the existing installation block and append this limitation + verification text:

```markdown
## Verification

Use the skill tool to confirm discovery:

```text
use skill tool to list skills
use skill tool to load autoresearch-brainstorming
```

Then from the repo root run:

```bash
bash tests/autoresearch-skills/run-tests.sh
```

## Limitation

This install path registers the skills directory, but it does not inject a bootstrap system prompt comparable to `using-superpowers`. OpenCode users can load and use the skills, but the repository does not currently guarantee proactive skill use at session start.
```

- [ ] **Step 5: Run release-readiness test to verify it passes**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: `[PASS] release-readiness install surface checks`

- [ ] **Step 6: Commit**

```bash
git add README.md docs/README.codex.md docs/README.opencode.md tests/release-readiness/test-readme-install-surface.sh
git commit -m "docs: publish honest install support matrix"
```

---

### Task 2: Add CI for honest fast release gates

**Files:**
- Create: `.github/workflows/skills-fast-checks.yml`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Test: `tests/release-readiness/test-readme-install-surface.sh`

- [ ] **Step 1: Write the failing workflow assertion**

Append to `tests/release-readiness/test-readme-install-surface.sh`:

```bash
[ -f "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" ] || fail "skills-fast-checks.yml missing"
rg -q "tests/autoresearch-skills/run-tests.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" || fail "workflow missing static runner"
rg -q "tests/claude-code/run-skill-tests.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" || fail "workflow missing fast harness suite"
if rg -q "tests/skill-triggering/run-all.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml"; then
  fail "workflow must not claim prompt-registration scripts as CI gates"
fi
if rg -q "tests/explicit-skill-requests/run-all.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml"; then
  fail "workflow must not claim prompt-registration scripts as CI gates"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: FAIL because `.github/workflows/skills-fast-checks.yml` does not exist yet.

- [ ] **Step 3: Create the GitHub Actions workflow**

Create `.github/workflows/skills-fast-checks.yml` with:

```yaml
name: skills-fast-checks

on:
  push:
  pull_request:

jobs:
  fast-checks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install ripgrep
        run: sudo apt-get update && sudo apt-get install -y ripgrep

      - name: Static contract runner
        run: bash tests/autoresearch-skills/run-tests.sh

      - name: Fast Claude harness suite
        run: bash tests/claude-code/run-skill-tests.sh

```

- [ ] **Step 4: Register the release-readiness test in the fast suite**

In `tests/claude-code/run-skill-tests.sh`, extend the fast-test array:

```bash
fast_tests=(
    "test-autoresearch-brainstorming-harness.sh"
    "test-autoresearch-loop-harness.sh"
    "test-autoresearch-planning-harness.sh"
    "test-autoresearch-bootstrap-harness.sh"
    "../release-readiness/test-readme-install-surface.sh"
)
```

And add one help line under `Fast Tests (run by default):`

```text
  ../release-readiness/test-readme-install-surface.sh   Release-readiness docs/install checks
```

- [ ] **Step 5: Run the test suites to verify they pass**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: `[PASS] release-readiness install surface checks`

Run: `bash tests/claude-code/run-skill-tests.sh`
Expected:
```text
STATUS: PASSED
Passed:  5
Failed:  0
Skipped: 0
```

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/skills-fast-checks.yml tests/claude-code/run-skill-tests.sh tests/release-readiness/test-readme-install-surface.sh
git commit -m "ci: add fast release readiness workflow"
```

---

### Task 3: Add release metadata and public limitations

**Files:**
- Create: `CHANGELOG.md`
- Modify: `README.md`
- Create: `tests/release-readiness/README.md`
- Test: `tests/release-readiness/test-readme-install-surface.sh`

- [ ] **Step 1: Write the failing metadata assertions**

Append to `tests/release-readiness/test-readme-install-surface.sh`:

```bash
[ -f "$REPO_ROOT/CHANGELOG.md" ] || fail "CHANGELOG.md missing"
rg -q "## \\[0.1.0\\]" "$REPO_ROOT/CHANGELOG.md" || fail "CHANGELOG missing 0.1.0 section"
rg -q "Known Limitations" "$REPO_ROOT/README.md" || fail "README missing Known Limitations section"
rg -q "Claude Code marketplace install is not shipped" "$REPO_ROOT/README.md" || fail "README missing Claude limitation"
rg -q "OpenCode users can load and use the skills, but the repository does not currently guarantee proactive skill use at session start because this release does not inject a bootstrap system prompt" "$REPO_ROOT/README.md" || fail "README missing OpenCode bootstrap limitation"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: FAIL because the changelog and limitations section do not exist yet.

- [ ] **Step 3: Add changelog and release-readiness notes**

Create `CHANGELOG.md` with:

```markdown
# Changelog

## [0.1.0] - 2026-04-14

### Added
- Four-skill autoresearch workflow: brainstorming, planning, bootstrap, loop
- Static contract runner and Claude fast harness suite
- Autoresearch live integration suite for brainstorming, planning reviewer, bootstrap, and loop
- Codex and OpenCode local installation documentation

### Known Limitations
- Claude Code marketplace install is not shipped in this release
- No public plugin manifest or marketplace metadata is included yet
- Live integration tests depend on Claude CLI and are not run in CI
- OpenCode support is local `skills.paths` registration only; this release does not inject a bootstrap system prompt and does not guarantee proactive skill use at session start
```

Create `tests/release-readiness/README.md` with:

```markdown
# Release Readiness Tests

These tests verify the public install surface, support-matrix honesty, and release metadata needed before publishing the repository for external users.

Current coverage:
- README support matrix matches actual install artifacts
- Codex/OpenCode docs exist and contain real install instructions
- Fast CI workflow exists and runs the public fast suites
- Changelog and release limitations are present
```

Append to `README.md` after the `## Updating` section:

```markdown
## Known Limitations

- Claude Code marketplace install is not shipped in this release.
- The supported install paths today are local Codex and local OpenCode setup.
- Live Claude integration coverage exists, but it depends on local Claude CLI and is not part of CI.
- OpenCode users can load and use the skills, but the repository does not currently guarantee proactive skill use at session start because this release does not inject a bootstrap system prompt.
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected: `[PASS] release-readiness install surface checks`

Run: `bash tests/autoresearch-skills/run-tests.sh`
Expected:
```text
[PASS] autoresearch static runner skeleton
[PASS] autoresearch-brainstorming static checks
[PASS] autoresearch-planning static checks
[PASS] autoresearch-bootstrap static checks
[PASS] autoresearch-loop static checks
```

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md README.md tests/release-readiness/README.md tests/release-readiness/test-readme-install-surface.sh
git commit -m "docs: add release metadata and public limitations"
```

---

### Task 4: Final verification

**Files:** Read-only verification pass

- [ ] **Step 1: Run static contract runner**

Run: `bash tests/autoresearch-skills/run-tests.sh`
Expected:
```text
[PASS] autoresearch static runner skeleton
[PASS] autoresearch-brainstorming static checks
[PASS] autoresearch-planning static checks
[PASS] autoresearch-bootstrap static checks
[PASS] autoresearch-loop static checks
```

- [ ] **Step 2: Run prompt-registration coverage manually**

Run: `bash tests/skill-triggering/run-all.sh`
Expected:
```text
[PASS] autoresearch skill-triggering prompts registered
```

Interpretation: this is a prompt-registration check only. It does not invoke Claude and is not equivalent to live trigger verification.

- [ ] **Step 3: Run explicit-request prompt-registration manually**

Run: `bash tests/explicit-skill-requests/run-all.sh`
Expected:
```text
[PASS] autoresearch explicit-skill-request prompts registered
```

Interpretation: this is a prompt-registration check only. It does not invoke Claude and is not equivalent to live explicit-skill invocation testing.

- [ ] **Step 4: Run fast suite**

Run: `bash tests/claude-code/run-skill-tests.sh`
Expected:
```text
STATUS: PASSED
Passed:  5
Failed:  0
Skipped: 0
```

- [ ] **Step 5: Run release-readiness check directly**

Run: `bash tests/release-readiness/test-readme-install-surface.sh`
Expected:
```text
[PASS] release-readiness install surface checks
```

- [ ] **Step 6: Spot-check public support claims**

Run: `rg -n "Platform Support Matrix|Claude Code marketplace install is not shipped|publish-time checklist item|does not inject a bootstrap system prompt" README.md CHANGELOG.md docs/README.codex.md docs/README.opencode.md`
Expected: matches found in the docs, with no claim that Claude marketplace/plugin install already exists and with OpenCode/Codex limitations stated explicitly.

---

## Self-Review

**Spec coverage:**
- Honest support matrix and no false Claude-install claims → Task 1 ✓
- Codex/OpenCode public install docs with verification flow and explicit limitation language → Task 1 ✓
- Fast CI workflow for real static/fast gates only (not fake trigger coverage) → Task 2 ✓
- Release metadata and known limitations → Task 3 ✓
- Keep skill semantics unchanged; only release/install surface changes → Tasks 1–3 ✓

**Placeholder scan:** The only intentional placeholder is the public repo coordinate such as `<your-repo-url>`. This is explicitly treated as a publish-time checklist item, not a CI-passing release claim. No task delegates unspecified implementation details.

**Type consistency:** Fast-suite expected count is `5` because the current default suite has four existing harnesses plus one new release-readiness test. The workflow intentionally excludes `tests/skill-triggering/run-all.sh` and `tests/explicit-skill-requests/run-all.sh` because they are prompt-registration checks, not live trigger tests. The plan does not claim Claude marketplace/plugin artifacts exist; it explicitly treats them as unsupported in this release.
