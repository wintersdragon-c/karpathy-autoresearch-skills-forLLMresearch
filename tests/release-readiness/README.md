# Release Readiness Tests

Static checks that verify the public install surface is honest and complete before a release is announced.

## What These Tests Check

- `README.md` contains a Platform Support Matrix and honest statements about each supported platform
- `docs/README.codex.md` contains clone instructions and a publish-time URL placeholder policy note
- `docs/README.opencode.md` contains `skills.paths` instructions and the bootstrap limitation disclaimer
- `.github/workflows/skills-fast-checks.yml` exists and references the correct CI scripts
- The CI workflow does **not** claim prompt-registration scripts (`tests/skill-triggering/`, `tests/explicit-skill-requests/`) as CI gates
- `CHANGELOG.md` exists with a `[0.1.0]` section
- `README.md` contains a `## Known Limitations` section with the Claude Code marketplace and OpenCode bootstrap caveats

## Running

These tests are included in the fast harness suite and run automatically via `run-skill-tests.sh`:

```bash
bash tests/claude-code/run-skill-tests.sh
```

To run this suite alone (requires `rg` on PATH):

```bash
bash tests/release-readiness/test-readme-install-surface.sh
```

## Adding New Checks

Add assertions to `test-readme-install-surface.sh` using the `fail` helper:

```bash
rg -q "expected string" "$FILE" || fail "human-readable failure message"
```
