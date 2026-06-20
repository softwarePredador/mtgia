# Battle latest 20260619_235553 learning and provenance recheck

Generated: 2026-06-19T21:00:36-03:00

## Scope

Read-only recheck of the current recurring battle audit snapshot for open learning/provenance findings:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_235553/seed_*/deck_provenance.json`

No code, PostgreSQL, deck swap, commit or push was performed.

## Aggregate evidence

- `timestamp_utc=2026-06-19T23:55:53Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`

## BV-072 result: remains open

Strategy evidence:

- `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`
- High-confidence seeds: `63202355`, `63202356`, `63202358`, `63202359`, `63202360`, `63202361`, `63202362`, `63202363`, `63202365`, `63202366`, `63202367`, `63202368`, `63202369`, `63202370`
- Low-confidence seeds: `63202357`, `63202364`
- `strategy_findings=3`
- `strategy_low_confidence_findings=3`
- Seed `63202364` has two `forced_keep_after_bad_mulligan` findings.
- `strategy_review_required_findings=0`
- `global_learning_eligible_seeds=null`
- `global_not_learning_eligible_seeds=null`

Inference: because this snapshot has all mandatory gates passing, the high-confidence strategy seed list is likely compatible with global learning in this run. That remains an inference, not a published post-gate contract.

Conclusion: `BV-072` remains open until global post-gate learning eligibility and per-seed reasons are published.

## BV-075 result: remains open

Deck provenance evidence:

- `summary.json.learned_deck_opponents=null`
- `summary.json.opponent_deck_provenance=null`
- `summary.json.learned_opponent_source_counts=null`
- Per-seed `deck_provenance.json` artifacts contain `64` deck rows: `16` `sqlite_deck_cards` rows and `48` `learned_decks` rows.
- Learned opponents have `12` unique refs.
- Learned rows use `source_system=pg_meta_decks`, `source_card_count=100`, `battle_card_count=99`, `cached_metadata_used_for_metrics=false`, `metrics_basis=runtime_derived_from_resolved_built_deck`, and `blocker_domain=none`.

Observed learned refs:

| Source ref | Name | Appearances |
| --- | --- | ---: |
| `learned_deck:116` | Tayam, Luminous Enigma #116 (real) | 7 |
| `learned_deck:42` | The Emperor of Palamecia #42 (real) | 7 |
| `learned_deck:104` | Kinnan, Bonder Prodigy #104 (real) | 6 |
| `learned_deck:25` | Tayam, Luminous Enigma #25 (real) | 5 |
| `learned_deck:105` | Etali, Primal Conqueror #105 (real) | 4 |
| `learned_deck:58` | Thrasios, Triton Hero #58 (real) | 4 |
| `learned_deck:31` | Sisay, Weatherlight Captain #31 (real) | 3 |
| `learned_deck:54` | Thrasios, Triton Hero #54 (real) | 3 |
| `learned_deck:62` | Rograkh, Son of Rohgahh #62 (real) | 3 |
| `learned_deck:74` | Dargo, the Shipwrecker #74 (real) | 2 |
| `learned_deck:83` | Kraum, Ludevic's Opus #83 (real) | 2 |
| `learned_deck:84` | Kinnan, Bonder Prodigy #84 (real) | 2 |

Conclusion: `BV-075` remains open. Per-seed provenance exists, but the principal `summary.json` still does not aggregate learned opponents or construction/coherence status.
