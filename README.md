# Autoresearch Skills V1

Superpowers skills for running autonomous ML experiment loops on small research repos.

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

## Skills

### autoresearch-brainstorming
Use when a small research training repo must be diagnosed and scoped into an autoresearch-style experiment profile before any repo changes or runs begin.

Inspects the repo, determines V1 compatibility (`v1-direct-fit`, `v1-bootstrap-fit`, or `v2-required`), decomposes multi-target onboarding requests before freezing scope, and produces a frozen spec under `docs/autoresearch/specs/`. For `v1-bootstrap-fit` repos, the spec must define the thin adapter boundary explicitly. Blocked repos (`v2-required`) get a diagnosis spec and a `stage_status: blocked` state — no planning or execution proceeds.

### autoresearch-planning
Use when an approved autoresearch spec exists and must be turned into a concrete repo-adaptation plan before bootstrap begins.

Produces a low-ambiguity plan under `docs/autoresearch/plans/` using a rigid task template, exact file paths, exact verification commands, and expected outputs. After saving the plan and updating `autoresearch/state.yaml`, it stops — the only valid next skill is `autoresearch-bootstrap`. It does not offer execution modes.

### autoresearch-bootstrap
Use when an approved autoresearch plan is ready to be turned into a runnable autoresearch compatibility layer for a small research repo.

Reads and executes the approved plan using embedded `executing-plans` discipline: reviews the plan critically before acting, tracks the approved plan's tasks with TodoWrite, and stops on blockers rather than guessing. Generates `autoresearch/profile.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`, and any thin adapters; runs the mandatory baseline; records `baseline_ref`. Exits to `autoresearch-loop`.

### autoresearch-loop
Use when a validated autoresearch bootstrap is complete and the experiment loop is ready to run.

Runs bounded autonomous experiment iterations inside the approved `edit_scope`. Classifies each run as `keep`, `discard`, or `crash`. Appends `results.tsv` and `ledger.jsonl`. Terminates normally (`stopped-completed`) or abnormally (`stopped-blocked`) based on crash limits.

## Pipeline

```
autoresearch-brainstorming
  → autoresearch-planning
    → autoresearch-bootstrap
      → autoresearch-loop
```

Each skill sets `next_allowed_skills` to enforce the pipeline order. State is tracked in `autoresearch/state.yaml`.

## Tests

```bash
# Static contract checks (fast, no Claude needed)
bash tests/autoresearch-skills/run-tests.sh

# Trigger and explicit-request coverage
bash tests/skill-triggering/run-all.sh
bash tests/explicit-skill-requests/run-all.sh

# Fast harness checks
bash tests/claude-code/run-skill-tests.sh

# Live integration tests (requires Claude CLI, 10-30 minutes)
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

## Known Limitations

- **Claude Code marketplace install is not shipped.** Anthropic has not yet published a Claude Code marketplace package for this skill suite. Install via git clone as described in the [Installation](#installation) section.
- **OpenCode bootstrap system prompt not injected.** The `skills.paths` install path registers the skills directory but does not currently guarantee proactive skill use at session start because this release does not inject a bootstrap system prompt comparable to `using-superpowers`. OpenCode users can load and use the skills explicitly.
- **Live integration tests require Claude CLI.** The `--autoresearch-integration` test suite invokes Claude and takes 10–30 minutes. It is not run in CI by default.

## Updating

If you installed via a local clone and symlink/path configuration, updates are just a pull:

```bash
cd /path/to/autoresearch-skills-v1 && git pull
```

Restart the host tool after updating so it rediscovers the latest skill content.

## Supporting Files

- `skills/autoresearch-bootstrap/profile-template.yaml` — profile schema reference
- `skills/autoresearch-bootstrap/state-template.yaml` — state schema with canonical bootstrap defaults
- `skills/autoresearch-bootstrap/run-manifest-template.yaml` — per-run scratch file schema
- `skills/autoresearch-loop/profile-reference.md` — field-level semantics for timeout, crash retry, git strategies, `rejection_streak`, `results_row_ref`, and `active_run_manifest`
