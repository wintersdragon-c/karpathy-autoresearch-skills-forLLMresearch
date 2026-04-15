# Autoresearch Skills V1 for Codex

Guide for using the autoresearch skill suite with Codex via native skill discovery.

## Quick Install

Open this local file and follow it:

```text
/path/to/autoresearch-skills-v1/.codex/INSTALL.md
```

## Manual Installation

1. Clone this repository:
   ```bash
   git clone <your-repo-url> ~/.codex/autoresearch-skills-v1
   ```

   If this repository has not been published yet, `<your-repo-url>` is a publish-time checklist item and must be replaced with the final public clone URL before the release is announced.

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
