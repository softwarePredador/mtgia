# Battle latest 20260619_234922 current open recheck

Generated: 2026-06-19T20:54:57-03:00

## Scope

Read-only recheck of the current recurring battle audit snapshot:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_234922/seed_*/deck_provenance.json`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`

No code, PostgreSQL, deck swap, commit or push was performed.

## Aggregate gate evidence

- `timestamp_utc=2026-06-19T23:49:22Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`

This trusted aggregate still does not mean every reporting/provenance consumer is ready.

## Closed in current latest

`BV-068` remains closed:

- `effect_coverage_effect_totals_unknown=41`
- `effect_coverage_unknown_effect_cards` represents `34` unique cards.
- Sum of unknown-card deck appearances is `41`, matching the effect total.
- Source counts: `{"battle_rule_curated":1,"battle_rule_needs_review_generated":5,"focused_template_ready":28}`
- Status counts: `{"focused_template_ready":28,"needs_review":5,"waived_curated_unknown_effect":1}`

`BV-069` remains closed:

- `effect_coverage.json.source_totals.battle_rule_curated=724`
- `effect_coverage.json.source_totals.battle_rule_needs_review_generated=34`
- `effect_coverage.md` now renders `Battle Rule Curated` and `Battle Rule Needs Review Generated`.
- The table no longer renders historical `Battle Manual` / `Battle Generated` columns.

## BV-071 result: remains open

Runtime surface evidence:

- `runtime_surface_manifest.json.summary.total_files=108`
- `runtime_surface_manifest.json.summary.unclassified_files=[]`
- `runtime_surface_manifest.json.summary.automation_coverage_counts={"covered_by_recurring_run":29,"imported_by_core_runtime":6,"outside_recurring_run":73}`
- `runtime_surface_manifest.json.summary.category_counts={"core runtime":31,"focused evidence/promotion":4,"learned-deck source":14,"optimizer/scorecard":15,"recurring audit gate":24,"renderer":4,"review queue":1,"rule registry/sync":15}`
- `runtime_surface_manifest.json.summary.gate_expected_counts={"core_runtime_import_regression":6,"recurring_audit_required":29,"targeted_manual_gate_required_before_change":31,"targeted_test_required_before_change":42}`
- `summary.json.runtime_surface_manifest_total_files=108`
- `summary.json.runtime_surface_manifest_gate_expected_counts=null`
- `summary.json.runtime_surface_manifest_status=null`

Test evidence:

- `test_battle_runtime_surface_manifest.py` still uses `assert summary["total_files"] >= 98`.
- The test checks category presence and per-file non-empty `owner`, `gate_expected`, and `automation_coverage`, but does not pin `108` or exact category/coverage/gate counts.

Conclusion: `BV-071` remains open.

Task for "Ajustar battle":

- Pin the current denominator or require a versioned snapshot/waiver when `total_files` changes.
- Validate exact category, automation coverage and gate expected counts.
- Publish `runtime_surface_manifest_gate_expected_counts` and a manifest status in `summary.json`.

## BV-072 result: remains open

Strategy evidence:

- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- High-confidence seeds: `63202349`, `63202350`, `63202351`, `63202352`, `63202354`, `63202355`, `63202356`, `63202358`, `63202359`, `63202360`, `63202361`, `63202362`, `63202363`
- Low-confidence seeds: `63202353`, `63202357`, `63202364`
- `strategy_findings=4`
- `strategy_low_confidence_findings=4`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":4}`
- `strategy_severity_counts={"medium":4}`
- Seed `63202364` has two low-confidence findings.
- `strategy_review_required_findings=0`
- `global_learning_eligible_seeds=null`
- `global_not_learning_eligible_seeds=null`

Inference: because this snapshot has all mandatory gates passing, the high-confidence strategy seed list is likely compatible with global learning in this run. That remains an inference, not a published post-gate contract.

Conclusion: `BV-072` remains open until the wrapper publishes global post-gate learning eligibility and per-seed reasons, or clearly renames current `strategy_*` fields as strategy-audit-only.

## BV-075 result: remains open

Deck provenance evidence:

- `summary.json.learned_deck_opponents=null`
- `summary.json.opponent_deck_provenance=null`
- `summary.json.learned_opponent_source_counts=null`
- `16` per-seed `deck_provenance.json` files exist.
- Across those files: `64` deck rows, `16` `sqlite_deck_cards` rows and `48` `learned_decks` rows.
- Learned opponents have `12` unique refs and `blocker_domain=none` on all `48` rows.
- Learned rows use `source_system=pg_meta_decks`, `source_card_count=100`, `battle_card_count=99`, `cached_metadata_used_for_metrics=false`, and `metrics_basis=runtime_derived_from_resolved_built_deck`.

Observed learned refs:

| Source ref | Name | Appearances |
| --- | --- | ---: |
| `learned_deck:42` | The Emperor of Palamecia #42 (real) | 7 |
| `learned_deck:116` | Tayam, Luminous Enigma #116 (real) | 6 |
| `learned_deck:104` | Kinnan, Bonder Prodigy #104 (real) | 5 |
| `learned_deck:105` | Etali, Primal Conqueror #105 (real) | 5 |
| `learned_deck:58` | Thrasios, Triton Hero #58 (real) | 5 |
| `learned_deck:31` | Sisay, Weatherlight Captain #31 (real) | 4 |
| `learned_deck:83` | Kraum, Ludevic's Opus #83 (real) | 4 |
| `learned_deck:74` | Dargo, the Shipwrecker #74 (real) | 3 |
| `learned_deck:84` | Kinnan, Bonder Prodigy #84 (real) | 3 |
| `learned_deck:25` | Tayam, Luminous Enigma #25 (real) | 2 |
| `learned_deck:54` | Thrasios, Triton Hero #54 (real) | 2 |
| `learned_deck:62` | Rograkh, Son of Rohgahh #62 (real) | 2 |

Conclusion: `BV-075` remains open. Per-seed provenance exists, but the principal result still does not aggregate learned opponents or construction/coherence status.

Task for "Ajustar battle":

- Aggregate learned opponents in `summary.json` by `source_system`, `source_ref`, name and row id when available.
- Include appearances/seeds, `source_card_count`, `battle_card_count`, metrics basis, cached flag, blocker domain and construction/coherence status.
- Add a test that fails when learned opponents appear in `seed_*/deck_provenance.json` but summary-level learned opponent fields remain null.
