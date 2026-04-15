---
name: using-autoresearch
description: Use when starting any session — establishes the autoresearch pipeline and requires Skill tool invocation before any response or action
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
You have the autoresearch skill suite installed.

**Before any response or action**, check whether one of the four autoresearch skills applies. Even a 1% chance a skill might apply means you MUST invoke it.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Use Skills

In Claude Code, use the `Skill` tool. Invoke a skill by name before acting:

```
Skill("autoresearch-brainstorming")
Skill("autoresearch-planning")
Skill("autoresearch-bootstrap")
Skill("autoresearch-loop")
```

When you invoke a skill, its content is loaded — follow it directly.

## The Four Skills

### autoresearch-brainstorming
**When:** A research repo needs to be diagnosed and scoped before any changes begin.
Inspects the repo, determines V1 compatibility, and produces a frozen spec. Use this first — always.

### autoresearch-planning
**When:** An approved spec exists and needs a concrete implementation plan.
Produces a low-ambiguity plan with exact file paths and verification commands. Only valid after brainstorming.

### autoresearch-bootstrap
**When:** An approved plan is ready to execute.
Runs the plan, generates `profile.yaml`, runs the mandatory baseline, records `baseline_ref`. Only valid after planning.

### autoresearch-loop
**When:** Bootstrap is complete and the experiment loop is ready to run.
Runs autonomous experiment iterations: propose → run → keep/discard/crash. Never pauses unless genuinely blocked.

## Pipeline Order

```
autoresearch-brainstorming
  → autoresearch-planning
    → autoresearch-bootstrap
      → autoresearch-loop
```

You cannot skip stages. Each skill sets `next_allowed_skills` in `autoresearch/state.yaml` to enforce this.

## Red Flags

These thoughts mean STOP — you are rationalizing:

| Thought | Reality |
|---------|---------|
| "I'll just look at the code first" | Skill check comes BEFORE any action. |
| "This is a simple question, no skill needed" | Before any response or action, check for skills. |
| "I already know what to do" | Load the skill anyway — it has the contract. |
| "The user didn't ask for a skill" | Pipeline discipline is not optional. |
| "This doesn't seem autoresearch-related" | If there's a 1% chance it is, invoke the skill. |
