# Claude Code Plugin Packaging Design

**Date:** 2026-04-15
**Status:** Approved (revised)

## Goal

Add Claude Code plugin packaging to `autoresearch-skills-v1` so users can install via `claude plugins marketplace add` + `claude plugins install` and get a bootstrap system prompt injected at every session start — making Claude Code a first-class install path alongside Codex and OpenCode.

## Architecture

Reuse the hook skeleton and platform JSON format from superpowers-origin, but inject `using-autoresearch` instead of `using-superpowers`. The Claude plugin manifest lives in `.claude-plugin/` (not root `package.json`, which belongs to OpenCode's JS plugin system). Root `package.json` is retained only as a future OpenCode alignment placeholder and is not part of the Claude minimum package.

### New files

```
skills/using-autoresearch/SKILL.md   ← standalone meta-skill (session-start injection target)
.claude-plugin/plugin.json           ← Claude Code plugin manifest
.claude-plugin/marketplace.json      ← local marketplace descriptor (enables marketplace add)
hooks/hooks.json                     ← declares SessionStart hook
hooks/session-start                  ← bash script, injects using-autoresearch at session start
hooks/run-hook.cmd                   ← cross-platform polyglot wrapper (Windows + Unix)
```

### Modified files

```
README.md                                              ← Claude Code install section + updated matrix
tests/release-readiness/test-readme-install-surface.sh ← updated assertions
```

### Not part of the Claude minimum package

`package.json` (root) — this is OpenCode's JS plugin manifest, not Claude's. It is retained in the repo for future OpenCode alignment but is not required for Claude Code plugin installation.

---

## Component Designs

### `skills/using-autoresearch/SKILL.md`

Standalone meta-skill injected at every Claude Code session start. Does NOT reference superpowers or assume superpowers is installed.

**Responsibilities:**
- Tell the agent this plugin provides four autoresearch skills
- Explain the pipeline order: brainstorming → planning → bootstrap → loop
- Tell the agent to use the `Skill` tool to load any skill before acting
- Explain when each skill applies (triggering conditions)
- Enforce: invoke the relevant skill BEFORE any response or action

**Frontmatter:**
```yaml
---
name: using-autoresearch
description: Use when starting any session — orients the agent to the autoresearch pipeline and requires Skill tool invocation before any research-related action
---
```

**Content structure:**
1. `<SUBAGENT-STOP>` guard (skip if dispatched as subagent)
2. `<EXTREMELY-IMPORTANT>` block: invoke skills before acting, no exceptions
3. How to use the Skill tool in Claude Code
4. The four skills and when each applies
5. Pipeline order enforcement
6. Red flags / rationalization table

**Key behavioral contract:** If the user mentions a training repo, ML experiment, research idea, or any autoresearch-related task — invoke the relevant skill FIRST. Do not start writing code or modifying files before loading the skill.

---

### `.claude-plugin/plugin.json`

Claude Code plugin manifest. Mirrors superpowers-origin's `.claude-plugin/plugin.json` structure:

```json
{
  "name": "karpathy-autoresearch-skills-forLLMresearch",
  "description": "Autonomous ML research skill suite for LLM/RL/NLP experiments. Wraps Karpathy's autoresearch loop in a structured Superpowers-compatible pipeline.",
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

---

### `.claude-plugin/marketplace.json`

Local marketplace descriptor. Enables `claude plugins marketplace add <github-url>` to register this repo as a marketplace, after which `claude plugins install karpathy-autoresearch-skills-forLLMresearch@<marketplace-name>` works.

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

---

### `hooks/hooks.json`

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

Matcher `startup|clear|compact` is the current Claude Code convention (verified from superpowers-origin 5.0.7).

---

### `hooks/session-start`

Bash script. Reads `skills/using-autoresearch/SKILL.md`, escapes it for JSON embedding, and outputs the correct `additionalContext` format for the detected platform:

- Claude Code (`CLAUDE_PLUGIN_ROOT` set, `COPILOT_CLI` not set) → `hookSpecificOutput.additionalContext`
- Cursor (`CURSOR_PLUGIN_ROOT` set) → `additional_context`
- Copilot CLI / unknown → `additionalContext`

Exits 0 on success. If the skill file cannot be read, injects an error message rather than silently failing.

---

### `hooks/run-hook.cmd`

Verbatim copy of superpowers-origin's polyglot wrapper. On Windows, `cmd.exe` runs the batch block which finds bash (Git for Windows, MSYS2, Cygwin). On Unix, the shell skips the batch block and runs the named script directly.

---

### README updates

**Platform Support Matrix** — Claude Code row updated:

| Platform | Status | Install Path |
|---|---|---|
| Claude Code | Supported via git install | `claude plugins marketplace add` + `claude plugins install` |
| Codex | Supported | One-liner below |
| OpenCode | Supported | One-liner below |

**New `### Claude Code` install section:**

```bash
claude plugins marketplace add https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch
claude plugins install karpathy-autoresearch-skills-forLLMresearch@autoresearch-skills-marketplace
```

After install, restart Claude Code. The `using-autoresearch` skill will be injected at every session start.

**Known Limitations update:**

Remove: "Claude Code marketplace install is not shipped."
Replace with: "Not yet listed on the official Claude Code marketplace — install via the two-step git install above."

---

### Release-readiness test updates

Remove assertions that will break after README changes:
- `rg -q "not yet ship a Claude Code marketplace package"` (README text is changing)
- `rg -q "Claude Code marketplace install is not shipped"` (README/CHANGELOG text is changing)

Add assertions:
- `[ -f "$REPO_ROOT/.claude-plugin/plugin.json" ]` — Claude plugin manifest exists
- `[ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]` — marketplace descriptor exists
- `rg -q "karpathy-autoresearch-skills-forLLMresearch" "$REPO_ROOT/.claude-plugin/plugin.json"` — name matches
- `[ -f "$REPO_ROOT/hooks/hooks.json" ]` — hooks manifest exists
- `rg -q "SessionStart" "$REPO_ROOT/hooks/hooks.json"` — hook is declared
- `rg -q "startup" "$REPO_ROOT/hooks/hooks.json"` — matcher is present
- `[ -f "$REPO_ROOT/hooks/session-start" ]` — session-start script exists
- `[ -x "$REPO_ROOT/hooks/session-start" ]` — session-start is executable
- `[ -f "$REPO_ROOT/hooks/run-hook.cmd" ]` — cross-platform wrapper exists
- `[ -f "$REPO_ROOT/skills/using-autoresearch/SKILL.md" ]` — meta-skill exists
- `rg -q "using-autoresearch" "$REPO_ROOT/hooks/session-start"` — session-start references the right skill
- `rg -q "plugins marketplace add" "$README"` — README has correct install command
- `rg -q "not yet listed on the official Claude Code marketplace" "$README"` — honest limitation

---

## Out of Scope

- Gemini CLI support (`GEMINI.md`, `gemini-extension.json`) — separate future task
- `agents/` directory (code-reviewer subagent) — separate future task
- Official Claude Code marketplace submission — requires Anthropic review process
- OpenCode JS plugin (`package.json` `main` field) — separate future task

---

## Success Criteria

1. `bash tests/claude-code/run-skill-tests.sh` → STATUS: PASSED, 5/5
2. `bash tests/release-readiness/test-readme-install-surface.sh` → [PASS]
3. `claude plugins validate .claude-plugin/plugin.json` → no errors
4. `hooks/session-start` injects `using-autoresearch` content (verifiable by reading the script)
5. README Claude Code section has the exact two-step `marketplace add` + `plugins install` commands
6. Root `package.json` is absent; Claude packaging does not depend on it.
