# Battle Action Critic

## Summary

- total_actions: 245
- events_total: 541
- event_types_total: 29
- event_contract_class_counts: `{"action_audited": 245, "ignored_with_reason": 11, "strategy_signal": 5, "technical": 280}`
- events_unclassified: 0
- event_types_unclassified: `[]`
- findings: 25
- verdict_counts: `{"low": 25, "ok": 220}`
- technical_events_included: False
- technical_events_mode: default_action_only

## Findings

| Severity | Action | Turn | Player | Event | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- |
| low | action-000007 | 1 | Thrasios, Triton Hero #101 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000014 | 1 | Dargo, the Shipwrecker #74 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000019 | 1 | Yorion, Sky Nomad #38 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000024 | 2 | Lorehold | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000031 | 2 | Thrasios, Triton Hero #101 (real) | commander_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000037 | 2 | Dargo, the Shipwrecker #74 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000049 | 2 | Yorion, Sky Nomad #38 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000056 | 3 | Lorehold | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000063 | 3 | Thrasios, Triton Hero #101 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000066 | 3 | Thrasios, Triton Hero #101 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000077 | 3 | Dargo, the Shipwrecker #74 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000079 | 3 | Dargo, the Shipwrecker #74 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000092 | 3 | Yorion, Sky Nomad #38 (real) | commander_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000104 | 4 | Lorehold | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000114 | 4 | Thrasios, Triton Hero #101 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000126 | 4 | Dargo, the Shipwrecker #74 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000138 | 4 | Yorion, Sky Nomad #38 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000151 | 5 | Thrasios, Triton Hero #101 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000165 | 5 | Dargo, the Shipwrecker #74 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000181 | 5 | Yorion, Sky Nomad #38 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000193 | 6 | Lorehold | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000216 | 6 | Thrasios, Triton Hero #101 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000220 | 6 | Thrasios, Triton Hero #101 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000232 | 6 | Dargo, the Shipwrecker #74 (real) | spell_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |
| low | action-000236 | 6 | Dargo, the Shipwrecker #74 (real) | creature_cast | Action has no matching decision trace. | Emit a decision trace for cast/combat choices. |

## Action Ledger

| Action | Line | Turn | Phase | Player | Event | Label | Verdict | Evidence |
| --- | ---: | ---: | --- | --- | --- | --- | --- | --- |
| action-000001 | 1 | 1 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000002 | 3 | 1 | - | Lorehold | land_played | Inventors' Fair | ok | rule=curated/active; effect=land |
| action-000003 | 13 | 1 | - | Lorehold | turn_end | - | ok | hand=7; board=1; grave=0 |
| action-000004 | 14 | 1 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000005 | 16 | 1 | - | Thrasios, Triton Hero #101 (real) | land_played | Scrubland | ok | rule=curated/verified; effect=land |
| action-000006 | 18 | 1 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Imperial Seal | ok | card=Imperial Seal; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=40->40 |
| action-000007 | 19 | 1 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Imperial Seal | low | rule=curated/verified; effect=tutor |
| action-000008 | 24 | 1 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_resolved | Imperial Seal | ok | rule=curated/verified; effect=tutor; resolved_from_stack=True; destination=graveyard |
| action-000009 | 25 | 1 | - | Thrasios, Triton Hero #101 (real) | tutor_resolved | Imperial Seal | ok | - |
| action-000010 | 34 | 1 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=7; board=1; grave=1 |
| action-000011 | 35 | 1 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000012 | 37 | 1 | - | Dargo, the Shipwrecker #74 (real) | land_played | Sacred Foundry | ok | rule=curated/verified; effect=land |
| action-000013 | 39 | 1 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Stitcher's Supplier | ok | card=Stitcher's Supplier; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=1->0; life=40->40 |
| action-000014 | 40 | 1 | precombat_main | Dargo, the Shipwrecker #74 (real) | creature_cast | Stitcher's Supplier | low | rule=type_line_creature/fact; effect=creature |
| action-000015 | 49 | 1 | - | Dargo, the Shipwrecker #74 (real) | turn_end | - | ok | hand=6; board=2; grave=0 |
| action-000016 | 50 | 1 | - | Yorion, Sky Nomad #38 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000017 | 52 | 1 | - | Yorion, Sky Nomad #38 (real) | land_played | Plains | ok | rule=curated/verified; effect=land |
| action-000018 | 54 | 1 | precombat_main | Yorion, Sky Nomad #38 (real) | cost_paid | Sol Ring | ok | card=Sol Ring; cost={'colored': {}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=1->0; life=40->40 |
| action-000019 | 55 | 1 | precombat_main | Yorion, Sky Nomad #38 (real) | spell_cast | Sol Ring | low | rule=curated/verified; effect=ramp_permanent |
| action-000020 | 64 | 1 | - | Yorion, Sky Nomad #38 (real) | turn_end | - | ok | hand=6; board=2; grave=0 |
| action-000021 | 65 | 2 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000022 | 67 | 2 | - | Lorehold | land_played | Spectator Seating | ok | rule=curated/verified; effect=land |
| action-000023 | 69 | 2 | precombat_main | Lorehold | cost_paid | Land Tax | ok | card=Land Tax; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['noncreature_spell']}; mana=2->1; life=40->40 |
| action-000024 | 70 | 2 | precombat_main | Lorehold | spell_cast | Land Tax | low | rule=curated/verified; effect=passive |
| action-000025 | 75 | 2 | precombat_main | Lorehold | spell_resolved | Land Tax | ok | rule=curated/verified; effect=passive; resolved_from_stack=True; destination=battlefield |
| action-000026 | 80 | 2 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000027 | 86 | 2 | - | Lorehold | turn_end | - | ok | hand=6; board=3; grave=0 |
| action-000028 | 87 | 2 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000029 | 89 | 2 | - | Thrasios, Triton Hero #101 (real) | land_played | Breeding Pool | ok | rule=curated/verified; effect=land |
| action-000030 | 91 | 2 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Thrasios, Triton Hero | ok | card=Thrasios, Triton Hero; cost={'colored': {'blue': 1, 'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=2->0; life=40->40 |
| action-000031 | 92 | 2 | precombat_main | Thrasios, Triton Hero #101 (real) | commander_cast | Thrasios, Triton Hero | low | rule=curated/verified; effect=creature |
| action-000032 | 97 | 2 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000033 | 102 | 2 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=7; board=3; grave=1 |
| action-000034 | 103 | 2 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=6 |
| action-000035 | 105 | 2 | - | Dargo, the Shipwrecker #74 (real) | land_played | Mana Confluence | ok | rule=curated/verified; effect=land |
| action-000036 | 107 | 2 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Cabal Ritual | ok | card=Cabal Ritual; cost={'colored': {'black': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=2->0; life=40->40 |
| action-000037 | 108 | 2 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_cast | Cabal Ritual | low | rule=curated/verified; effect=ramp_ritual |
| action-000038 | 113 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000039 | 114 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000040 | 115 | 2 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000041 | 116 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat | target=Lorehold | ok | - |
| action-000042 | 117 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000043 | 118 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000044 | 119 | 2 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000045 | 124 | 2 | - | Dargo, the Shipwrecker #74 (real) | turn_end | - | ok | hand=5; board=3; grave=1 |
| action-000046 | 125 | 2 | - | Yorion, Sky Nomad #38 (real) | turn_start | - | ok | life=40; hand=6 |
| action-000047 | 127 | 2 | - | Yorion, Sky Nomad #38 (real) | land_played | Azorius Chancery | ok | rule=curated/verified; effect=land |
| action-000048 | 129 | 2 | precombat_main | Yorion, Sky Nomad #38 (real) | cost_paid | Aether Channeler | ok | card=Aether Channeler; cost={'colored': {'blue': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->1; life=40->40 |
| action-000049 | 130 | 2 | precombat_main | Yorion, Sky Nomad #38 (real) | spell_cast | Aether Channeler | low | rule=known_cards_canonical_snapshot/review_only; effect=passive |
| action-000050 | 135 | 2 | precombat_main | Yorion, Sky Nomad #38 (real) | spell_resolved | Aether Channeler | ok | rule=known_cards_canonical_snapshot/review_only; effect=passive; resolved_from_stack=True; destination=battlefield |
| action-000051 | 140 | 2 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000052 | 145 | 2 | - | Yorion, Sky Nomad #38 (real) | turn_end | - | ok | hand=5; board=4; grave=0 |
| action-000053 | 146 | 3 | - | Lorehold | turn_start | - | ok | life=39; hand=6 |
| action-000054 | 148 | 3 | - | Lorehold | land_played | Urza's Saga | ok | rule=curated/active; effect=land |
| action-000055 | 150 | 3 | precombat_main | Lorehold | cost_paid | Victory Chimes | ok | card=Victory Chimes; cost={'colored': {}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=3->0; life=39->39 |
| action-000056 | 151 | 3 | precombat_main | Lorehold | spell_cast | Victory Chimes | low | rule=curated/verified; effect=draw_engine |
| action-000057 | 156 | 3 | precombat_main | Lorehold | spell_resolved | Victory Chimes | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000058 | 161 | 3 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000059 | 168 | 3 | - | Lorehold | turn_end | - | ok | hand=7; board=5; grave=0 |
| action-000060 | 169 | 3 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000061 | 171 | 3 | - | Thrasios, Triton Hero #101 (real) | land_played | Ancient Tomb | ok | rule=curated/verified; effect=land |
| action-000062 | 174 | 3 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Voice of Victory | ok | card=Voice of Victory; cost={'colored': {'white': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->1; life=40->40 |
| action-000063 | 175 | 3 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Voice of Victory | low | rule=curated/verified; effect=silence_opponents |
| action-000064 | 180 | 3 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_resolved | Voice of Victory | ok | rule=curated/verified; effect=silence_opponents; resolved_from_stack=True; destination=battlefield |
| action-000065 | 182 | 3 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Mockingbird | ok | card=Mockingbird; cost={'colored': {'blue': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=1->0; life=40->40 |
| action-000066 | 183 | 3 | precombat_main | Thrasios, Triton Hero #101 (real) | creature_cast | Mockingbird | low | rule=type_line_creature/fact; effect=creature |
| action-000067 | 188 | 3 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000068 | 189 | 3 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000069 | 190 | 3 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000070 | 191 | 3 | - | Thrasios, Triton Hero #101 (real) | combat | target=Lorehold | ok | - |
| action-000071 | 192 | 3 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000072 | 193 | 3 | - | Thrasios, Triton Hero #101 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000073 | 194 | 3 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000074 | 199 | 3 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=5; board=6; grave=1 |
| action-000075 | 200 | 3 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000076 | 203 | 3 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Lotus Petal | ok | card=Lotus Petal; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=2->2; life=40->40 |
| action-000077 | 204 | 3 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_cast | Lotus Petal | low | rule=curated/verified; effect=ramp_ritual |
| action-000078 | 206 | 3 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Esper Sentinel | ok | card=Esper Sentinel; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=3->2; life=40->40 |
| action-000079 | 207 | 3 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_cast | Esper Sentinel | low | rule=curated/verified; effect=draw_engine |
| action-000080 | 212 | 3 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_resolved | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000081 | 217 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000082 | 218 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000083 | 219 | 3 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000084 | 220 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat | target=Lorehold | ok | - |
| action-000085 | 221 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000086 | 222 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000087 | 223 | 3 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000088 | 228 | 3 | - | Dargo, the Shipwrecker #74 (real) | turn_end | - | ok | hand=6; board=4; grave=2 |
| action-000089 | 229 | 3 | - | Yorion, Sky Nomad #38 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000090 | 231 | 3 | - | Yorion, Sky Nomad #38 (real) | land_played | Island | ok | rule=curated/verified; effect=land |
| action-000091 | 233 | 3 | precombat_main | Yorion, Sky Nomad #38 (real) | cost_paid | Yorion, Sky Nomad | ok | card=Yorion, Sky Nomad; cost={'colored': {}, 'generic': 3, 'hybrid': [['white', 'blue'], ['white', 'blue']], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=5->0; life=40->40 |
| action-000092 | 234 | 3 | precombat_main | Yorion, Sky Nomad #38 (real) | commander_cast | Yorion, Sky Nomad | low | rule=type_line_creature/fact; effect=creature |
| action-000093 | 239 | 3 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000094 | 240 | 3 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000095 | 241 | 3 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000096 | 242 | 3 | - | Yorion, Sky Nomad #38 (real) | combat | target=Lorehold | ok | - |
| action-000097 | 243 | 3 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000098 | 244 | 3 | - | Yorion, Sky Nomad #38 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000099 | 245 | 3 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000100 | 250 | 3 | - | Yorion, Sky Nomad #38 (real) | turn_end | - | ok | hand=5; board=6; grave=0 |
| action-000101 | 251 | 4 | - | Lorehold | turn_start | - | ok | life=35; hand=7 |
| action-000102 | 254 | 4 | - | Lorehold | land_played | Scalding Tarn | ok | rule=curated/verified; effect=land |
| action-000103 | 256 | 4 | precombat_main | Lorehold | cost_paid | Gamble | ok | card=Gamble; cost={'colored': {'red': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->3; life=35->35 |
| action-000104 | 257 | 4 | precombat_main | Lorehold | spell_cast | Gamble | low | rule=curated/verified; effect=tutor |
| action-000105 | 258 | 4 | - | Dargo, the Shipwrecker #74 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=0 |
| action-000106 | 263 | 4 | precombat_main | Dargo, the Shipwrecker #74 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000107 | 268 | 4 | precombat_main | Lorehold | spell_resolved | Gamble | ok | rule=curated/verified; effect=tutor; resolved_from_stack=True; destination=graveyard |
| action-000108 | 269 | 4 | - | Lorehold | tutor_resolved | Gamble | ok | - |
| action-000109 | 274 | 4 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000110 | 280 | 4 | - | Lorehold | turn_end | - | ok | hand=7; board=7; grave=2 |
| action-000111 | 281 | 4 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000112 | 283 | 4 | - | Thrasios, Triton Hero #101 (real) | land_played | Verdant Catacombs | ok | rule=curated/verified; effect=land |
| action-000113 | 286 | 4 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Eternal Witness | ok | card=Eternal Witness; cost={'colored': {'green': 2}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->1; life=40->40 |
| action-000114 | 287 | 4 | precombat_main | Thrasios, Triton Hero #101 (real) | creature_cast | Eternal Witness | low | rule=curated/verified; effect=creature |
| action-000115 | 292 | 4 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000116 | 293 | 4 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000117 | 294 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000118 | 295 | 4 | - | Thrasios, Triton Hero #101 (real) | combat | target=Lorehold | ok | - |
| action-000119 | 296 | 4 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000120 | 297 | 4 | - | Thrasios, Triton Hero #101 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000121 | 298 | 4 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000122 | 303 | 4 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=4; board=8; grave=1 |
| action-000123 | 304 | 4 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000124 | 306 | 4 | - | Dargo, the Shipwrecker #74 (real) | land_played | Verdant Catacombs | ok | rule=curated/verified; effect=land |
| action-000125 | 308 | 4 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Magda, Brazen Outlaw | ok | card=Magda, Brazen Outlaw; cost={'colored': {'red': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->1; life=40->40 |
| action-000126 | 309 | 4 | precombat_main | Dargo, the Shipwrecker #74 (real) | creature_cast | Magda, Brazen Outlaw | low | rule=curated/verified; effect=creature |
| action-000127 | 314 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000128 | 315 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000129 | 316 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000130 | 317 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat | target=Lorehold | ok | - |
| action-000131 | 318 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000132 | 319 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000133 | 320 | 4 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000134 | 325 | 4 | - | Dargo, the Shipwrecker #74 (real) | turn_end | - | ok | hand=7; board=5; grave=3 |
| action-000135 | 326 | 4 | - | Yorion, Sky Nomad #38 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000136 | 328 | 4 | - | Yorion, Sky Nomad #38 (real) | land_played | Glacial Fortress | ok | rule=curated/verified; effect=land |
| action-000137 | 330 | 4 | precombat_main | Yorion, Sky Nomad #38 (real) | cost_paid | Glimmerpoint Stag | ok | card=Glimmerpoint Stag; cost={'colored': {'white': 2}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=6->2; life=40->40 |
| action-000138 | 331 | 4 | precombat_main | Yorion, Sky Nomad #38 (real) | creature_cast | Glimmerpoint Stag | low | rule=type_line_creature/fact; effect=creature |
| action-000139 | 336 | 4 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000140 | 337 | 4 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000141 | 338 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000142 | 339 | 4 | - | Yorion, Sky Nomad #38 (real) | combat | target=Lorehold | ok | - |
| action-000143 | 340 | 4 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000144 | 341 | 4 | - | Yorion, Sky Nomad #38 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000145 | 342 | 4 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000146 | 347 | 4 | - | Yorion, Sky Nomad #38 (real) | turn_end | - | ok | hand=4; board=8; grave=0 |
| action-000147 | 348 | 5 | - | Lorehold | turn_start | - | ok | life=25; hand=7 |
| action-000148 | 353 | 5 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=40; hand=4 |
| action-000149 | 355 | 5 | - | Thrasios, Triton Hero #101 (real) | land_played | Polluted Delta | ok | rule=curated/verified; effect=land |
| action-000150 | 358 | 5 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Rhystic Study | ok | card=Rhystic Study; cost={'colored': {'blue': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['noncreature_spell']}; mana=5->2; life=40->40 |
| action-000151 | 359 | 5 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Rhystic Study | low | rule=curated/verified; effect=draw_engine |
| action-000152 | 360 | 5 | - | Dargo, the Shipwrecker #74 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=1 |
| action-000153 | 365 | 5 | precombat_main | Dargo, the Shipwrecker #74 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000154 | 370 | 5 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_resolved | Rhystic Study | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000155 | 375 | 5 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000156 | 376 | 5 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000157 | 377 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000158 | 378 | 5 | - | Thrasios, Triton Hero #101 (real) | combat | target=Lorehold | ok | - |
| action-000159 | 379 | 5 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000160 | 380 | 5 | - | Thrasios, Triton Hero #101 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000161 | 381 | 5 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000162 | 386 | 5 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=5; board=10; grave=1 |
| action-000163 | 387 | 5 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000164 | 390 | 5 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Professional Face-Breaker | ok | card=Professional Face-Breaker; cost={'colored': {'red': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->0; life=40->40 |
| action-000165 | 391 | 5 | precombat_main | Dargo, the Shipwrecker #74 (real) | creature_cast | Professional Face-Breaker | low | rule=curated/verified; effect=creature |
| action-000166 | 396 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000167 | 397 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000168 | 398 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000169 | 399 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat | target=Lorehold | ok | - |
| action-000170 | 400 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000171 | 401 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000172 | 402 | 5 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000173 | 407 | 5 | end_step | Lorehold | end_step_instant | Generous Gift | ok | rule=curated/verified; effect=remove_permanent; target=Thrasios, Triton Hero |
| action-000174 | 408 | 5 | end_step | Lorehold | spell_resolved | Generous Gift | ok | rule=curated/verified; effect=remove_permanent; target=Thrasios, Triton Hero; resolved_from_stack=False; destination=graveyard |
| action-000175 | 409 | 5 | - | Lorehold | removal_resolved | Generous Gift | ok | - |
| action-000176 | 410 | 5 | - | ? | replacement_applied | Thrasios, Triton Hero | ok | card=Thrasios, Triton Hero; affected_player=Thrasios, Triton Hero #101 (real); source=Generous Gift; reason=removal; zone=battlefield->command_zone; value=0->0; replacement_rule_source=commander_replacement_rule |
| action-000177 | 411 | 5 | - | Dargo, the Shipwrecker #74 (real) | turn_end | - | ok | hand=7; board=6; grave=4 |
| action-000178 | 412 | 5 | - | Yorion, Sky Nomad #38 (real) | turn_start | - | ok | life=40; hand=4 |
| action-000179 | 414 | 5 | - | Yorion, Sky Nomad #38 (real) | land_played | Sejiri Refuge | ok | rule=curated/verified; effect=land |
| action-000180 | 416 | 5 | precombat_main | Yorion, Sky Nomad #38 (real) | cost_paid | Mnemonic Wall | ok | card=Mnemonic Wall; cost={'colored': {'blue': 1}, 'generic': 4, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=7->2; life=40->40 |
| action-000181 | 417 | 5 | precombat_main | Yorion, Sky Nomad #38 (real) | creature_cast | Mnemonic Wall | low | rule=type_line_creature/fact; effect=creature |
| action-000182 | 422 | 5 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000183 | 423 | 5 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000184 | 424 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000185 | 425 | 5 | - | Yorion, Sky Nomad #38 (real) | combat | target=Lorehold | ok | - |
| action-000186 | 426 | 5 | - | Yorion, Sky Nomad #38 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000187 | 427 | 5 | - | Yorion, Sky Nomad #38 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000188 | 428 | 5 | - | Yorion, Sky Nomad #38 (real) | combat_step | - | ok | target=-; power=- |
| action-000189 | 433 | 5 | - | Yorion, Sky Nomad #38 (real) | turn_end | - | ok | hand=3; board=10; grave=0 |
| action-000190 | 434 | 6 | - | Lorehold | turn_start | - | ok | life=8; hand=7 |
| action-000191 | 437 | 6 | - | Lorehold | land_played | Hall of Heliod's Generosity | ok | rule=curated/active; effect=land |
| action-000192 | 439 | 6 | precombat_main | Lorehold | cost_paid | The One Ring | ok | card=The One Ring; cost={'colored': {}, 'generic': 4, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=4->0; life=9->9 |
| action-000193 | 440 | 6 | precombat_main | Lorehold | spell_cast | The One Ring | low | rule=curated/verified; effect=draw_engine |
| action-000194 | 441 | 6 | - | Thrasios, Triton Hero #101 (real) | trigger_put_on_stack | Rhystic Study | ok | source=Rhystic Study; trigger=opponent_spell; stack=2 |
| action-000195 | 442 | 6 | - | Dargo, the Shipwrecker #74 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=3 |
| action-000196 | 447 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000197 | 452 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | trigger_resolved | Rhystic Study | ok | - |
| action-000198 | 457 | 6 | precombat_main | Lorehold | spell_resolved | The One Ring | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000199 | 462 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000200 | 463 | 6 | - | Lorehold | combat_step | target=Yorion, Sky Nomad #38 (real) | ok | target=Yorion, Sky Nomad #38 (real); power=- |
| action-000201 | 464 | 6 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000202 | 465 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_step | defender=Thrasios, Triton Hero #101 (real) | ok | target=Thrasios, Triton Hero #101 (real); power=- |
| action-000203 | 466 | 6 | - | Yorion, Sky Nomad #38 (real) | combat_step | defender=Yorion, Sky Nomad #38 (real) | ok | target=Yorion, Sky Nomad #38 (real); power=- |
| action-000204 | 467 | 6 | - | Lorehold | combat | target=Yorion, Sky Nomad #38 (real) | ok | - |
| action-000205 | 468 | 6 | - | Lorehold | combat_step | target=Thrasios, Triton Hero #101 (real) | ok | target=Thrasios, Triton Hero #101 (real); power=- |
| action-000206 | 469 | 6 | - | Lorehold | combat_result | target=Thrasios, Triton Hero #101 (real) | ok | damage=-; target_life=- |
| action-000207 | 470 | 6 | - | Lorehold | combat_step | target=Yorion, Sky Nomad #38 (real) | ok | target=Yorion, Sky Nomad #38 (real); power=- |
| action-000208 | 471 | 6 | - | Lorehold | combat_result | target=Yorion, Sky Nomad #38 (real) | ok | damage=-; target_life=- |
| action-000209 | 472 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000210 | 479 | 6 | end_step | Thrasios, Triton Hero #101 (real) | end_step_instant | Demonic Consultation | ok | rule=curated/verified; effect=tutor |
| action-000211 | 480 | 6 | end_step | Thrasios, Triton Hero #101 (real) | spell_resolved | Demonic Consultation | ok | rule=curated/verified; effect=tutor; resolved_from_stack=False; destination=graveyard |
| action-000212 | 481 | 6 | - | Thrasios, Triton Hero #101 (real) | tutor_resolved | Demonic Consultation | ok | - |
| action-000213 | 482 | 6 | - | Lorehold | turn_end | - | ok | hand=7; board=8; grave=6 |
| action-000214 | 483 | 6 | - | Thrasios, Triton Hero #101 (real) | turn_start | - | ok | life=38; hand=6 |
| action-000215 | 487 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Tataru Taru | ok | card=Tataru Taru; cost={'colored': {'white': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=5->3; life=38->38 |
| action-000216 | 488 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Tataru Taru | low | rule=curated/verified; effect=ramp_engine |
| action-000217 | 489 | 6 | - | Dargo, the Shipwrecker #74 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=4 |
| action-000218 | 494 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000219 | 496 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | cost_paid | Delighted Halfling | ok | card=Delighted Halfling; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->2; life=38->38 |
| action-000220 | 497 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | creature_cast | Delighted Halfling | low | rule=curated/verified; effect=creature |
| action-000221 | 502 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000222 | 503 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000223 | 504 | 6 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000224 | 505 | 6 | - | Thrasios, Triton Hero #101 (real) | combat | target=Lorehold | ok | - |
| action-000225 | 506 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000226 | 507 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000227 | 508 | 6 | - | Thrasios, Triton Hero #101 (real) | combat_step | - | ok | target=-; power=- |
| action-000228 | 513 | 6 | - | Thrasios, Triton Hero #101 (real) | turn_end | - | ok | hand=6; board=12; grave=2 |
| action-000229 | 514 | 6 | - | Dargo, the Shipwrecker #74 (real) | turn_start | - | ok | life=40; hand=9 |
| action-000230 | 516 | 6 | - | Dargo, the Shipwrecker #74 (real) | land_played | Starting Town | ok | rule=curated/verified; effect=land |
| action-000231 | 518 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Sol Ring | ok | card=Sol Ring; cost={'colored': {}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=4->3; life=40->40 |
| action-000232 | 519 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_cast | Sol Ring | low | rule=curated/verified; effect=ramp_permanent |
| action-000233 | 520 | 6 | - | Thrasios, Triton Hero #101 (real) | trigger_put_on_stack | Rhystic Study | ok | source=Rhystic Study; trigger=opponent_spell; stack=5 |
| action-000234 | 525 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | trigger_resolved | Rhystic Study | ok | - |
| action-000235 | 527 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | cost_paid | Mardu Devotee | ok | card=Mardu Devotee; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->3; life=40->40 |
| action-000236 | 528 | 6 | precombat_main | Dargo, the Shipwrecker #74 (real) | creature_cast | Mardu Devotee | low | rule=manual_runtime_waiver/verified; effect=creature |
| action-000237 | 533 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000238 | 534 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000239 | 535 | 6 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000240 | 536 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat | target=Lorehold | ok | - |
| action-000241 | 537 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000242 | 538 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000243 | 539 | 6 | - | Dargo, the Shipwrecker #74 (real) | combat_step | - | ok | target=-; power=- |
| action-000244 | 540 | 6 | - | Lorehold | player_eliminated | life_zero | ok | reason=life_zero |
| action-000245 | 541 | 6 | - | Thrasios, Triton Hero #101 (real) | game_won | elimination | ok | winner=Thrasios, Triton Hero #101 (real) |
