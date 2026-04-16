# Research Onboarding Examples

Domain-specific walkthroughs showing how the autoresearch pipeline handles different research repo shapes.

---

## Example 1: Small LLM trainer

**Repo shape:** Single `train.py` with GPT-style model, Muon+AdamW optimizer, `val_bpb` printed to stdout.

**Starting skill:** `autoresearch-brainstorming`

**Metric:** `val_bpb` (lower is better), extracted from stdout via `grep "^val_bpb:" run.log | awk '{print $2}'`

**Classification:** `v1-direct-fit` — single entry command, single scalar metric, no adapter needed.

**What happens:** Brainstorming freezes the metric and extraction command. Planning writes a scaffold plan. Bootstrap generates `profile.yaml`, runs the baseline, records `baseline_ref`. Loop iterates on `train.py` within `edit_scope`.

---

## Example 2: RL repo with scalar reward metric

**Repo shape:** `train.py` + `env.py` + `agent.py`. Training logs episode reward to a CSV file.

**Starting skill:** `autoresearch-brainstorming`

**Metric:** `mean_reward` (higher is better), extracted from CSV via `tail -1 results.csv | cut -d',' -f3`

**Classification:** `v1-bootstrap-fit` — needs a thin log-extraction adapter to normalize the CSV output to a single number.

**What happens:** Brainstorming identifies the CSV extraction need and freezes the adapter boundary. Bootstrap creates a thin wrapper script that extracts the metric. Loop iterates on `train.py` and `agent.py`.

---

## Example 3: Agent harness or eval benchmark repo

**Repo shape:** Multi-file agent system with `run_eval.py` producing a JSON report with multiple scores.

**Starting skill:** `autoresearch-brainstorming`

**Metric:** `overall_score` (higher is better), extracted from JSON via `python3 -c "import json; print(json.load(open('eval_report.json'))['overall_score'])"`

**Classification:** `v1-bootstrap-fit` — needs a thin adapter to extract the single scalar from the JSON report.

**What happens:** Brainstorming freezes the JSON extraction path. Planning specifies the adapter. Bootstrap creates the extractor, runs baseline. Loop iterates within the approved edit scope.

---

## Example 4: CV trainer with offline evaluation script

**Repo shape:** `train.py` + `evaluate.py`. Training produces checkpoints; evaluation runs separately and prints accuracy.

**Starting skill:** `autoresearch-brainstorming`

**Metric:** `top1_accuracy` (higher is better), extracted from evaluation stdout via `grep "Top-1:" eval.log | awk '{print $2}'`

**Classification:** `v1-bootstrap-fit` — needs a thin wrapper that chains training and evaluation into a single entry command.

**What happens:** Brainstorming identifies the two-step execution need. Bootstrap creates a wrapper script (`run_and_eval.sh`) that runs training then evaluation. The metric extraction targets the evaluation output.

---

## Example 5: Repo diagnosed as `v2-required`

**Repo shape:** Distributed training across multiple GPUs with custom NCCL setup, no single-machine entry point, metric requires aggregation across workers.

**Starting skill:** `autoresearch-brainstorming`

**Metric:** Cannot be reduced to a single-machine scalar extraction within V1 constraints.

**Classification:** `v2-required` — brainstorming writes a diagnosis spec with `stage_status: blocked` and `profile_status: blocked-v2-required`. No planning or execution proceeds.

**What happens:** The diagnosis spec documents why V1 cannot handle this repo (distributed execution, multi-worker metric aggregation) and what V2 would need to support it. The pipeline stops cleanly.
