# Demo Repo Autoresearch Adaptation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate the autoresearch compatibility layer for the demo repo so it can be operated as an autoresearch loop target.

**Architecture:** Single bootstrap pass. Generate profile.yaml from the frozen spec fields, scaffold state.yaml/results.tsv/ledger.jsonl, run one baseline to validate the entry command and metric extraction, then record baseline_ref.

**Tech Stack:** Python 3.10+, uv, GPT-style train.py, grep-based log extraction.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `autoresearch/profile.yaml` | Create | Frozen runtime and experiment configuration |
| `autoresearch/state.yaml` | Update | Bootstrap exit state |
| `autoresearch/results.tsv` | Create | TSV results log with header row |
| `autoresearch/ledger.jsonl` | Create | Canonical per-run history (empty at bootstrap) |

## Task 1 — Generate profile.yaml

**Files:** `autoresearch/profile.yaml`

- [ ] Create `autoresearch/profile.yaml` from `skills/autoresearch-bootstrap/profile-template.yaml`
- [ ] Fill `runtime.entry_command: "uv run train.py > run.log 2>&1"`
- [ ] Fill `runtime.timeout_seconds: 360`
- [ ] Fill `logging.summary_extract_command: "grep '^val_bpb:' run.log | tail -1"`
- [ ] Verify readable: `cat autoresearch/profile.yaml`
- [ ] Commit: `git add autoresearch/profile.yaml && git commit -m "bootstrap: add profile.yaml"`

## Task 2 — Scaffold state.yaml, results.tsv, ledger.jsonl

**Files:** `autoresearch/state.yaml`, `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`

- [ ] Write `autoresearch/results.tsv` with header: `commit\tmetric_value\tmemory_gb\tstatus\tdescription`
- [ ] Create empty `autoresearch/ledger.jsonl`
- [ ] Update `autoresearch/state.yaml` with `bootstrap_status: completed`, `active_profile_path: autoresearch/profile.yaml`
- [ ] Verify: `head -1 autoresearch/results.tsv` → `commit	metric_value	memory_gb	status	description`
- [ ] Commit: `git add autoresearch/ && git commit -m "bootstrap: scaffold results.tsv and ledger.jsonl"`

## Task 3 — Run baseline and record result

**Files:** `autoresearch/results.tsv`, `autoresearch/ledger.jsonl`, `autoresearch/state.yaml`

- [ ] Execute: `uv run train.py > run.log 2>&1` (wait up to 360 seconds)
- [ ] Extract metric: `grep '^val_bpb:' run.log | tail -1` → must return a value
- [ ] Append baseline row to `autoresearch/results.tsv`
- [ ] Append baseline entry to `autoresearch/ledger.jsonl`
- [ ] Set `baseline_ref` to current commit hash: `git rev-parse HEAD`
- [ ] Update `autoresearch/state.yaml` with exit gate values
- [ ] Commit: `git add autoresearch/ && git commit -m "bootstrap: record baseline result"`
