# Installing Autoresearch Skills V1 for OpenCode

This repository does not currently ship an OpenCode plugin. Install it through OpenCode's local skill-path configuration.

## Prerequisites

- OpenCode installed
- A local clone of this repository

## Installation

1. Clone this repository somewhere stable, for example:
   ```bash
   git clone <your-repo-url> ~/.config/opencode/autoresearch-skills-v1
   ```

2. Add this repo's `skills/` directory to `opencode.json` using `skills.paths`:
   ```json
   {
     "skills": {
       "paths": [
         "/absolute/path/to/autoresearch-skills-v1/skills"
       ]
     }
   }
   ```

   Replace the example path with the real absolute path to your clone.

3. Restart OpenCode.

## Verify

In OpenCode, list discovered skills or explicitly ask for one:

```text
Use skill tool to list skills
```

Then try:

```text
use skill tool to load autoresearch-brainstorming
```

## Updating

```bash
cd /absolute/path/to/autoresearch-skills-v1 && git pull
```

Restart OpenCode after updating.

## Uninstalling

Remove the `skills.paths` entry that points at this repository and restart OpenCode.
