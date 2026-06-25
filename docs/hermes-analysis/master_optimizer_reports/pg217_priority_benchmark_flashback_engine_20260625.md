# PG217 Priority Benchmark - Flashback Engine Slot

Status: rejected for apply; evidence-only benchmark.

Scope:

- Deck: `6` / Lorehold current deck.
- Candidate source:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg217_saga_draw_artifact_postsync_v1.json`.
- Required lane: `priority_benchmark_candidate`.
- Tested category: `engine`.
- Candidate: `Flashback`.
- Temporary cut target selected by `slot_optimizer.py`: `Reverberate`.
- Phase: `pg217_priority_matrix_v1`.

Baseline/hash guard:

- Baseline source:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_111525/summary.json`.
- Baseline importer:
  `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_gate_baseline.py`.
- Baseline report:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_gate_baseline_20260625_114942.md`.
- Baseline id: `9`.
- Baseline deck hash:
  `8f719f40b096e17644e1e9308c8f1be9ea2a6c122344d61967cad9fedd358d9f`.
- Baseline semantics hash:
  `b942018cbf4c67c5011a2d6465832ace4cda6aca67b6020695fb2b9bfb247418`.
- Baseline ruleset hash:
  `2f6276b7d7ddb3060a1e6a54119a3658ba95db23b83b8eaa33c20b6ec3427b9f`.
- Baseline WR: `12.5%` (`2W/14L/0S`).
- Battle gate divergence at baseline:
  `["event_contract_static=review_required"]`; all operational gates used by
  optimizer evidence were pass or accepted residual.

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py \
  --deck-id 6 \
  --games 1 \
  --max-per-category 1 \
  --category engine \
  --candidate-matrix docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260625_pg217_saga_draw_artifact_postsync_v1.json \
  --phase pg217_priority_matrix_v1 \
  --reset-current-baseline
```

Result:

- Matrix allowlist size: `54` normalized names from
  `priority_benchmark_candidate` / `battle_ready` rows.
- Selected candidates: `1`.
- Tested: `Flashback` replacing `Reverberate`.
- Result WR: `8.3%` (`1W/11L/0S`).
- Delta vs baseline: `-4.2pp`.
- Quality gate report:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_quality_gate_20260625_115439.md`.
- Quality gate structural status: `passed`.
- Strategic decision: reject/no handoff because benchmark was below baseline.

Integrity checks:

- The temporary swap restored the deck after the benchmark.
- Post-benchmark deck hash:
  `8f719f40b096e17644e1e9308c8f1be9ea2a6c122344d61967cad9fedd358d9f`.
- No PostgreSQL write and no deck apply happened.

Operational note:

- The legacy `master_optimizer_baseline.py` local battle runner was too slow
  for this phase and was interrupted before it produced a report. The new
  `master_optimizer_gate_baseline.py` uses the official battle-strategy-audit
  summary as baseline evidence and keeps the same hash guard contract for
  downstream slot benchmarks.
