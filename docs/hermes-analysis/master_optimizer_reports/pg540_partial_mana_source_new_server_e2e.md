# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T01:14:03.824421+00:00`
- Package ID: `pg540_partial_mana_source_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 143}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 143}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 143}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 143}` |
| battle_execution | `pass` | `{"events": 148, "scenarios": 143}` |

## Battle Execution

```json
{
  "event_count": 148,
  "results": [
    {
      "available_mana": 1,
      "card_name": "Aetheric Amplifier",
      "conditional_mana": 1,
      "scenario": "Aetheric Amplifier refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Agility Bobblehead",
      "conditional_mana": 1,
      "scenario": "Agility Bobblehead refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ancient Cornucopia",
      "conditional_mana": 1,
      "scenario": "Ancient Cornucopia refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Arc Reactor",
      "conditional_mana": 0,
      "scenario": "Arc Reactor refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 2,
      "card_name": "Arixmethes, Slumbering Isle",
      "conditional_mana": 0,
      "scenario": "Arixmethes, Slumbering Isle refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Armored Scrapgorger",
      "conditional_mana": 1,
      "scenario": "Armored Scrapgorger refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Atarka Monument",
      "conditional_mana": 1,
      "scenario": "Atarka Monument refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Azorius Keyrune",
      "conditional_mana": 1,
      "scenario": "Azorius Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Bandit's Haul",
      "conditional_mana": 1,
      "scenario": "Bandit's Haul refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Bonder's Ornament",
      "conditional_mana": 1,
      "scenario": "Bonder's Ornament refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Boros Keyrune",
      "conditional_mana": 1,
      "scenario": "Boros Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Bounty Board",
      "conditional_mana": 1,
      "scenario": "Bounty Board refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Bronze Walrus",
      "conditional_mana": 1,
      "scenario": "Bronze Walrus refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Bugenhagen, Wise Elder",
      "conditional_mana": 1,
      "scenario": "Bugenhagen, Wise Elder refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 3,
      "card_name": "Canopy Tactician",
      "conditional_mana": 0,
      "scenario": "Canopy Tactician refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Centaur Nurturer",
      "conditional_mana": 1,
      "scenario": "Centaur Nurturer refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ceta Disciple",
      "conditional_mana": 1,
      "scenario": "Ceta Disciple refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Chronatog Totem",
      "conditional_mana": 0,
      "scenario": "Chronatog Totem refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Crossroads Candleguide",
      "conditional_mana": 1,
      "scenario": "Crossroads Candleguide refreshes modeled mana source",
      "sources": 3,
      "tapped": false
    },
    {
      "available_mana": 1,
      "card_name": "Crystal Skull, Isu Spyglass",
      "conditional_mana": 0,
      "scenario": "Crystal Skull, Isu Spyglass refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Cultivator's Caravan",
      "conditional_mana": 1,
      "scenario": "Cultivator's Caravan refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dawnhart Rejuvenator",
      "conditional_mana": 1,
      "scenario": "Dawnhart Rejuvenator refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Deathcap Cultivator",
      "conditional_mana": 1,
      "scenario": "Deathcap Cultivator refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Decanter of Endless Water",
      "conditional_mana": 1,
      "scenario": "Decanter of Endless Water refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dimir Keyrune",
      "conditional_mana": 1,
      "scenario": "Dimir Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dragon's Hoard",
      "conditional_mana": 1,
      "scenario": "Dragon's Hoard refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dragonstorm Globe",
      "conditional_mana": 1,
      "scenario": "Dragonstorm Globe refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dromoka Monument",
      "conditional_mana": 1,
      "scenario": "Dromoka Monument refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Drover of the Mighty",
      "conditional_mana": 1,
      "scenario": "Drover of the Mighty refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Drumhunter",
      "conditional_mana": 0,
      "scenario": "Drumhunter refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Dungeon Map",
      "conditional_mana": 0,
      "scenario": "Dungeon Map refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Ebony Fly",
      "conditional_mana": 0,
      "scenario": "Ebony Fly refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 3,
      "card_name": "Elvish Aberration",
      "conditional_mana": 0,
      "scenario": "Elvish Aberration refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Elvish Harbinger",
      "conditional_mana": 1,
      "scenario": "Elvish Harbinger refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Endurance Bobblehead",
      "conditional_mana": 1,
      "scenario": "Endurance Bobblehead refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Exuberant Firestoker",
      "conditional_mana": 0,
      "scenario": "Exuberant Firestoker refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Eye of Ojer Taq // Apex Observatory",
      "conditional_mana": 1,
      "scenario": "Eye of Ojer Taq // Apex Observatory refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Fieldmist Borderpost",
      "conditional_mana": 0,
      "scenario": "Fieldmist Borderpost refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Firdoch Core",
      "conditional_mana": 1,
      "scenario": "Firdoch Core refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Firewild Borderpost",
      "conditional_mana": 0,
      "scenario": "Firewild Borderpost refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Foriysian Totem",
      "conditional_mana": 0,
      "scenario": "Foriysian Totem refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Fountain of Ichor",
      "conditional_mana": 1,
      "scenario": "Fountain of Ichor refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Frog Butler",
      "conditional_mana": 1,
      "scenario": "Frog Butler refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Gatewatch Beacon",
      "conditional_mana": 0,
      "scenario": "Gatewatch Beacon refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Golgari Keyrune",
      "conditional_mana": 1,
      "scenario": "Golgari Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Gruul Keyrune",
      "conditional_mana": 1,
      "scenario": "Gruul Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Guardian Idol",
      "conditional_mana": 0,
      "scenario": "Guardian Idol refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Guy in the Chair",
      "conditional_mana": 1,
      "scenario": "Guy in the Chair refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Hardbristle Bandit",
      "conditional_mana": 1,
      "scenario": "Hardbristle Bandit refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Hierophant's Chalice",
      "conditional_mana": 0,
      "scenario": "Hierophant's Chalice refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Honor-Worn Shaku",
      "conditional_mana": 0,
      "scenario": "Honor-Worn Shaku refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Honored Heirloom",
      "conditional_mana": 1,
      "scenario": "Honored Heirloom refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Indatha Crystal",
      "conditional_mana": 1,
      "scenario": "Indatha Crystal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Inherited Envelope",
      "conditional_mana": 1,
      "scenario": "Inherited Envelope refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Intrepid Paleontologist",
      "conditional_mana": 1,
      "scenario": "Intrepid Paleontologist refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ketria Crystal",
      "conditional_mana": 1,
      "scenario": "Ketria Crystal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Kolaghan Monument",
      "conditional_mana": 1,
      "scenario": "Kolaghan Monument refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Lantern of Revealing",
      "conditional_mana": 1,
      "scenario": "Lantern of Revealing refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Laser Screwdriver",
      "conditional_mana": 1,
      "scenario": "Laser Screwdriver refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 2,
      "card_name": "Lavabrink Floodgates",
      "conditional_mana": 0,
      "scenario": "Lavabrink Floodgates refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Llanowar Loamspeaker",
      "conditional_mana": 1,
      "scenario": "Llanowar Loamspeaker refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Lullmage's Familiar",
      "conditional_mana": 1,
      "scenario": "Lullmage's Familiar refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Magnifying Glass",
      "conditional_mana": 0,
      "scenario": "Magnifying Glass refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Magus of the Library",
      "conditional_mana": 0,
      "scenario": "Magus of the Library refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Mana Geode",
      "conditional_mana": 1,
      "scenario": "Mana Geode refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Meteorite",
      "conditional_mana": 1,
      "scenario": "Meteorite refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Midnight Clock",
      "conditional_mana": 0,
      "scenario": "Midnight Clock refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Misleading Signpost",
      "conditional_mana": 0,
      "scenario": "Misleading Signpost refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Mistvein Borderpost",
      "conditional_mana": 0,
      "scenario": "Mistvein Borderpost refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Model of Unity",
      "conditional_mana": 1,
      "scenario": "Model of Unity refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Mox Tantalite",
      "conditional_mana": 1,
      "scenario": "Mox Tantalite refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Mystic Skull // Mystic Monstrosity",
      "conditional_mana": 1,
      "scenario": "Mystic Skull // Mystic Monstrosity refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Necra Disciple",
      "conditional_mana": 1,
      "scenario": "Necra Disciple refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Oasis Gardener",
      "conditional_mana": 1,
      "scenario": "Oasis Gardener refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ojutai Monument",
      "conditional_mana": 1,
      "scenario": "Ojutai Monument refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Orzhov Keyrune",
      "conditional_mana": 1,
      "scenario": "Orzhov Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Paradise Druid",
      "conditional_mana": 1,
      "scenario": "Paradise Druid refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Patchwork Banner",
      "conditional_mana": 1,
      "scenario": "Patchwork Banner refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Patriar's Seal",
      "conditional_mana": 1,
      "scenario": "Patriar's Seal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Perception Bobblehead",
      "conditional_mana": 1,
      "scenario": "Perception Bobblehead refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Phial of Galadriel",
      "conditional_mana": 1,
      "scenario": "Phial of Galadriel refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Phyrexian Atlas",
      "conditional_mana": 1,
      "scenario": "Phyrexian Atlas refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Phyrexian Totem",
      "conditional_mana": 0,
      "scenario": "Phyrexian Totem refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Planar Atlas",
      "conditional_mana": 0,
      "scenario": "Planar Atlas refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Poison Dart Frog",
      "conditional_mana": 1,
      "scenario": "Poison Dart Frog refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Potioner's Trove",
      "conditional_mana": 1,
      "scenario": "Potioner's Trove refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Prize Pig",
      "conditional_mana": 1,
      "scenario": "Prize Pig refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Progenitor's Icon",
      "conditional_mana": 1,
      "scenario": "Progenitor's Icon refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Radha, Heir to Keld",
      "conditional_mana": 0,
      "scenario": "Radha, Heir to Keld refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Rakdos Keyrune",
      "conditional_mana": 1,
      "scenario": "Rakdos Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Rattleclaw Mystic",
      "conditional_mana": 1,
      "scenario": "Rattleclaw Mystic refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Raugrin Crystal",
      "conditional_mana": 1,
      "scenario": "Raugrin Crystal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Reclusive Taxidermist",
      "conditional_mana": 1,
      "scenario": "Reclusive Taxidermist refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Rift Sower",
      "conditional_mana": 1,
      "scenario": "Rift Sower refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ruby, Daring Tracker",
      "conditional_mana": 1,
      "scenario": "Ruby, Daring Tracker refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Runadi, Behemoth Caller",
      "conditional_mana": 0,
      "scenario": "Runadi, Behemoth Caller refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Savai Crystal",
      "conditional_mana": 1,
      "scenario": "Savai Crystal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Scorned Villager // Moonscarred Werewolf",
      "conditional_mana": 0,
      "scenario": "Scorned Villager // Moonscarred Werewolf refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Scuttlemutt",
      "conditional_mana": 1,
      "scenario": "Scuttlemutt refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Seer's Lantern",
      "conditional_mana": 0,
      "scenario": "Seer's Lantern refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Selesnya Keyrune",
      "conditional_mana": 1,
      "scenario": "Selesnya Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Serum Powder",
      "conditional_mana": 0,
      "scenario": "Serum Powder refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Silumgar Monument",
      "conditional_mana": 1,
      "scenario": "Silumgar Monument refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Simic Keyrune",
      "conditional_mana": 1,
      "scenario": "Simic Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Skull Prophet",
      "conditional_mana": 1,
      "scenario": "Skull Prophet refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Skyclave Relic",
      "conditional_mana": 1,
      "scenario": "Skyclave Relic refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 2,
      "card_name": "Snapping Voidcraw",
      "conditional_mana": 0,
      "scenario": "Snapping Voidcraw refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 2,
      "card_name": "Sol Talisman",
      "conditional_mana": 0,
      "scenario": "Sol Talisman refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Sonic Screwdriver",
      "conditional_mana": 1,
      "scenario": "Sonic Screwdriver refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Spider Manifestation",
      "conditional_mana": 1,
      "scenario": "Spider Manifestation refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Spinning Wheel",
      "conditional_mana": 1,
      "scenario": "Spinning Wheel refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Starnheim Memento",
      "conditional_mana": 0,
      "scenario": "Starnheim Memento refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Stonework Packbeast",
      "conditional_mana": 1,
      "scenario": "Stonework Packbeast refreshes modeled mana source",
      "sources": 3,
      "tapped": false
    },
    {
      "available_mana": 1,
      "card_name": "Strength Bobblehead",
      "conditional_mana": 1,
      "scenario": "Strength Bobblehead refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Sunbird Standard // Sunbird Effigy",
      "conditional_mana": 1,
      "scenario": "Sunbird Standard // Sunbird Effigy refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Sunseed Nurturer",
      "conditional_mana": 0,
      "scenario": "Sunseed Nurturer refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Tender Wildguide",
      "conditional_mana": 1,
      "scenario": "Tender Wildguide refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "The Celestus",
      "conditional_mana": 1,
      "scenario": "The Celestus refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "The Irencrag",
      "conditional_mana": 0,
      "scenario": "The Irencrag refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "The Lion-Turtle",
      "conditional_mana": 1,
      "scenario": "The Lion-Turtle refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Thunder Totem",
      "conditional_mana": 0,
      "scenario": "Thunder Totem refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ticket Turbotubes",
      "conditional_mana": 1,
      "scenario": "Ticket Turbotubes refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Tome of the Guildpact",
      "conditional_mana": 1,
      "scenario": "Tome of the Guildpact refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Torgal, A Fine Hound",
      "conditional_mana": 1,
      "scenario": "Torgal, A Fine Hound refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Trailtracker Scout",
      "conditional_mana": 1,
      "scenario": "Trailtracker Scout refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Tunnel Tipster",
      "conditional_mana": 0,
      "scenario": "Tunnel Tipster refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Ulvenwald Captive // Ulvenwald Abomination",
      "conditional_mana": 0,
      "scenario": "Ulvenwald Captive // Ulvenwald Abomination refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Veinfire Borderpost",
      "conditional_mana": 0,
      "scenario": "Veinfire Borderpost refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Veloheart Bike",
      "conditional_mana": 1,
      "scenario": "Veloheart Bike refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Vessel of Endless Rest",
      "conditional_mana": 1,
      "scenario": "Vessel of Endless Rest refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Visage of Bolas",
      "conditional_mana": 1,
      "scenario": "Visage of Bolas refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Wand of the Worldsoul",
      "conditional_mana": 0,
      "scenario": "Wand of the Worldsoul refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Wandertale Mentor",
      "conditional_mana": 1,
      "scenario": "Wandertale Mentor refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Warden of the Wall",
      "conditional_mana": 0,
      "scenario": "Warden of the Wall refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Weatherseed Totem",
      "conditional_mana": 0,
      "scenario": "Weatherseed Totem refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Weaver of Blossoms // Blossom-Clad Werewolf",
      "conditional_mana": 1,
      "scenario": "Weaver of Blossoms // Blossom-Clad Werewolf refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Werebear",
      "conditional_mana": 0,
      "scenario": "Werebear refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "White Auracite",
      "conditional_mana": 0,
      "scenario": "White Auracite refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 0,
      "card_name": "Wildfield Borderpost",
      "conditional_mana": 0,
      "scenario": "Wildfield Borderpost refreshes modeled mana source",
      "sources": 0,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Wose Pathfinder",
      "conditional_mana": 1,
      "scenario": "Wose Pathfinder refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Zagoth Crystal",
      "conditional_mana": 1,
      "scenario": "Zagoth Crystal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Zhur-Taa Druid",
      "conditional_mana": 0,
      "scenario": "Zhur-Taa Druid refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Zookeeper Mechan",
      "conditional_mana": 0,
      "scenario": "Zookeeper Mechan refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    }
  ],
  "scenario_count": 143
}
```
