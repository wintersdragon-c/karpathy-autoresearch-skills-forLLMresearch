# Autoresearch Skills Static Test Suite

This suite is a **static contract and fixture validator** for the `autoresearch-*` skill family. It does not execute live Claude sessions or run training experiments.

**Current state:** All four skills implemented (Tasks 1-4 complete). All static checks are active.

## Fixture categories

| Fixture | Represents |
|---|---|
| `autoresearch-brainstorming/` | Pre-spec state: no spec written yet |
| `autoresearch-planning/` | Post-spec, pre-plan state: spec approved, plan not yet written |
| `autoresearch-bootstrap/` | Post-plan, pre-bootstrap state: plan approved, no generated artifacts yet |
| `autoresearch-loop/` | Post-bootstrap, pre-run state: profile and baseline validated, loop not yet started |

## What it checks (now active)

- All four skill files exist (`autoresearch-brainstorming`, `autoresearch-planning`, `autoresearch-bootstrap`, `autoresearch-loop`)
- All trigger fixtures exist and contain required fields
- Every fixture `state.yaml` includes `schema_version` and a non-empty `project_id`
- Canonical artifact paths use `docs/autoresearch/` and `autoresearch/` (no drift to `docs/research/` or `research/`)
- State/status enumerations and `next_allowed_skills` exit gates match the spec
- Per-skill state ownership contracts: each fixture only contains fields the owning skill is allowed to write; downstream fields remain null or absent

## Ownership-boundary checks

Each fixture represents the state **before** the owning skill runs. This means downstream fields must be null or absent in the fixture:

- `autoresearch-brainstorming` fixture: `active_profile_path` is null — the profile is not generated until bootstrap
- `autoresearch-planning` fixture: `active_plan_path` is null — the plan is not written until planning completes
- `autoresearch-bootstrap` fixture: `best_ref` is null — the loop has not run any experiments yet
- `autoresearch-loop` fixture: `active_run_manifest` is null — no run is in flight at loop start

This ensures each skill's contract is tested in isolation and no skill silently writes fields it does not own.

## Limitations

This suite validates static text and file presence. It does **not** prove:
- That a live Claude agent will follow the skill correctly
- That the baseline run command actually works on a real repo
- That the loop terminates correctly under all conditions

Live integration coverage is in `tests/claude-code/test-autoresearch-*-integration.sh`.

## Running

```bash
# Requires ripgrep (rg) in PATH
bash tests/autoresearch-skills/run-tests.sh

# Trigger prompt registration check
bash tests/skill-triggering/run-all.sh

# Explicit skill-request prompt check
bash tests/explicit-skill-requests/run-all.sh
```
