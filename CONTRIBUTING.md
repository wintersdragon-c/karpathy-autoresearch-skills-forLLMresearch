# Contributing

Thanks for contributing to Autoresearch Skills V1.

## Scope

This repository contains a focused four-skill workflow for small single-machine research repos:

- `autoresearch-brainstorming`
- `autoresearch-planning`
- `autoresearch-bootstrap`
- `autoresearch-loop`

Please keep changes aligned with that scope unless the change explicitly expands V1.

## Before Opening a Change

1. Read the relevant `SKILL.md` files first.
2. Prefer reusing proven patterns from `superpowers-origin` instead of inventing new workflow machinery.
3. Keep trigger descriptions trigger-only. Do not move workflow summaries into frontmatter descriptions.
4. Keep contracts explicit. Avoid free-form wording where the skill depends on canonical enums or state fields.

## Testing

Run the smallest relevant checks first:

```bash
bash tests/autoresearch-skills/run-tests.sh
bash tests/claude-code/run-skill-tests.sh
```

Before claiming a workflow change is complete, run the live suite:

```bash
bash tests/claude-code/run-skill-tests.sh --autoresearch-integration
```

If you change trigger wording or explicit invocation behavior, also run:

```bash
bash tests/skill-triggering/run-all.sh
bash tests/explicit-skill-requests/run-all.sh
```

## Change Guidelines

- Prefer small, reviewable diffs.
- Do not weaken hard gates, state ownership rules, or review loops without updating tests and docs together.
- When changing prompts, update the matching harness or integration checks in the same change.
- If a behavior is borrowed from `superpowers-origin`, note that clearly in the PR or issue description.

## Pull Requests

Include:

- what changed
- why it changed
- which tests were run
- any known limitations or follow-up work
