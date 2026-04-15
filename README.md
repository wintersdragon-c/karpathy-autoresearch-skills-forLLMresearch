# Autoresearch Skills V1

An autonomous ML research skill suite for coding agents, built on top of [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) experiment loop and [Superpowers](https://github.com/obra/superpowers) composable skill framework.

## What This Is

[Karpathy's autoresearch](https://github.com/karpathy/autoresearch) introduced a compelling idea: give a coding agent a single editable file (`train.py`), a fixed time budget per run, and a scalar metric to minimize — then let it iterate autonomously. The agent proposes changes, runs experiments, keeps improvements, discards regressions, and never stops.

[Superpowers](https://github.com/obra/superpowers) provides the skill infrastructure: composable Markdown-based "skills" that instruct coding agents to follow structured workflows (brainstorming, TDD, planning, subagent-driven development, etc.).

This project combines both: it wraps the autoresearch experiment loop in a full Superpowers skill pipeline, adding structured brainstorming, planning, bootstrap, and loop skills that enforce research discipline — baseline-first, crash retry, research taste criteria, branch isolation, and an autonomous operation contract.

## Research Domain Coverage

**Currently covered:**

- **LLM** — language model training, architecture search, optimizer tuning
- **RL** — reinforcement learning, reward shaping, policy optimization
- **NLP** — sequence modeling, tokenization, fine-tuning workflows

**Planned:**

- Agent systems
- Computer vision
- Multimodal

The pipeline is domain-agnostic at the skill level; domain coverage refers to the tested compatibility profiles and example repos.

## How It Works

The pipeline is a sequential state machine enforced by `next_allowed_skills` in `autoresearch/state.yaml`:

1. **autoresearch-brainstorming** — Diagnoses the repo, determines V1 compatibility, and produces a frozen spec. Blocked repos get a diagnosis and stop; no planning proceeds.

2. **autoresearch-planning** — Turns the approved spec into a low-ambiguity plan with exact file paths, verification commands, and expected outputs.

3. **autoresearch-bootstrap** — Executes the plan, generates `profile.yaml`, runs the mandatory baseline, and records `baseline_ref`.

4. **autoresearch-loop** — Runs bounded autonomous experiment iterations. Proposes changes to `train.py`, runs timed experiments, classifies each as `keep`/`discard`/`crash`, appends `results.tsv` and `ledger.jsonl`, and never pauses to ask unless genuinely blocked.

The agent checks for relevant skills before any action. The pipeline enforces order — you cannot skip brainstorming and jump to the loop.

## Installation

### Platform Support Matrix

| Platform | Status | Install Path |
|---|---|---|
| Claude Code marketplace/plugin install | Not supported yet | No marketplace package shipped in this repository |
| Codex | Supported | One-liner below |
| OpenCode | Supported | One-liner below |

### Codex

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch/refs/heads/main/.codex/INSTALL.md
```

Detailed guide: [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch/refs/heads/main/.opencode/INSTALL.md
```

Detailed guide: [docs/README.opencode.md](docs/README.opencode.md)

### Claude Code

This repository does not yet ship a Claude Code marketplace package or plugin manifest. Claude-side development tests exist but are not a public installation path.

### Verify Installation

Start a new session and explicitly ask for one of the skills:

- `Use the autoresearch-brainstorming skill to diagnose this repo.`
- `Use the autoresearch-bootstrap skill to set up the experiment profile.`

Then run:

```bash
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```

`tests/skill-triggering/run-all.sh` and `tests/explicit-skill-requests/run-all.sh` are prompt-registration checks only — they do not invoke Claude.

## Skills

### autoresearch-brainstorming
Inspects the repo, determines V1 compatibility (`v1-direct-fit`, `v1-bootstrap-fit`, or `v2-required`), decomposes multi-target onboarding requests before freezing scope, and produces a frozen spec under `docs/autoresearch/specs/`. Blocked repos get a diagnosis spec and `stage_status: blocked` — no planning or execution proceeds.

### autoresearch-planning
Produces a low-ambiguity plan under `docs/autoresearch/plans/` using a rigid task template, exact file paths, exact verification commands, and expected outputs. Stops after saving — the only valid next skill is `autoresearch-bootstrap`.

### autoresearch-bootstrap
Executes the approved plan using embedded `executing-plans` discipline. Generates `autoresearch/profile.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`, and any thin adapters; runs the mandatory baseline; records `baseline_ref`. Exits to `autoresearch-loop`.

### autoresearch-loop
Runs bounded autonomous experiment iterations inside the approved `edit_scope`. Classifies each run as `keep`, `discard`, or `crash`. Applies crash retry logic, research taste criteria (Simplicity, VRAM, Equal Performance), and branch discipline. Appends `results.tsv` and `ledger.jsonl`. Never pauses autonomously unless genuinely blocked.

## Tests

```bash
# Static contract checks (fast, no Claude needed)
bash tests/autoresearch-skills/run-tests.sh

# Fast harness checks
bash tests/claude-code/run-skill-tests.sh

# Live integration tests (requires Claude CLI, 10-30 minutes)
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

## Known Limitations

- **Claude Code marketplace install is not shipped.** Install via git clone as described above.
- **OpenCode bootstrap system prompt not injected.** The `skills.paths` install path does not currently guarantee proactive skill use at session start. OpenCode users can load and use the skills explicitly.
- **Live integration tests require Claude CLI.** Not run in CI by default.

## Updating

```bash
cd ~/.codex/autoresearch-skills-v1 && git pull
```

Restart the host tool after updating.

## Supporting Files

- `skills/autoresearch-bootstrap/profile-template.yaml` — profile schema reference
- `skills/autoresearch-bootstrap/state-template.yaml` — state schema with canonical bootstrap defaults
- `skills/autoresearch-bootstrap/run-manifest-template.yaml` — per-run scratch file schema
- `skills/autoresearch-loop/profile-reference.md` — field-level semantics for timeout, crash retry, git strategies, `rejection_streak`, `results_row_ref`, and `active_run_manifest`

## Credits

- [Andrej Karpathy](https://github.com/karpathy) — [autoresearch](https://github.com/karpathy/autoresearch), the autonomous experiment loop concept this project is built on
- [Jesse Vincent / obra](https://github.com/obra) — [Superpowers](https://github.com/obra/superpowers), the composable skill framework

## License

MIT License — see LICENSE file for details.
