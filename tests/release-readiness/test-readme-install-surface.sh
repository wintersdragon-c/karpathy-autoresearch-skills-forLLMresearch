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
rg -q "\\.codex/INSTALL.md" "$README" || fail "README missing Codex install path"
rg -q "\\.opencode/INSTALL.md" "$README" || fail "README missing OpenCode install path"
rg -q "git clone" "$CODEX_DOC" || fail "Codex doc missing clone instructions"
rg -q "wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch" "$CODEX_DOC" || fail "Codex doc missing real GitHub clone URL"
rg -q "raw.githubusercontent.com" "$README" || fail "README missing raw GitHub URL for Codex/OpenCode install"
rg -q "skills.paths" "$OPENCODE_DOC" || fail "OpenCode doc missing skills.paths instructions"
rg -q "does not inject a bootstrap system prompt" "$OPENCODE_DOC" || fail "OpenCode doc missing bootstrap limitation"

[ -f "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" ] || fail "skills-fast-checks.yml missing"
rg -q "tests/autoresearch-skills/run-tests.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" || fail "workflow missing static runner"
rg -q "tests/claude-code/run-skill-tests.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml" || fail "workflow missing fast harness suite"
if rg -q "tests/skill-triggering/run-all.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml"; then
  fail "workflow must not claim prompt-registration scripts as CI gates"
fi
if rg -q "tests/explicit-skill-requests/run-all.sh" "$REPO_ROOT/.github/workflows/skills-fast-checks.yml"; then
  fail "workflow must not claim prompt-registration scripts as CI gates"
fi

CHANGELOG="$REPO_ROOT/CHANGELOG.md"
[ -f "$CHANGELOG" ] || fail "CHANGELOG.md missing"
rg -q "\[0\.1\.0\]" "$CHANGELOG" || fail "CHANGELOG.md missing [0.1.0] section"
rg -q "Known Limitations" "$README" || fail "README missing Known Limitations section"
rg -qi "not yet listed on the official Claude Code marketplace" "$README" || fail "README missing Claude Code marketplace limitation"
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
