# Battle latest global learning and learned opponents recheck - 2026-06-19T23:36:26Z

Scope: read-only validation. No code was changed for this report, PostgreSQL was
not touched, and no deck swaps were applied.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_232324/summary.json`
- all `seed_*/strategy_audit.json`
- all `seed_*/deck_provenance.json`
- all `seed_*/action_critic.json`
- all `seed_*/forensic_audit.json`
- all `seed_*/replay_decision_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current aggregate gate

Latest official run:

- `timestamp_utc=2026-06-19T23:23:24Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `action_critic.status=pass`, `findings=0`
- `forensic_audit.status=pass`, `rule_findings=0`, `turn_findings=0`
- `replay_decision_audit.status=pass`, `decision_findings=0`,
  `turn_findings=0`
- `strategy_audit.status=pass`, `findings=4`,
  `review_required_findings=0`, `low_confidence_findings=4`
- high/critical action findings: `[]`
- high/critical replay-decision findings: `[]`
- high/critical forensic findings: `[]`

No high/critical action finding or strategy blocker was present in this summary.

## Strategy/global-learning evidence

Per-seed strategy artifacts:

- Strategy audit files scanned: `16`
- `high_confidence_replay`: `13`
- `low_confidence_replay`: `3`
- `review_required_findings`: `0`
- total strategy findings: `4`
- weight split: `13` seeds at `1.0`, `3` seeds at `0.0`

High-confidence seeds in the current summary:

```text
63202323, 63202324, 63202325, 63202326, 63202327, 63202328, 63202329,
63202330, 63202331, 63202334, 63202335, 63202336, 63202337
```

Low-confidence seeds in the current summary:

```text
63202332, 63202333, 63202338
```

The three low-confidence seeds all have `learning_confidence=low_confidence_replay`,
`high_confidence_learning_eligible=false`, `high_confidence_learning_weight=0.0`,
and code `forced_keep_after_bad_mulligan`.

The aggregate summary still does not publish explicit global learning fields:

- `global_learning_eligible_seeds=null`
- `global_not_learning_eligible_seeds=null`

Inference, not proven by a dedicated summary field: because the current final
status is trusted and all mandatory gates pass, the `strategy_high_confidence`
list is consistent with global eligibility for this specific run. This is still
not a contract. `BV-072` remains open until the summary publishes global fields
and reasons after all gates are evaluated.

## Learned-deck opponent provenance

The current summary publishes:

- `deck_provenance_files`: `16` files
- `deck_source_blocker_domains={"none":64}`
- `learned_deck_opponents=null`
- `opponent_deck_provenance=null`
- `learned_opponent_source_counts=null`

Per-seed `deck_provenance.json` evidence:

- Total deck provenance rows: `64`
- Lorehold rows: `16`, `source_kind=sqlite_deck_cards`,
  `source_ref=deck_id:6`, construction report valid.
- Learned-deck opponent appearances: `48`
- Unique learned opponent refs: `11`
- All learned opponent rows have:
  - `source_system=pg_meta_decks`
  - `source_card_count=100`
  - `battle_card_count=99`
  - `cached_metadata_used_for_metrics=false`
  - `metrics_basis=runtime_derived_from_resolved_built_deck`
  - `blocker_domain=none`
  - `construction_report=null`

Observed learned opponents:

| Appearances | Source ref | Name |
| ---: | --- | --- |
| 8 | `learned_deck:105` | `Etali, Primal Conqueror #105 (real)` |
| 7 | `learned_deck:116` | `Tayam, Luminous Enigma #116 (real)` |
| 6 | `learned_deck:104` | `Kinnan, Bonder Prodigy #104 (real)` |
| 5 | `learned_deck:84` | `Kinnan, Bonder Prodigy #84 (real)` |
| 5 | `learned_deck:74` | `Dargo, the Shipwrecker #74 (real)` |
| 5 | `learned_deck:42` | `The Emperor of Palamecia #42 (real)` |
| 4 | `learned_deck:62` | `Rograkh, Son of Rohgahh #62 (real)` |
| 3 | `learned_deck:54` | `Thrasios, Triton Hero #54 (real)` |
| 2 | `learned_deck:83` | `Kraum, Ludevic's Opus #83 (real)` |
| 2 | `learned_deck:31` | `Sisay, Weatherlight Captain #31 (real)` |
| 1 | `learned_deck:58` | `Thrasios, Triton Hero #58 (real)` |

`BV-075` remains open: the source-backed details exist in per-seed artifacts,
but the main `summary.json` still does not aggregate learned opponents or their
source status.

## Task for "Ajustar battle"

1. Add post-gate global learning fields to `summary.json`, including
   `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds`, and
   per-seed reasons that combine final gate status, action critic,
   replay-decision audit, forensic audit, event contracts, template gates, and
   strategy confidence.
2. Keep `strategy_high_confidence_learning_seeds` as a strategy-audit field, or
   rename/scope it clearly so consumers do not treat it as a global contract
   without the post-gate fields.
3. Aggregate learned-deck opponents in the main summary by unambiguous key:
   `source_system`, `source_ref`, `name`, appearances/seeds,
   `source_card_count`, `battle_card_count`, cached metadata flag, metrics basis,
   blocker domain, and construction/coherence status.
4. Add a test or wrapper check that fails when per-seed learned opponents exist
   but `learned_deck_opponents`, `opponent_deck_provenance`, or
   `learned_opponent_source_counts` remain null.

## Status

`BV-072` and `BV-075` remain open with current latest evidence. The current
mandatory replay gates are trusted, but the main summary still lacks the global
learning contract and learned-opponent aggregate provenance.
