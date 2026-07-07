# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T06:37:34.869367+00:00`
- Package ID: `pg598_dynamic_counter_unless_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 7}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 7}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 7}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 7}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Clash of Wills",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "x_value",
      "counter_unless_pays_count": 3,
      "counter_unless_pays_generic": 3,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Clash of Wills counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Concerted Defense",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "party_count",
      "counter_unless_pays_count": 4,
      "counter_unless_pays_generic": 5,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Concerted Defense counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Evasive Action",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "domain_basic_land_types",
      "counter_unless_pays_count": 3,
      "counter_unless_pays_generic": 3,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Evasive Action counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Ixidor's Will",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "battlefield_subtype_count",
      "counter_unless_pays_count": 2,
      "counter_unless_pays_generic": 4,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Ixidor's Will counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Spell Stutter",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "controlled_subtype_count",
      "counter_unless_pays_count": 2,
      "counter_unless_pays_generic": 4,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Spell Stutter counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Syncopate",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "x_value",
      "counter_unless_pays_count": 3,
      "counter_unless_pays_generic": 3,
      "countered": true,
      "countered_spell_to_exile": true,
      "scenario": "Syncopate counters unless tax is paid",
      "target": "Counter Target Fixture"
    },
    {
      "card_name": "Thassa's Rebuff",
      "counter_tax_paid": false,
      "counter_unless_pays_amount_source": "devotion_to_blue",
      "counter_unless_pays_count": 3,
      "counter_unless_pays_generic": 3,
      "countered": true,
      "countered_spell_to_exile": false,
      "scenario": "Thassa's Rebuff counters unless tax is paid",
      "target": "Counter Target Fixture"
    }
  ],
  "scenario_count": 7
}
```
