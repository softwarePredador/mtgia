# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T23:37:33.941624+00:00`
- Package ID: `pg677_counter_unless_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Disrupt",
      "cards_drawn": 1,
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": null,
      "counter_unless_pays_count": null,
      "counter_unless_pays_generic": 1,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Disrupt counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Runeboggle",
      "cards_drawn": 1,
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": null,
      "counter_unless_pays_count": null,
      "counter_unless_pays_generic": 1,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Runeboggle counters unless tax is paid",
      "target": "Counter Target Fixture"
    }
  ],
  "scenario_count": 2
}
```
