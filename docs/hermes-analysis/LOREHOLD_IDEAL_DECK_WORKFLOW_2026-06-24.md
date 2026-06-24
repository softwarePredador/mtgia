# Lorehold Ideal Deck Workflow

Status: current canonical workflow for Lorehold deck improvement.

## Decision

Do not try to pick the ideal Lorehold deck directly from XMage, raw WR, or the
old hardcoded builder.

Use a two-stage flow:

1. Close rule confidence for every card that touches Lorehold.
2. Benchmark only the rule-ready candidates through the safe master optimizer
   flow.

XMage is the rules/reference corpus. It tells ManaLoom how a card can be
modeled and tested. It is not the strategic deck oracle by itself.

## Active Tooling

Primary matrix generator:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_ideal_deck_candidate_matrix.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1
```

Current generated evidence:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1.md`

The script reads:

- active Lorehold deck `6`;
- prior Lorehold variants `606` and `607`;
- new Lorehold variants `608` through `616`;
- current XMage proposal report
  `xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json`;
- Hermes SQLite battle-rule cache for rule readiness.

It does not mutate deck rows, SQLite, or PostgreSQL.

## Current Matrix Result

Generated on 2026-06-24:

- total Lorehold-touching cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `35`;
- `watchlist_candidate`: `88`;
- `needs_rule_before_strategy`: `127`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Rule-readiness split:

- `battle_ready`: `268`;
- `mapper_manual`: `88`;
- `split_scope`: `26`;
- `runtime_needed`: `11`;
- `no_rule_signal`: `2`.

Operational interpretation:

- The `127` `needs_rule_before_strategy` cards must not drive deck swaps yet.
  They first need mapper/runtime/split-scope closure.
- The `35` `priority_benchmark_candidate` cards are the first practical swap
  candidates after baseline hash guard and battle gate review.
- `Chrome Mox` and `Mox Opal` are policy-blocked for the current no-premium-Mox
  Lorehold lane even if they have rule evidence.

## Current Rule-First Priority

The first deck-improvement work is not a swap. It is closing the highest-impact
Lorehold card rules from the matrix.

Start with:

- split-scope cards that are strategically relevant, such as
  `Pyromancer Ascension`, `Fury Storm`, `Cool but Rude`,
  `Profound Journey`, `Sun Titan`, `Glint-Horn Buccaneer`,
  `Taii Wakeen, Perfect Shot`, `Primal Amulet // Primal Wellspring`,
  `Starfield Shepherd`, `Erode`, and `Lightning Helix`;
- runtime-needed token or damage families only when the exact scope is
  reusable and has focused test coverage;
- manual mapper cards last unless they are blocking a top Lorehold role gap.

## Current Benchmark Candidate Lane

After rules are ready, the first battle-benchmark candidates are the top
rule-ready matrix rows, not every possible card.

Current top candidates include:

- `Library of Leng`;
- `Restoration Seminar`;
- `Reforge the Soul`;
- `Increasing Vengeance`;
- `Flare of Duplication`;
- `Volcanic Vision`;
- `Big Score`;
- `Flashback`;
- `Improvisation Capstone`;
- `Pinnacle Monk // Mystic Peak`;
- `Return the Favor`;
- `Monument to Endurance`;
- `Dawn's Truce`;
- `Arcane Bombardment`;
- `Creative Technique`.

These are candidate rows only. They still require baseline hash guard,
category-safe cut target, temporary battle benchmark, quality gate,
confirmation, handoff, and explicit apply approval.

## Historical Tools Removed From Active Path

The following are retained only as history/compatibility and must not guide new
Lorehold deck decisions:

- `build_optimized_deck.py`
  - now exits as `historical_disabled`;
  - reason: hardcoded collection/priority heuristic without rule readiness,
    baseline hashes, or battle evidence gates.
- `universal_optimizer.py`
  - now blocks execution unless explicitly overridden with
    `MANALOOM_ALLOW_LEGACY_UNIVERSAL_OPTIMIZER=1` or `--allow-legacy`;
  - reason: legacy quick/full auto-apply path is not authorized for current
    handoff.

Use `lorehold_ideal_deck_candidate_matrix.py` plus the safe master optimizer
pipeline instead.

## Required Gates Before Any Deck Change

Any actual deck change must pass:

1. current PostgreSQL/backend source-of-truth check when the claim depends on
   promoted data;
2. Hermes SQLite freshness check for the local battle cache;
3. approved baseline hash guard;
4. candidate matrix row in `priority_benchmark_candidate` or explicitly
   documented override;
5. temporary `slot_optimizer.py` benchmark;
6. `master_optimizer_quality_gate.py`;
7. confirmation/handoff artifact;
8. explicit apply approval;
9. post-apply battle gate and strategy-coherence review.

No matrix row is an automatic swap.
