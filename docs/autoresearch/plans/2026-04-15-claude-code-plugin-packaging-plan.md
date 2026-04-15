# Claude Code Plugin Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Claude Code plugin packaging so users can install via `claude plugins marketplace add` + `claude plugins install` and get `using-autoresearch` injected at every session start.

**Architecture:** Reuse the hook skeleton and platform JSON format from superpowers-origin (at `/Users/chendongyao/Desktop/计算机顶会skill创建/superpowers-origin/`), replacing only the skill name and session message. The Claude plugin manifest lives in `.claude-plugin/` — root `package.json` is not part of this work. Tests are written first (TDD); each task ends with a passing test and a commit.

**Tech Stack:** Bash, JSON, Claude Code plugin system (`claude plugins validate`, `claude plugins marketplace add`)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `skills/using-autoresearch/SKILL.md` | Create | Standalone meta-skill injected at session start |
| `.claude-plugin/plugin.json` | Create | Claude Code plugin manifest |
| `.claude-plugin/marketplace.json` | Create | Local marketplace descriptor |
| `hooks/hooks.json` | Create | Declares SessionStart hook |
| `hooks/session-start` | Create | Upstream skeleton with skill name + message replaced |
| `hooks/run-hook.cmd` | Create | Verbatim copy of superpowers-origin (no changes) |
| `README.md` | Modify | Claude Code install section + updated matrix + Known Limitations |
| `tests/release-readiness/test-readme-install-surface.sh` | Modify | Replace stale assertions, add plugin structure + skill contract assertions |

---

### Task 1: Write failing tests for plugin structure and skill contract

**Files:**
- Modify: `tests/release-readiness/test-readme-install-surface.sh`

- [ ] **Step 1: Add failing assertions**

Open `tests/release-readiness/test-readme-install-surface.sh` and replace the block from line 42 to the final `echo "[PASS]"` line with:

```bash
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
[ -f "$CHANGELOG" ] || fail "CHANGELOG.md missing"
rg -q "\[0\.1\.0\]" "$CHANGELOG" || fail "CHANGELOG.md missing [0.1.0] section"
rg -q "Known Limitations" "$README" || fail "README missing Known Limitations section"
rg -q "not yet listed on the official Claude Code marketplace" "$README" || fail "README missing Claude Code marketplace limitation"
rg -q "does not currently guarantee proactive skill use at session start" "$README" || fail "README missing OpenCode bootstrap limitation"

[ -f "$REPO_ROOT/.claude-plugin/plugin.json" ] || fail ".claude-plugin/plugin.json missing"
[ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ] || fail ".claude-plugin/marketplace.json missing"
rg -q "karpathy-autoresearch-skills-forLLMresearch" "$REPO_ROOT/.claude-plugin/plugin.json" || fail "plugin.json missing plugin name"
[ -f "$REPO_ROOT/hooks/hooks.json" ] || fail "hooks/hooks.json missing"
rg -q "SessionStart" "$REPO_ROOT/hooks/hooks.json" || fail "hooks.json missing SessionStart"
rg -q "startup" "$REPO_ROOT/hooks/hooks.json" || fail "hooks.json missing matcher"
[ -f "$REPO_ROOT/hooks/session-start" ] || fail "hooks/session-start missing"
[ -x "$REPO_ROOT/hooks/session-start" ] || fail "hooks/session-start not executable"
[ -f "$REPO_ROOT/hooks/run-hook.cmd" ] || fail "hooks/run-hook.cmd missing"
[ -f "$REPO_ROOT/skills/using-autoresearch/SKILL.md" ] || fail "skills/using-autoresearch/SKILL.md missing"
rg -q "using-autoresearch" "$REPO_ROOT/hooks/session-start" || fail "session-start does not reference using-autoresearch"
rg -q "plugins marketplace add" "$README" || fail "README missing claude plugins marketplace add command"

# Bind README install command names to manifest names
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
# Extract names from manifests and verify README references them exactly
plugin_name=$(python3 -c "import json,sys; print(json.load(open('$PLUGIN_JSON'))['name'])" 2>/dev/null || echo "")
marketplace_name=$(python3 -c "import json,sys; print(json.load(open('$MARKETPLACE_JSON'))['name'])" 2>/dev/null || echo "")
[ -n "$plugin_name" ] || fail "could not read plugin name from plugin.json"
[ -n "$marketplace_name" ] || fail "could not read name from marketplace.json"
rg -q "$plugin_name" "$README" || fail "README install command does not match plugin.json name ($plugin_name)"
rg -q "@$marketplace_name" "$README" || fail "README install command does not match marketplace.json name (@$marketplace_name)"

# Skill contract assertions: using-autoresearch must enforce global discipline
rg -q "SUBAGENT-STOP" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing SUBAGENT-STOP guard"
rg -q "EXTREMELY-IMPORTANT" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing EXTREMELY-IMPORTANT block"
rg -q "before any response or action" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing pre-action discipline"
rg -q "autoresearch-brainstorming" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing brainstorming skill reference"
rg -q "autoresearch-loop" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing loop skill reference"
rg -q "Red Flag" "$REPO_ROOT/skills/using-autoresearch/SKILL.md" || fail "using-autoresearch missing Red Flags rationalization table"

echo "[PASS] release-readiness install surface checks"
```

Also remove the two stale assertions that will no longer match after the README update:
- Line 23: `rg -q "not yet ship a Claude Code marketplace package" "$README"` → delete this line
- Line 46: `rg -q "Claude Code marketplace install is not shipped" "$README"` → delete this line

- [ ] **Step 2: Run the test suite and confirm it fails on the new assertions**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1 | tail -20`

Expected: `[FAIL]` on `../release-readiness/test-readme-install-surface.sh` with messages like `.claude-plugin/plugin.json missing`. The other four harness tests should still pass.

---

### Task 2: Create `using-autoresearch` meta-skill

**Files:**
- Create: `skills/using-autoresearch/SKILL.md`

- [ ] **Step 1: Create the skill file**

```bash
mkdir -p skills/using-autoresearch
```

Write `skills/using-autoresearch/SKILL.md`:

```markdown
---
name: using-autoresearch
description: Use when starting any session — establishes the autoresearch pipeline and requires Skill tool invocation before any response or action
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
You have the autoresearch skill suite installed.

**Before any response or action**, check whether one of the four autoresearch skills applies. Even a 1% chance a skill might apply means you MUST invoke it.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Use Skills

In Claude Code, use the `Skill` tool. Invoke a skill by name before acting:

```
Skill("autoresearch-brainstorming")
Skill("autoresearch-planning")
Skill("autoresearch-bootstrap")
Skill("autoresearch-loop")
```

When you invoke a skill, its content is loaded — follow it directly.

## The Four Skills

### autoresearch-brainstorming
**When:** A research repo needs to be diagnosed and scoped before any changes begin.
Inspects the repo, determines V1 compatibility, and produces a frozen spec. Use this first — always.

### autoresearch-planning
**When:** An approved spec exists and needs a concrete implementation plan.
Produces a low-ambiguity plan with exact file paths and verification commands. Only valid after brainstorming.

### autoresearch-bootstrap
**When:** An approved plan is ready to execute.
Runs the plan, generates `profile.yaml`, runs the mandatory baseline, records `baseline_ref`. Only valid after planning.

### autoresearch-loop
**When:** Bootstrap is complete and the experiment loop is ready to run.
Runs autonomous experiment iterations: propose → run → keep/discard/crash. Never pauses unless genuinely blocked.

## Pipeline Order

```
autoresearch-brainstorming
  → autoresearch-planning
    → autoresearch-bootstrap
      → autoresearch-loop
```

You cannot skip stages. Each skill sets `next_allowed_skills` in `autoresearch/state.yaml` to enforce this.

## Red Flags

These thoughts mean STOP — you are rationalizing:

| Thought | Reality |
|---------|---------|
| "I'll just look at the code first" | Skill check comes BEFORE any action. |
| "This is a simple question, no skill needed" | Before any response or action, check for skills. |
| "I already know what to do" | Load the skill anyway — it has the contract. |
| "The user didn't ask for a skill" | Pipeline discipline is not optional. |
| "This doesn't seem autoresearch-related" | If there's a 1% chance it is, invoke the skill. |
```

- [ ] **Step 2: Run the failing test to confirm skill contract assertions now pass**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1 | grep -E "using-autoresearch|SUBAGENT|EXTREMELY|before any|Red Flag|PASS|FAIL"`

Expected: all six skill contract assertions pass. Other new assertions (plugin files, README) still fail.

- [ ] **Step 3: Commit**

```bash
git add skills/using-autoresearch/SKILL.md
git commit -m "feat: add using-autoresearch meta-skill for session-start injection"
```

---

### Task 3: Create Claude plugin manifests

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create `.claude-plugin/plugin.json`**

```bash
mkdir -p .claude-plugin
```

Write `.claude-plugin/plugin.json`:

```json
{
  "name": "karpathy-autoresearch-skills-forLLMresearch",
  "description": "Autonomous ML research skill suite for LLM/RL/NLP experiments. Wraps Karpathy's autoresearch loop in a structured pipeline: brainstorming → planning → bootstrap → loop.",
  "version": "0.1.0",
  "author": {
    "name": "wintersdragon-c"
  },
  "homepage": "https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch",
  "repository": "https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch",
  "license": "MIT",
  "keywords": [
    "autoresearch",
    "llm",
    "rl",
    "nlp",
    "skills",
    "research"
  ]
}
```

- [ ] **Step 2: Create `.claude-plugin/marketplace.json`**

Write `.claude-plugin/marketplace.json`:

```json
{
  "name": "autoresearch-skills-marketplace",
  "description": "Local marketplace for karpathy-autoresearch-skills-forLLMresearch",
  "owner": {
    "name": "wintersdragon-c"
  },
  "plugins": [
    {
      "name": "karpathy-autoresearch-skills-forLLMresearch",
      "description": "Autonomous ML research skill suite for LLM/RL/NLP experiments.",
      "version": "0.1.0",
      "source": "./",
      "author": {
        "name": "wintersdragon-c"
      }
    }
  ]
}
```

- [ ] **Step 3: Validate both manifests**

Run: `claude plugins validate .claude-plugin/plugin.json 2>&1`
Expected: no errors.

Run: `claude plugins validate .claude-plugin/marketplace.json 2>&1`
Expected: no errors.

If either fails, fix the JSON before proceeding.

- [ ] **Step 4: Run the test suite to confirm plugin.json assertions now pass**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1 | grep -E "claude-plugin|PASS|FAIL"`

Expected: `.claude-plugin/plugin.json missing`, `.claude-plugin/marketplace.json missing`, and `plugin.json missing plugin name` assertions no longer fire.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat: add .claude-plugin manifests for Claude Code plugin install"
```

---

### Task 4: Create hooks

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/session-start`
- Create: `hooks/run-hook.cmd`

`hooks/session-start` is based directly on the superpowers-origin upstream skeleton at `/Users/chendongyao/Desktop/计算机顶会skill创建/superpowers-origin/hooks/session-start`. The only changes from upstream are:
1. Comment line 3: `superpowers plugin` → `karpathy-autoresearch-skills plugin`
2. Remove the legacy `~/.config/superpowers/skills` warning block (lines 10–15 of upstream) — not applicable
3. Variable name: `using_superpowers_content` → `skill_content`, `using_superpowers_escaped` → `skill_escaped`
4. Skill path: `skills/using-superpowers/SKILL.md` → `skills/using-autoresearch/SKILL.md`
5. Session context message: `You have superpowers` → `You have the autoresearch skill suite installed`, skill name updated

All other logic — `escape_for_json`, platform detection, `printf` instead of heredoc, exit 0 — is verbatim from upstream.

- [ ] **Step 1: Create `hooks/hooks.json`**

```bash
mkdir -p hooks
```

Write `hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "async": false
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create `hooks/session-start`**

Write `hooks/session-start` (no `.sh` extension — required so Claude Code's Windows auto-detection does not prepend `bash` to the command path):

```bash
#!/usr/bin/env bash
# SessionStart hook for karpathy-autoresearch-skills plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-autoresearch meta-skill content
skill_content=$(cat "${PLUGIN_ROOT}/skills/using-autoresearch/SKILL.md" 2>&1 || echo "Error reading using-autoresearch skill")

# Escape string for JSON embedding using bash parameter substitution.
# Each ${s//old/new} is a single C-level pass - orders of magnitude
# faster than the character-by-character loop this replaces.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

skill_escaped=$(escape_for_json "$skill_content")
session_context="<EXTREMELY_IMPORTANT>\nYou have the autoresearch skill suite installed.\n\n**Below is the full content of your 'using-autoresearch' skill - your introduction to the autoresearch pipeline. For all other skills, use the 'Skill' tool:**\n\n${skill_escaped}\n</EXTREMELY_IMPORTANT>"

# Output context injection as JSON.
# Cursor hooks expect additional_context (snake_case).
# Claude Code hooks expect hookSpecificOutput.additionalContext (nested).
# Copilot CLI (v1.0.11+) and others expect additionalContext (top-level, SDK standard).
# Claude Code reads BOTH additional_context and hookSpecificOutput without
# deduplication, so we must emit only the field the current platform consumes.
#
# Uses printf instead of heredoc to work around bash 5.3+ heredoc hang.
# See: https://github.com/obra/superpowers/issues/571
if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  # Cursor sets CURSOR_PLUGIN_ROOT (may also set CLAUDE_PLUGIN_ROOT)
  printf '{\n  "additional_context": "%s"\n}\n' "$session_context"
elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -z "${COPILOT_CLI:-}" ]; then
  # Claude Code sets CLAUDE_PLUGIN_ROOT without COPILOT_CLI
  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$session_context"
else
  # Copilot CLI (sets COPILOT_CLI=1) or unknown platform — SDK standard format
  printf '{\n  "additionalContext": "%s"\n}\n' "$session_context"
fi

exit 0
```

Make it executable:

```bash
chmod +x hooks/session-start
```

- [ ] **Step 3: Create `hooks/run-hook.cmd`**

Write `hooks/run-hook.cmd` — verbatim copy of superpowers-origin, no changes:

```
: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for hook scripts.
REM On Windows: cmd.exe runs the batch portion, which finds and calls bash.
REM On Unix: the shell interprets this as a script (: is a no-op in bash).
REM
REM Hook scripts use extensionless filenames (e.g. "session-start" not
REM "session-start.sh") so Claude Code's Windows auto-detection -- which
REM prepends "bash" to any command containing .sh -- doesn't interfere.
REM
REM Usage: run-hook.cmd <script-name> [args...]

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

REM Try Git for Windows bash in standard locations
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM Try bash on PATH (e.g. user-installed Git Bash, MSYS2, Cygwin)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM No bash found - exit silently rather than error
REM (plugin still works, just without SessionStart context injection)
exit /b 0
CMDBLOCK

# Unix: run the named script directly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

- [ ] **Step 4: Smoke-test the session-start script locally**

Run: `CLAUDE_PLUGIN_ROOT=$(pwd) bash hooks/session-start 2>&1`

Expected: output is valid JSON containing all three of these fields:
- `hookSpecificOutput` — top-level key
- `hookEventName` — nested under `hookSpecificOutput`, value `"SessionStart"`
- `additionalContext` — nested under `hookSpecificOutput`, containing the injected skill text

Verify with:
```bash
CLAUDE_PLUGIN_ROOT=$(pwd) bash hooks/session-start 2>&1 | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'hookSpecificOutput' in d, 'missing hookSpecificOutput'
h = d['hookSpecificOutput']
assert h.get('hookEventName') == 'SessionStart', 'missing or wrong hookEventName'
assert 'additionalContext' in h, 'missing additionalContext'
assert 'using-autoresearch' in h['additionalContext'], 'additionalContext does not contain using-autoresearch'
print('smoke test PASSED')
"
```

Expected: `smoke test PASSED`. If it prints an assertion error, fix `hooks/session-start` before proceeding.

- [ ] **Step 5: Run the test suite to confirm hooks assertions now pass**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1 | grep -E "hooks|session-start|run-hook|PASS|FAIL"`

Expected: all hooks-related assertions pass. Only README assertions remain failing.

- [ ] **Step 6: Commit**

```bash
git add hooks/hooks.json hooks/session-start hooks/run-hook.cmd
git commit -m "feat: add SessionStart hook skeleton for Claude Code plugin"
```

---

### Task 5: Update README and Known Limitations

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the Platform Support Matrix**

Find the table under `### Platform Support Matrix` and replace the Claude Code row:

Old:
```
| Claude Code marketplace/plugin install | Not supported yet | No marketplace package shipped in this repository |
```

New:
```
| Claude Code | Supported via git install | `claude plugins marketplace add` + `claude plugins install` |
```

- [ ] **Step 2: Replace the `### Claude Code` install section**

Find the existing `### Claude Code` section (currently says "does not yet ship...") and replace it entirely with:

````markdown
### Claude Code

```bash
claude plugins marketplace add https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch
claude plugins install karpathy-autoresearch-skills-forLLMresearch@autoresearch-skills-marketplace
```

After install, restart Claude Code. The `using-autoresearch` skill will be injected at every session start, orienting the agent to the autoresearch pipeline.
````

- [ ] **Step 3: Update Known Limitations**

Find the line:
```
- **Claude Code marketplace install is not shipped.** ...
```

Replace with:
```
- **Not yet listed on the official Claude Code marketplace.** Install via the two-step git install above. The plugin works fully via local marketplace registration.
```

- [ ] **Step 4: Run the full test suite — expect STATUS: PASSED**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1`

Expected:
```
STATUS: PASSED
Passed:  5
Failed:  0
Skipped: 0
```

If any assertion fails, read the failure message, fix the README text to match the exact expected string, and re-run.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add Claude Code plugin install instructions"
```

---

### Task 6: Final verification

- [ ] **Step 1: Run full test suite**

Run: `bash tests/claude-code/run-skill-tests.sh 2>&1`

Expected: `STATUS: PASSED, Passed: 5, Failed: 0, Skipped: 0`

- [ ] **Step 2: Run static contract suite**

Run: `bash tests/autoresearch-skills/run-tests.sh 2>&1`

Expected: all `[PASS]` lines, no `[FAIL]`.

- [ ] **Step 3: Validate both Claude plugin manifests**

Run: `claude plugins validate .claude-plugin/plugin.json 2>&1`
Expected: no errors.

Run: `claude plugins validate .claude-plugin/marketplace.json 2>&1`
Expected: no errors.

- [ ] **Step 4: Confirm root package.json is absent**

Run: `ls package.json 2>&1`

Expected: `No such file or directory` — Claude packaging does not depend on it.

- [ ] **Step 5: Report results to the user**

All verification steps complete. If the user wants to publish, they should run `git push` manually.
