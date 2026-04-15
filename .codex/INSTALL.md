# Installing Autoresearch Skills V1 for Codex

Enable the autoresearch skill suite in Codex via native skill discovery.

## Prerequisites

- OpenAI Codex CLI
- Git

## Installation

1. Clone this repository somewhere stable, for example:
   ```bash
   git clone https://github.com/wintersdragon-c/karpathy-autoresearch-skills-forLLMresearch.git ~/.codex/autoresearch-skills-v1
   ```

   If you already have a local checkout, use that path instead of cloning again.

2. Create a Codex skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/autoresearch-skills-v1/skills ~/.agents/skills/autoresearch
   ```

   If your clone lives elsewhere, replace `~/.codex/autoresearch-skills-v1` with the real path.

   Windows (PowerShell):
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\autoresearch" "$env:USERPROFILE\.codex\autoresearch-skills-v1\skills"
   ```

3. Restart Codex so it rediscovers the skills.

## Verify

```bash
ls -la ~/.agents/skills/autoresearch
```

You should see a symlink or junction pointing at this repo's `skills/` directory.

Then start a fresh Codex session and ask:

```text
Use the autoresearch-brainstorming skill to diagnose this repo.
```

## Updating

```bash
cd ~/.codex/autoresearch-skills-v1 && git pull
```

Skills update through the symlink. Restart Codex after updating.

## Uninstalling

```bash
rm ~/.agents/skills/autoresearch
```

Optionally delete the clone:

```bash
rm -rf ~/.codex/autoresearch-skills-v1
```
