# Autoresearch Skills V1 for OpenCode

Guide for using the autoresearch skill suite with OpenCode via local `skills.paths` configuration.

## Installation

1. Clone this repository locally.
2. Add the repo's `skills/` directory to `opencode.json`:

```json
{
  "skills": {
    "paths": [
      "/absolute/path/to/autoresearch-skills-v1/skills"
    ]
  }
}
```

3. Restart OpenCode.

## Usage

### Finding Skills

```text
use skill tool to list skills
```

### Loading a Skill

```text
use skill tool to load autoresearch-brainstorming
```

## Updating

Pull the latest changes in your local clone and restart OpenCode:

```bash
cd /absolute/path/to/autoresearch-skills-v1 && git pull
```

## Uninstalling

Remove the `skills.paths` entry that points at this repository and restart OpenCode.

## Verification

Use the skill tool to confirm discovery:

```text
use skill tool to list skills
use skill tool to load autoresearch-brainstorming
```

Then from the repo root run:

```bash
bash tests/autoresearch-skills/run-tests.sh
```

## Limitation

This install path registers the skills directory, but it does not inject a bootstrap system prompt comparable to `using-superpowers`. OpenCode users can load and use the skills, but the repository does not currently guarantee proactive skill use at session start.
