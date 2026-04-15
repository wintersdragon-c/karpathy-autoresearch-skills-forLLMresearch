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
rg -q "Claude Code marketplace install is not shipped" "$README" || fail "README missing Claude Code marketplace limitation"
rg -q "does not currently guarantee proactive skill use at session start" "$README" || fail "README missing OpenCode bootstrap limitation"

echo "[PASS] release-readiness install surface checks"
