# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T05:55:05.881944+00:00`
- Package ID: `pg553_self_keyword_until_eot_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 43}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 43}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 43}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 43}` |
| battle_execution | `pass` | `{"events": 86, "scenarios": 43}` |

## Battle Execution

```json
{
  "event_count": 86,
  "results": [
    {
      "card_name": "Bastion Mastodon",
      "granted_keywords": [
        "vigilance"
      ],
      "scenario": "Bastion Mastodon activates self keyword ability",
      "source_keywords": [
        "vigilance"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Bladed Sentinel",
      "granted_keywords": [
        "vigilance"
      ],
      "scenario": "Bladed Sentinel activates self keyword ability",
      "source_keywords": [
        "vigilance"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Cabaretti Initiate",
      "granted_keywords": [
        "double_strike"
      ],
      "scenario": "Cabaretti Initiate activates self keyword ability",
      "source_keywords": [
        "double_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Cobalt Golem",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Cobalt Golem activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Disciple of the Old Ways",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Disciple of the Old Ways activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Dukhara Peafowl",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Dukhara Peafowl activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Fallaji Chaindancer",
      "granted_keywords": [
        "double_strike"
      ],
      "scenario": "Fallaji Chaindancer activates self keyword ability",
      "source_keywords": [
        "double_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Goblin Balloon Brigade",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Goblin Balloon Brigade activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Gruul Nodorog",
      "granted_keywords": [
        "menace"
      ],
      "scenario": "Gruul Nodorog activates self keyword ability",
      "source_keywords": [
        "menace"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Gust-Skimmer",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Gust-Skimmer activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Henge Guardian",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Henge Guardian activates self keyword ability",
      "source_keywords": [
        "trample"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Igneous Golem",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Igneous Golem activates self keyword ability",
      "source_keywords": [
        "trample"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Kessig Wolf",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Kessig Wolf activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Killer Whale",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Killer Whale activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Kor Sky Climber",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Kor Sky Climber activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Leaping Master",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Leaping Master activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Llanowar Cavalry",
      "granted_keywords": [
        "vigilance"
      ],
      "scenario": "Llanowar Cavalry activates self keyword ability",
      "source_keywords": [
        "vigilance"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Malachite Golem",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Malachite Golem activates self keyword ability",
      "source_keywords": [
        "trample"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Manta Riders",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Manta Riders activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Mardu Hateblade",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Mardu Hateblade activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Moorland Inquisitor",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Moorland Inquisitor activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Narnam Cobra",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Narnam Cobra activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Noble Panther",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Noble Panther activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Patagia Golem",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Patagia Golem activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Pestilent Wolf",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Pestilent Wolf activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Prakhata Pillar-Bug",
      "granted_keywords": [
        "lifelink"
      ],
      "scenario": "Prakhata Pillar-Bug activates self keyword ability",
      "source_keywords": [
        "lifelink"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Riveteers Initiate",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Riveteers Initiate activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Roofstalker Wight",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Roofstalker Wight activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Saberclaw Golem",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Saberclaw Golem activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Serpentine Kavu",
      "granted_keywords": [
        "haste"
      ],
      "scenario": "Serpentine Kavu activates self keyword ability",
      "source_keywords": [
        "haste"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Skittering Heartstopper",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Skittering Heartstopper activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Steeple Creeper",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Steeple Creeper activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Stonefare Crocodile",
      "granted_keywords": [
        "lifelink"
      ],
      "scenario": "Stonefare Crocodile activates self keyword ability",
      "source_keywords": [
        "lifelink"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Stream Hopper",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Stream Hopper activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Titanium Golem",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Titanium Golem activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Towering Thunderfist",
      "granted_keywords": [
        "vigilance"
      ],
      "scenario": "Towering Thunderfist activates self keyword ability",
      "source_keywords": [
        "vigilance"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Twilight Panther",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Twilight Panther activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Unyielding Krumar",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Unyielding Krumar activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Vectis Silencers",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Vectis Silencers activates self keyword ability",
      "source_keywords": [
        "deathtouch"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Viashino Grappler",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Viashino Grappler activates self keyword ability",
      "source_keywords": [
        "trample"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Weldfast Monitor",
      "granted_keywords": [
        "menace"
      ],
      "scenario": "Weldfast Monitor activates self keyword ability",
      "source_keywords": [
        "menace"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Whiptongue Frog",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Whiptongue Frog activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Wily Bandar",
      "granted_keywords": [
        "indestructible"
      ],
      "scenario": "Wily Bandar activates self keyword ability",
      "source_keywords": [
        "indestructible"
      ],
      "source_tapped": false
    }
  ],
  "scenario_count": 43
}
```
