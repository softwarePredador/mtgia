# Battle latest 20260619_234218 effect, learning and provenance recheck

Generated: 2026-06-19T20:45:48-03:00

## Scope

Read-only recheck of the current recurring battle audit snapshot:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234218/seed_*/deck_provenance.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`

No code, PostgreSQL, deck swap, commit or push was performed.

## Aggregate gate evidence

- `timestamp_utc=2026-06-19T23:42:18Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- Required gates in `mandatory_gates_required_for_final_status`: `action_critic`, `strategy_audit`, `replay_decision_audit`, `forensic_audit`, `effect_coverage`, `focused_template_dispatch`, `unknown_template_backlog`, `decision_trace_taxonomy`, `event_contract_static`
- Gate statuses: all `pass`
- `test_results_total=16`, `test_results_status_counts={"pass":16}`, `test_log_empty_successes=[]`, `test_log_empty_failures=[]`

Important caveat: this trusted aggregate does not close source/provenance/reporting follow-ups by itself.

## BV-068 result: close

Current summary now publishes the missing denominator for `effect=unknown`:

- `effect_coverage_effect_totals_unknown=41`
- `effect_coverage_unknown_effect_cards` has `34` unique cards.
- The sum of `effect_coverage_unknown_effect_cards[].decks.length` is `41`, matching `effect_coverage_effect_totals_unknown`.
- `effect_coverage_unknown_effect_source_counts={"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`
- `effect_coverage_unknown_effect_status_counts={"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`
- `focused_template_ready_effect_totals={"remove_permanent":1,"unknown":28}`
- `needs_review_unknown_effect_count=5`
- `needs_review_unknown_effect_cards` lists `Amulet of Vigor`, `Blood Moon`, `Exploration`, `Ghostly Flicker` and `Grasp of Fate`.
- `Mirrormade` is represented as `waived_curated_unknown_effect` from `battle_rule_curated` with four deck appearances.

Conclusion: `BV-068` is closed for this snapshot because the result principal now reconciles the `41` unknown-effect appearances to concrete card/status/source/owner rows. `unknown_template_backlog_cards=0` still only means the source-unknown backlog is ready; it must not be used as the denominator by itself.

## BV-069 result: remains open

Current `effect_coverage.json` still has current source keys:

- `source_totals.battle_rule_curated=724`
- `source_totals.battle_rule_needs_review_generated=34`
- `deck_totals` has `13` decks with `battle_rule_curated>0`, sum `724`.
- `deck_totals` has `11` decks with `battle_rule_needs_review_generated>0`, sum `34`.
- Old keys sum to zero: `battle_rule_manual=0`, `battle_rule_generated=0`.

Current `effect_coverage.md` still renders the old columns:

- Header line: `Battle Manual | Battle Generated`
- All deck rows show `0 | 0` in those two columns.

Code evidence:

- `battle_effect_coverage_audit.py` renders the header with `Battle Manual` and `Battle Generated`.
- The renderer reads `totals.get("battle_rule_manual", 0)` and `totals.get("battle_rule_generated", 0)`.

Conclusion: `BV-069` remains open. The JSON is correct enough to preserve the source totals, but the Markdown table still hides `724 + 34 = 758` battle-rule sourced instances at deck level.

Task for "Ajustar battle":

- Render `Deck Coverage` from `battle_rule_curated` and `battle_rule_needs_review_generated`, or generate source columns dynamically from `deck_totals/source_totals`.
- Add a test that compares Markdown table totals against `effect_coverage.json.deck_totals` and fails when nonzero source keys are omitted or displayed as zero.

## BV-072 result: remains open

Current strategy evidence:

- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- High-confidence seeds: `63202343`, `63202344`, `63202345`, `63202346`, `63202347`, `63202348`, `63202349`, `63202350`, `63202351`, `63202352`, `63202354`, `63202355`, `63202356`
- Low-confidence seeds: `63202342`, `63202353`, `63202357`
- Strategy findings: `3`, all `medium` / `forced_keep_after_bad_mulligan`
- `strategy_review_required_findings=0`
- `global_learning_eligible_seeds=null`
- `global_not_learning_eligible_seeds=null`

Inference: because this run has all mandatory gates passing, the high-confidence strategy seeds are likely compatible with global learning in this snapshot. That is still an inference, not a published global contract.

Conclusion: `BV-072` remains open until the wrapper publishes post-gate global learning eligibility and reasons per seed, or renames the current strategy-only fields so downstream consumers cannot mistake them for global eligibility.

Task for "Ajustar battle":

- Publish `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds` and per-seed reasons after all mandatory gates.
- Add a regression where a seed is high confidence in strategy audit but blocked/reviewed by another mandatory gate, proving it cannot become globally learning eligible.

## BV-075 result: remains open

Current deck provenance evidence:

- `summary.json` still has `learned_deck_opponents=null`, `opponent_deck_provenance=null`, and `learned_opponent_source_counts=null`.
- Per-seed `deck_provenance.json` files exist for `16` seeds.
- Across those files: `64` deck rows, `16` `sqlite_deck_cards` rows for Lorehold and `48` `learned_decks` rows for opponents.
- Learned rows have `12` unique refs.
- All `48` learned rows have `blocker_domain=none`.
- Learned rows use `source_system=pg_meta_decks`, `source_card_count=100`, `battle_card_count=99`, `cached_metadata_used_for_metrics=false`, and `metrics_basis=runtime_derived_from_resolved_built_deck`.

Observed learned refs:

| Source ref | Name | Appearances |
| --- | --- | ---: |
| `learned_deck:104` | Kinnan, Bonder Prodigy #104 (real) | 6 |
| `learned_deck:74` | Dargo, the Shipwrecker #74 (real) | 6 |
| `learned_deck:116` | Tayam, Luminous Enigma #116 (real) | 5 |
| `learned_deck:42` | The Emperor of Palamecia #42 (real) | 5 |
| `learned_deck:58` | Thrasios, Triton Hero #58 (real) | 5 |
| `learned_deck:105` | Etali, Primal Conqueror #105 (real) | 4 |
| `learned_deck:25` | Tayam, Luminous Enigma #25 (real) | 4 |
| `learned_deck:54` | Thrasios, Triton Hero #54 (real) | 3 |
| `learned_deck:83` | Kraum, Ludevic's Opus #83 (real) | 3 |
| `learned_deck:84` | Kinnan, Bonder Prodigy #84 (real) | 3 |
| `learned_deck:31` | Sisay, Weatherlight Captain #31 (real) | 2 |
| `learned_deck:62` | Rograkh, Son of Rohgahh #62 (real) | 2 |

Conclusion: `BV-075` remains open. The provenance exists in per-seed artifacts, but the principal `summary.json` still does not aggregate learned opponents or expose construction/coherence status for them.

Task for "Ajustar battle":

- Aggregate learned opponents in `summary.json` by `source_system`, `source_ref`, name and row id when available.
- Include appearances/seeds, `source_card_count`, `battle_card_count`, metrics basis, cached flag, blocker domain and construction/coherence status.
- Add a test that fails when learned opponents appear in `seed_*/deck_provenance.json` but summary-level learned opponent fields remain null.
