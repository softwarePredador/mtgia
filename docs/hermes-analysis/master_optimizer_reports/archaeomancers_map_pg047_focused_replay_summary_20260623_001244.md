# PG047 Archaeomancer's Map Focused Replay Summary

Generated: 2026-06-23T00:16:58.711578+00:00

## Scope
- Card: `Archaeomancer's Map`
- SQLite cache: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Logical rule key: `battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e`
- Oracle hash: `22b82ca6bbef42371227bc38a9a546b5`
- Model scope: `basic_plains_etb_plus_opponent_land_catchup_v2`

## Scenario
1. Resolved Archaeomancer's Map using the synced SQLite rule and tutored up to two basic Plains cards to hand.
2. Resolved the opponent-land catch-up trigger while the active land player controlled more lands than the Map controller.
3. Attempted the same trigger with equal land counts and confirmed it was skipped.

## Results
- ETB found cards: `['Plains', 'Plains']`.
- Library after ETB: `['Mountain']`.
- Catch-up trigger put land: `Mountain`.
- Catch-up trigger land counts: active `3`, controller `1`.
- Equal-land skip reason: `opponent_does_not_control_more_lands`.
- Replay events: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_events_20260623_001244.jsonl`.
- Decision trace: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_pg047_focused_decision_trace_20260623_001244.jsonl` (`0` rows; this direct trigger scenario does not invoke strategic decisions).

## Checks
- sqlite_rule_key_loaded: PASS
- sqlite_oracle_hash_loaded: PASS
- spell_resolved_uses_pg047_key: PASS
- etb_tutored_two_basic_plains: PASS
- etb_tutor_uses_pg047_key: PASS
- map_stayed_on_battlefield: PASS
- catchup_trigger_put_land_from_hand: PASS
- catchup_trigger_uses_pg047_key: PASS
- catchup_trigger_land_counts_prove_behind: PASS
- equal_land_trigger_skipped: PASS
- skip_trigger_preserved_hand: PASS
- skip_trigger_uses_pg047_key: PASS
