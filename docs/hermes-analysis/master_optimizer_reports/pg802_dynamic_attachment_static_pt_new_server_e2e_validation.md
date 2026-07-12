# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T03:00:03.146322+00:00`
- Package ID: `pg802_dynamic_attachment_static_pt_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 17}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 17}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 17}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 17}` |
| battle_execution | `pass` | `{"events": 21, "scenarios": 17}` |

## Battle Execution

```json
{
  "event_count": 21,
  "results": [
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "All That Glitters",
      "moved_to_graveyard": false,
      "scenario": "All That Glitters aura static P/T attaches",
      "target": "E2E Aura Target for All That Glitters",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "power_boost": 4,
        "target_player": "Aura Controller",
        "toughness_boost": 4
      },
      "card_name": "Ancestral Mask",
      "moved_to_graveyard": false,
      "scenario": "Ancestral Mask aura static P/T attaches",
      "target": "E2E Aura Target for Ancestral Mask",
      "target_owner": "controller",
      "target_power": 6,
      "target_toughness": 6
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 2,
        "toughness_boost": 2
      },
      "card_name": "Blackblade Reforged",
      "scenario": "Blackblade Reforged equipment static P/T attaches",
      "target": "E2E Equipment Target for Blackblade Reforged",
      "target_power": 4,
      "target_toughness": 4,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Blessing of the Nephilim",
      "moved_to_graveyard": false,
      "scenario": "Blessing of the Nephilim aura static P/T attaches",
      "target": "E2E Aura Target for Blessing of the Nephilim",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 3,
        "toughness_boost": 0
      },
      "card_name": "Civic Saber",
      "scenario": "Civic Saber equipment static P/T attaches",
      "target": "E2E Equipment Target for Civic Saber",
      "target_power": 5,
      "target_toughness": 2,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Empyrial Armor",
      "moved_to_graveyard": false,
      "scenario": "Empyrial Armor aura static P/T attaches",
      "target": "E2E Aura Target for Empyrial Armor",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 3,
        "toughness_boost": 3
      },
      "card_name": "Empyrial Plate",
      "scenario": "Empyrial Plate equipment static P/T attaches",
      "target": "E2E Equipment Target for Empyrial Plate",
      "target_power": 5,
      "target_toughness": 5,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "grants": [
          "vigilance",
          "menace"
        ],
        "power_boost": 2,
        "toughness_boost": 0
      },
      "card_name": "Glaive of the Guildpact",
      "scenario": "Glaive of the Guildpact equipment static P/T attaches",
      "target": "E2E Equipment Target for Glaive of the Guildpact",
      "target_power": 4,
      "target_toughness": 2,
      "validated_keywords": [
        "menace",
        "vigilance"
      ]
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 2,
        "toughness_boost": 0
      },
      "card_name": "Golem-Skin Gauntlets",
      "scenario": "Golem-Skin Gauntlets equipment static P/T attaches",
      "target": "E2E Equipment Target for Golem-Skin Gauntlets",
      "target_power": 4,
      "target_toughness": 2,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 0
      },
      "card_name": "Granite Grip",
      "moved_to_graveyard": false,
      "scenario": "Granite Grip aura static P/T attaches",
      "target": "E2E Aura Target for Granite Grip",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 2,
        "toughness_boost": 2
      },
      "card_name": "Helm of the Gods",
      "scenario": "Helm of the Gods equipment static P/T attaches",
      "target": "E2E Equipment Target for Helm of the Gods",
      "target_power": 4,
      "target_toughness": 4,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -3
      },
      "card_name": "Kagemaro's Clutch",
      "moved_to_graveyard": true,
      "scenario": "Kagemaro's Clutch aura static P/T attaches",
      "target": "E2E Aura Target for Kagemaro's Clutch",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": -1
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 3,
        "toughness_boost": 3
      },
      "card_name": "Manaforce Mace",
      "scenario": "Manaforce Mace equipment static P/T attaches",
      "target": "E2E Equipment Target for Manaforce Mace",
      "target_power": 5,
      "target_toughness": 5,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 2,
        "toughness_boost": 2
      },
      "card_name": "Nightmare Lash",
      "scenario": "Nightmare Lash equipment static P/T attaches",
      "target": "E2E Equipment Target for Nightmare Lash",
      "target_power": 4,
      "target_toughness": 4,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 3,
        "toughness_boost": 3
      },
      "card_name": "Pennon Blade",
      "scenario": "Pennon Blade equipment static P/T attaches",
      "target": "E2E Equipment Target for Pennon Blade",
      "target_power": 5,
      "target_toughness": 5,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Quag Sickness",
      "moved_to_graveyard": true,
      "scenario": "Quag Sickness aura static P/T attaches",
      "target": "E2E Aura Target for Quag Sickness",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 0
    },
    {
      "attached_event": {
        "grants": [
          "menace"
        ],
        "power_boost": 4,
        "toughness_boost": 0
      },
      "card_name": "Ravager's Mace",
      "scenario": "Ravager's Mace equipment static P/T attaches",
      "target": "E2E Equipment Target for Ravager's Mace",
      "target_power": 6,
      "target_toughness": 2,
      "validated_keywords": [
        "menace"
      ]
    }
  ],
  "scenario_count": 17
}
```
