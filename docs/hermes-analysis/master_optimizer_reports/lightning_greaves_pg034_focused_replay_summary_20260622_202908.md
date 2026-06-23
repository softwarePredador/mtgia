# PG034 Lightning Greaves Focused Replay Summary

- Scenario: controller resolves Lightning Greaves with one creature on battlefield.
- Source rule: `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac`.
- Oracle hash: `4a4c71d3cc58637cf00a3d7fe2331353`.
- Runtime result: `equipment_attached` grants haste and shroud to Target Creature.
- Negative proof: Target Creature did not gain indestructible.
- Event proof: `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl`.
- Caveat: current battle runtime models Lightning Greaves as `auto_attach_best_creature_on_resolution`; it does not model full Equipment attach/retarget timing.
