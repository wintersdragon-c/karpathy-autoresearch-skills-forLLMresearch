# Changelog

## [0.1.0] - 2026-04-14

Initial public release of autoresearch-skills-v1.

### Added

- `autoresearch-brainstorming` skill — structured research ideation with novelty gate
- `autoresearch-planning` skill — reproduce → extend → ablate plan with guardrails YAML
- `autoresearch-bootstrap` skill — baseline freeze, contract emission, adapter entrypoint
- `autoresearch-loop` skill — autonomous experiment loop with crash retry, research taste, and branch discipline
- Static contract test suite (`tests/autoresearch-skills/run-tests.sh`)
- Fast Claude Code harness suite (`tests/claude-code/run-skill-tests.sh`)
- GitHub Actions workflow (`skills-fast-checks.yml`) running both suites on push and PR
- README installation guidance for Claude Code limitations, plus Codex/OpenCode install guides

### Known Limitations

- **Claude Code marketplace install is not shipped.** Anthropic has not yet published a Claude Code marketplace package for this skill suite. Install via git clone as described in README.md.
- **OpenCode bootstrap system prompt not injected.** The `skills.paths` install path registers the skills directory but does not inject a bootstrap system prompt comparable to `using-superpowers`. OpenCode users can load and use the skills, but the repository does not currently guarantee proactive skill use at session start.
- **Live integration tests require Claude CLI.** The `--autoresearch-integration` test suite invokes Claude and takes 10–30 minutes. It is not run in CI by default.
