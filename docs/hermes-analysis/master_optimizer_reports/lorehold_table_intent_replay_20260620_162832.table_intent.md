# Battle Table Intent Audit

- source: `docs/hermes-analysis/master_optimizer_reports/lorehold_table_intent_replay_20260620_162832.events.jsonl`
- target_player: `Lorehold`
- status: `review_required`
- events_total: `1132`
- combat_total: `24`
- table_intent_combat_total: `24`
- table_intent_missing_scores: `0`
- opponent_spell_cast: `6`
- opponent_spell_resolved: `2`
- opponent_creature_cast: `2`
- opponent_commander_cast: `0`
- opponent_cast_illegal: `53`
- opponent_interaction_events: `2`
- opponent_blockers_total: `0`
- target_blockers_total: `0`
- opponent_wins: `0`
- target_wins: `1`

## Findings
- `medium` `opponent_illegal_cast_pressure_high`: Opponent illegal cast attempts are more than 2x legal cast actions.
