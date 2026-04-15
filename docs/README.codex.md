# Autoresearch Skills V1 for Codex

Guide for using the autoresearch skill suite with Codex via native skill discovery.

## Quick Install

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch.git ~/.codex/autoresearch-skills-v1
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/autoresearch-skills-v1/skills ~/.agents/skills/autoresearch
   ```

3. Restart Codex.

## How It Works

Codex scans `~/.agents/skills/` at startup and discovers each skill from its `SKILL.md` frontmatter. This repository exposes the whole suite through one symlink:

```text
~/.agents/skills/autoresearch/ -> ~/.codex/autoresearch-skills-v1/skills/
```

## Usage

Skills can be loaded explicitly or discovered from task descriptions. Example prompts:

- `Use the autoresearch-brainstorming skill to diagnose this repo.`
- `Use the autoresearch-bootstrap skill to generate the autoresearch profile.`

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

## Updating

```bash
cd ~/.codex/autoresearch-skills-v1 && git pull
```

Restart Codex after updating.

## Uninstalling

```bash
rm ~/.agents/skills/autoresearch
```
