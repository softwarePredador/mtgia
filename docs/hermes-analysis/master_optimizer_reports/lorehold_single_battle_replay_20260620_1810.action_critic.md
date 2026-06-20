# Battle Action Critic

## Summary

- total_actions: 458
- events_total: 1139
- event_types_total: 38
- event_contract_class_counts: `{"action_audited": 458, "ignored_with_reason": 53, "renderer_only": 1, "strategy_signal": 10, "technical": 617}`
- events_unclassified: 0
- event_types_unclassified: `[]`
- findings: 0
- verdict_counts: `{"ok": 458}`
- technical_events_included: False
- technical_events_mode: default_action_only

## Findings

- No action findings.

## Action Ledger

| Action | Line | Turn | Phase | Player | Event | Label | Verdict | Evidence |
| --- | ---: | ---: | --- | --- | --- | --- | --- | --- |
| action-000001 | 1 | 1 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000002 | 3 | 1 | - | Lorehold | land_played | Spectator Seating | ok | rule=curated/verified; effect=land |
| action-000003 | 16 | 1 | - | Lorehold | turn_end | - | ok | hand=7; board=1; grave=0 |
| action-000004 | 17 | 1 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000005 | 19 | 1 | - | Rograkh, Son of Rohgahh #119 (real) | land_played | Boseiju, Who Endures | ok | rule=curated/verified; effect=land |
| action-000006 | 23 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | cost_paid | Mox Diamond | ok | card=Mox Diamond; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=1->1; life=40->40 |
| action-000007 | 24 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | spell_cast | Mox Diamond | ok | rule=curated/verified; effect=ramp_permanent; decision=decision-000009 |
| action-000008 | 29 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | cost_paid | Wild Growth | ok | card=Wild Growth; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['noncreature_spell']}; mana=2->1; life=40->40 |
| action-000009 | 30 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | spell_cast | Wild Growth | ok | rule=curated/verified; effect=ramp_permanent; decision=decision-000010 |
| action-000010 | 35 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | cost_paid | Training Grounds | ok | card=Training Grounds; cost={'colored': {'blue': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['noncreature_spell']}; mana=2->1; life=40->40 |
| action-000011 | 36 | 1 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | spell_cast | Training Grounds | ok | rule=curated/verified; effect=ramp_engine; decision=decision-000011 |
| action-000012 | 43 | 1 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=3; board=0; grave=5 |
| action-000013 | 44 | 1 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000014 | 46 | 1 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Watery Grave | ok | rule=curated/verified; effect=land |
| action-000015 | 50 | 1 | precombat_main | Y'shtola, Night's Blessed #70 (real) | cost_paid | Esper Sentinel | ok | card=Esper Sentinel; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=1->0; life=40->40 |
| action-000016 | 51 | 1 | precombat_main | Y'shtola, Night's Blessed #70 (real) | spell_cast | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; decision=decision-000013 |
| action-000017 | 56 | 1 | precombat_main | Y'shtola, Night's Blessed #70 (real) | spell_resolved | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000018 | 65 | 1 | - | Y'shtola, Night's Blessed #70 (real) | turn_end | - | ok | hand=7; board=1; grave=2 |
| action-000019 | 66 | 1 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000020 | 68 | 1 | - | The Gitrog Monster #78 (real) | land_played | Boseiju, Who Endures | ok | rule=curated/verified; effect=land |
| action-000021 | 75 | 2 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000022 | 77 | 2 | - | Lorehold | land_played | Sunbillow Verge | ok | rule=curated/verified; effect=land |
| action-000023 | 81 | 2 | precombat_main | Lorehold | cost_paid | Lightning Greaves | ok | card=Lightning Greaves; cost={'colored': {}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=2->0; life=40->40 |
| action-000024 | 82 | 2 | precombat_main | Lorehold | spell_cast | Lightning Greaves | ok | rule=curated/verified; effect=equipment_haste_shroud; decision=decision-000017 |
| action-000025 | 83 | 2 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=0 |
| action-000026 | 88 | 2 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000027 | 93 | 2 | precombat_main | Lorehold | spell_resolved | Lightning Greaves | ok | rule=curated/verified; effect=equipment_haste_shroud; resolved_from_stack=True; destination=battlefield |
| action-000028 | 99 | 2 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000029 | 104 | 2 | - | Lorehold | turn_end | - | ok | hand=6; board=3; grave=0 |
| action-000030 | 105 | 2 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=40; hand=3 |
| action-000031 | 107 | 2 | - | Rograkh, Son of Rohgahh #119 (real) | land_played | Talon Gates of Madara | ok | rule=curated/verified; effect=land |
| action-000032 | 114 | 2 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=40; hand=8 |
| action-000033 | 116 | 2 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Ancient Tomb | ok | rule=curated/verified; effect=land |
| action-000034 | 124 | 2 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000035 | 126 | 2 | - | The Gitrog Monster #78 (real) | land_played | Forest | ok | rule=curated/verified; effect=land |
| action-000036 | 130 | 2 | precombat_main | The Gitrog Monster #78 (real) | cost_paid | Delighted Halfling | ok | card=Delighted Halfling; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=1->0; life=40->40 |
| action-000037 | 131 | 2 | precombat_main | The Gitrog Monster #78 (real) | creature_cast | Delighted Halfling | ok | rule=curated/verified; effect=creature; decision=decision-000022 |
| action-000038 | 136 | 2 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000039 | 141 | 2 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=6; board=1; grave=2 |
| action-000040 | 142 | 3 | - | Lorehold | turn_start | - | ok | life=40; hand=6 |
| action-000041 | 144 | 3 | - | Lorehold | land_played | Bloodstained Mire | ok | rule=curated/verified; effect=land |
| action-000042 | 148 | 3 | precombat_main | Lorehold | cost_paid | Scroll Rack | ok | card=Scroll Rack; cost={'colored': {}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=3->1; life=40->40 |
| action-000043 | 149 | 3 | precombat_main | Lorehold | spell_cast | Scroll Rack | ok | rule=curated/active; effect=topdeck_manipulation; decision=decision-000025 |
| action-000044 | 150 | 3 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=1 |
| action-000045 | 155 | 3 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000046 | 160 | 3 | precombat_main | Lorehold | spell_resolved | Scroll Rack | ok | rule=curated/active; effect=topdeck_manipulation; resolved_from_stack=True; destination=battlefield |
| action-000047 | 167 | 3 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000048 | 174 | 3 | - | Lorehold | turn_end | - | ok | hand=6; board=5; grave=0 |
| action-000049 | 175 | 3 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=40; hand=3 |
| action-000050 | 177 | 3 | - | Rograkh, Son of Rohgahh #119 (real) | land_played | Prismatic Vista | ok | rule=curated/verified; effect=land |
| action-000051 | 184 | 3 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=40; hand=9 |
| action-000052 | 186 | 3 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Flooded Strand | ok | rule=curated/verified; effect=land |
| action-000053 | 193 | 3 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=40; hand=6 |
| action-000054 | 195 | 3 | - | The Gitrog Monster #78 (real) | land_played | Llanowar Wastes | ok | rule=curated/verified; effect=land |
| action-000055 | 199 | 3 | precombat_main | The Gitrog Monster #78 (real) | cost_paid | Carpet of Flowers | ok | card=Carpet of Flowers; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['noncreature_spell']}; mana=2->1; life=40->40 |
| action-000056 | 200 | 3 | precombat_main | The Gitrog Monster #78 (real) | spell_cast | Carpet of Flowers | ok | rule=curated/verified; effect=ramp_engine; decision=decision-000030 |
| action-000057 | 201 | 3 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=2 |
| action-000058 | 206 | 3 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000059 | 213 | 3 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000060 | 214 | 3 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000061 | 215 | 3 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000062 | 216 | 3 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000063 | 217 | 3 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000064 | 218 | 3 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000065 | 219 | 3 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000066 | 226 | 3 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=5; board=1; grave=4 |
| action-000067 | 227 | 4 | - | Lorehold | turn_start | - | ok | life=40; hand=6 |
| action-000068 | 229 | 4 | - | Lorehold | land_played | Ancient Den | ok | rule=curated/verified; effect=land |
| action-000069 | 233 | 4 | precombat_main | Lorehold | cost_paid | Boros Charm | ok | card=Boros Charm; cost={'colored': {'red': 1, 'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->2; life=40->40 |
| action-000070 | 234 | 4 | precombat_main | Lorehold | spell_cast | Boros Charm | ok | rule=curated/verified; effect=modal_boros_charm; decision=decision-000034 |
| action-000071 | 235 | 4 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=3 |
| action-000072 | 240 | 4 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000073 | 245 | 4 | precombat_main | Lorehold | spell_resolved | Boros Charm | ok | rule=curated/verified; effect=modal_boros_charm; resolved_from_stack=True; destination=graveyard |
| action-000074 | 252 | 4 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000075 | 259 | 4 | - | Lorehold | turn_end | - | ok | hand=5; board=6; grave=1 |
| action-000076 | 260 | 4 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=40; hand=3 |
| action-000077 | 266 | 4 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000078 | 271 | 4 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=4; board=0; grave=7 |
| action-000079 | 272 | 4 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=39; hand=11 |
| action-000080 | 274 | 4 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Isolated Chapel | ok | rule=curated/verified; effect=land |
| action-000081 | 278 | 4 | precombat_main | Y'shtola, Night's Blessed #70 (real) | cost_paid | Demonic Consultation | ok | card=Demonic Consultation; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=39->39 |
| action-000082 | 279 | 4 | precombat_main | Y'shtola, Night's Blessed #70 (real) | spell_cast | Demonic Consultation | ok | rule=curated/verified; effect=tutor; decision=decision-000039 |
| action-000083 | 284 | 4 | precombat_main | Y'shtola, Night's Blessed #70 (real) | spell_resolved | Demonic Consultation | ok | rule=curated/verified; effect=tutor; resolved_from_stack=True; destination=graveyard |
| action-000084 | 285 | 4 | - | Y'shtola, Night's Blessed #70 (real) | tutor_resolved | Demonic Consultation | ok | - |
| action-000085 | 290 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | - | ok | target=-; power=- |
| action-000086 | 291 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000087 | 292 | 4 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000088 | 293 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat | target=The Gitrog Monster #78 (real) | ok | - |
| action-000089 | 294 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000090 | 295 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000091 | 296 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | - | ok | target=-; power=- |
| action-000092 | 301 | 4 | - | Y'shtola, Night's Blessed #70 (real) | turn_end | - | ok | hand=7; board=1; grave=11 |
| action-000093 | 302 | 4 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=39; hand=5 |
| action-000094 | 310 | 4 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000095 | 311 | 4 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000096 | 312 | 4 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000097 | 313 | 4 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000098 | 314 | 4 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000099 | 315 | 4 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000100 | 316 | 4 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000101 | 323 | 4 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=6; board=1; grave=4 |
| action-000102 | 324 | 5 | - | Lorehold | turn_start | - | ok | life=40; hand=5 |
| action-000103 | 326 | 5 | - | Lorehold | land_played | Plateau | ok | rule=curated/verified; effect=land |
| action-000104 | 328 | 5 | precombat_main | Lorehold | cost_paid | Lorehold, the Historian | ok | card=Lorehold, the Historian; cost={'colored': {'red': 1, 'white': 1}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=5->0; life=40->40 |
| action-000105 | 329 | 5 | precombat_main | Lorehold | commander_cast | Lorehold, the Historian | ok | rule=curated/active; effect=passive; decision=decision-000047 |
| action-000106 | 334 | 5 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000107 | 335 | 5 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000108 | 336 | 5 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000109 | 337 | 5 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000110 | 338 | 5 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000111 | 339 | 5 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000112 | 340 | 5 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000113 | 345 | 5 | - | Lorehold | turn_end | - | ok | hand=5; board=8; grave=1 |
| action-000114 | 346 | 5 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=40; hand=4 |
| action-000115 | 354 | 5 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000116 | 359 | 5 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=5; board=0; grave=7 |
| action-000117 | 360 | 5 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=33; hand=7 |
| action-000118 | 364 | 5 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Command Tower | ok | rule=curated/verified; effect=land |
| action-000119 | 371 | 5 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=39; hand=6 |
| action-000120 | 375 | 5 | - | The Gitrog Monster #78 (real) | land_played | Prismatic Vista | ok | rule=curated/verified; effect=land |
| action-000121 | 382 | 6 | - | Lorehold | turn_start | - | ok | life=40; hand=5 |
| action-000122 | 385 | 6 | draw_step | Lorehold | miracle_cast | Mizzix's Mastery | ok | rule=curated/verified; effect=overload_recursion |
| action-000123 | 390 | 6 | draw_step | Lorehold | spell_resolved | Mizzix's Mastery | ok | rule=curated/verified; effect=overload_recursion; resolved_from_stack=True; destination=graveyard |
| action-000124 | 392 | 6 | precombat_main | Lorehold | cost_paid | Mana Vault | ok | card=Mana Vault; cost={'colored': {}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=2->1; life=40->40 |
| action-000125 | 393 | 6 | precombat_main | Lorehold | spell_cast | Mana Vault | ok | rule=curated/active; effect=ramp_permanent; decision=decision-000057 |
| action-000126 | 394 | 6 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=4 |
| action-000127 | 399 | 6 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000128 | 401 | 6 | precombat_main | Lorehold | cost_paid | Path to Exile | ok | card=Path to Exile; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->3; life=40->40 |
| action-000129 | 402 | 6 | precombat_main | Lorehold | spell_cast | Path to Exile | ok | rule=curated/active; effect=remove_creature; target=Esper Sentinel; decision=decision-000058 |
| action-000130 | 403 | 6 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=5 |
| action-000131 | 408 | 6 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000132 | 413 | 6 | precombat_main | Lorehold | spell_resolved | Path to Exile | ok | rule=curated/active; effect=remove_creature; target=Esper Sentinel; resolved_from_stack=True; destination=graveyard |
| action-000133 | 414 | 6 | - | Lorehold | removal_resolved | Path to Exile | ok | - |
| action-000134 | 419 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000135 | 420 | 6 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000136 | 421 | 6 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000137 | 422 | 6 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000138 | 423 | 6 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000139 | 424 | 6 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000140 | 425 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000141 | 430 | 6 | - | Lorehold | turn_end | - | ok | hand=3; board=9; grave=4 |
| action-000142 | 431 | 6 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=38; hand=5 |
| action-000143 | 438 | 6 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000144 | 443 | 6 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=6; board=0; grave=7 |
| action-000145 | 444 | 6 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=26; hand=9 |
| action-000146 | 447 | 6 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Plains | ok | rule=curated/verified; effect=land |
| action-000147 | 454 | 6 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=37; hand=6 |
| action-000148 | 463 | 6 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000149 | 464 | 6 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000150 | 465 | 6 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000151 | 466 | 6 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000152 | 467 | 6 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000153 | 468 | 6 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000154 | 469 | 6 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000155 | 476 | 6 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=5 |
| action-000156 | 477 | 7 | - | Lorehold | turn_start | - | ok | life=40; hand=3 |
| action-000157 | 480 | 7 | draw_step | Lorehold | miracle_cast | Deflecting Swat | ok | rule=curated/verified; effect=redirect_removal |
| action-000158 | 485 | 7 | draw_step | Lorehold | spell_resolved | Deflecting Swat | ok | rule=curated/verified; effect=redirect_removal; resolved_from_stack=True; destination=graveyard |
| action-000159 | 486 | 7 | - | Lorehold | land_played | Inspiring Vantage | ok | rule=curated/verified; effect=land |
| action-000160 | 488 | 7 | precombat_main | Lorehold | cost_paid | Guttersnipe | ok | card=Guttersnipe; cost={'colored': {'red': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=6->3; life=40->40 |
| action-000161 | 489 | 7 | precombat_main | Lorehold | creature_cast | Guttersnipe | ok | rule=curated/verified; effect=creature; decision=decision-000069 |
| action-000162 | 494 | 7 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000163 | 495 | 7 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000164 | 496 | 7 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000165 | 497 | 7 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000166 | 498 | 7 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000167 | 499 | 7 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000168 | 500 | 7 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000169 | 505 | 7 | - | Lorehold | turn_end | - | ok | hand=1; board=11; grave=5 |
| action-000170 | 506 | 7 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=38; hand=6 |
| action-000171 | 513 | 7 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000172 | 518 | 7 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=7 |
| action-000173 | 519 | 7 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=20; hand=9 |
| action-000174 | 522 | 7 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Underground River | ok | rule=curated/verified; effect=land |
| action-000175 | 529 | 7 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=37; hand=7 |
| action-000176 | 538 | 7 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000177 | 539 | 7 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000178 | 540 | 7 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000179 | 541 | 7 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000180 | 542 | 7 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000181 | 543 | 7 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000182 | 544 | 7 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000183 | 551 | 7 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=6 |
| action-000184 | 552 | 8 | - | Lorehold | turn_start | - | ok | life=40; hand=1 |
| action-000185 | 556 | 8 | precombat_main | Lorehold | cost_paid | Mother of Runes | ok | card=Mother of Runes; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=9->8; life=40->40 |
| action-000186 | 557 | 8 | precombat_main | Lorehold | creature_cast | Mother of Runes | ok | rule=curated/verified; effect=creature; decision=decision-000079 |
| action-000187 | 559 | 8 | precombat_main | Lorehold | cost_paid | Storm-Kiln Artist | ok | card=Storm-Kiln Artist; cost={'colored': {'red': 1}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=8->4; life=40->40 |
| action-000188 | 560 | 8 | precombat_main | Lorehold | creature_cast | Storm-Kiln Artist | ok | rule=curated/verified; effect=creature; decision=decision-000080 |
| action-000189 | 565 | 8 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000190 | 566 | 8 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000191 | 567 | 8 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000192 | 568 | 8 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000193 | 569 | 8 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000194 | 570 | 8 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000195 | 571 | 8 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000196 | 572 | 8 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000197 | 573 | 8 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000198 | 574 | 8 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000199 | 575 | 8 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000200 | 580 | 8 | - | Lorehold | turn_end | - | ok | hand=0; board=13; grave=5 |
| action-000201 | 581 | 8 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=38; hand=7 |
| action-000202 | 585 | 8 | - | Rograkh, Son of Rohgahh #119 (real) | land_played | Verdant Catacombs | ok | rule=curated/verified; effect=land |
| action-000203 | 589 | 8 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | cost_paid | Mana Vault | ok | card=Mana Vault; cost={'colored': {}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=1->0; life=38->38 |
| action-000204 | 590 | 8 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | spell_cast | Mana Vault | ok | rule=curated/active; effect=ramp_permanent; decision=decision-000084 |
| action-000205 | 591 | 8 | - | Y'shtola, Night's Blessed #70 (real) | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_spell; stack=6 |
| action-000206 | 596 | 8 | precombat_main | Y'shtola, Night's Blessed #70 (real) | trigger_resolved | Esper Sentinel | ok | - |
| action-000207 | 603 | 8 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000208 | 610 | 8 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=6; board=0; grave=9 |
| action-000209 | 611 | 8 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=14; hand=10 |
| action-000210 | 615 | 8 | - | Y'shtola, Night's Blessed #70 (real) | land_played | Underground Sea | ok | rule=curated/verified; effect=land |
| action-000211 | 622 | 8 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=35; hand=7 |
| action-000212 | 632 | 8 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000213 | 633 | 8 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000214 | 634 | 8 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000215 | 635 | 8 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000216 | 636 | 8 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000217 | 637 | 8 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000218 | 638 | 8 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000219 | 645 | 8 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=7 |
| action-000220 | 646 | 9 | - | Lorehold | turn_start | - | ok | life=40; hand=0 |
| action-000221 | 649 | 9 | - | Lorehold | land_played | Great Furnace | ok | rule=curated/verified; effect=land |
| action-000222 | 654 | 9 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000223 | 655 | 9 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000224 | 656 | 9 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000225 | 657 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000226 | 658 | 9 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000227 | 659 | 9 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000228 | 660 | 9 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000229 | 661 | 9 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000230 | 662 | 9 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000231 | 663 | 9 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000232 | 664 | 9 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000233 | 665 | 9 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000234 | 666 | 9 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000235 | 667 | 9 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000236 | 672 | 9 | - | Lorehold | turn_end | - | ok | hand=0; board=14; grave=5 |
| action-000237 | 673 | 9 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=36; hand=6 |
| action-000238 | 681 | 9 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000239 | 686 | 9 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=9 |
| action-000240 | 687 | 9 | - | Y'shtola, Night's Blessed #70 (real) | turn_start | - | ok | life=7; hand=10 |
| action-000241 | 695 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | - | ok | target=-; power=- |
| action-000242 | 696 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000243 | 697 | 9 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000244 | 698 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat | target=Lorehold | ok | - |
| action-000245 | 699 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000246 | 700 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000247 | 701 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | - | ok | target=-; power=- |
| action-000248 | 706 | 9 | - | Y'shtola, Night's Blessed #70 (real) | turn_end | - | ok | hand=7; board=1; grave=20 |
| action-000249 | 707 | 9 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=33; hand=7 |
| action-000250 | 717 | 9 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000251 | 718 | 9 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000252 | 719 | 9 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000253 | 720 | 9 | - | The Gitrog Monster #78 (real) | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000254 | 721 | 9 | - | The Gitrog Monster #78 (real) | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000255 | 722 | 9 | - | The Gitrog Monster #78 (real) | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000256 | 723 | 9 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000257 | 730 | 9 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=8 |
| action-000258 | 731 | 10 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000259 | 734 | 10 | draw_step | Lorehold | miracle_cast | Rite of Flame | ok | rule=curated/verified; effect=ramp_ritual |
| action-000260 | 739 | 10 | draw_step | Lorehold | spell_resolved | Rite of Flame | ok | rule=curated/verified; effect=ramp_ritual; resolved_from_stack=True; destination=graveyard |
| action-000261 | 744 | 10 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000262 | 745 | 10 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000263 | 746 | 10 | - | Y'shtola, Night's Blessed #70 (real) | combat_step | defender=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000264 | 747 | 10 | - | Lorehold | combat | target=Y'shtola, Night's Blessed #70 (real) | ok | - |
| action-000265 | 748 | 10 | - | Lorehold | combat_step | target=Y'shtola, Night's Blessed #70 (real) | ok | target=Y'shtola, Night's Blessed #70 (real); power=- |
| action-000266 | 749 | 10 | - | Lorehold | combat_result | target=Y'shtola, Night's Blessed #70 (real) | ok | damage=-; target_life=- |
| action-000267 | 750 | 10 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000268 | 751 | 10 | - | Y'shtola, Night's Blessed #70 (real) | player_eliminated | life_zero | ok | reason=life_zero |
| action-000269 | 752 | 10 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=36; hand=7 |
| action-000270 | 759 | 10 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000271 | 763 | 10 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=10 |
| action-000272 | 764 | 10 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=33; hand=7 |
| action-000273 | 773 | 10 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000274 | 774 | 10 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000275 | 775 | 10 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000276 | 776 | 10 | - | The Gitrog Monster #78 (real) | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000277 | 777 | 10 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000278 | 778 | 10 | - | The Gitrog Monster #78 (real) | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000279 | 779 | 10 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000280 | 785 | 10 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=9 |
| action-000281 | 786 | 11 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000282 | 789 | 11 | draw_step | Lorehold | miracle_cast | Mana Geyser | ok | rule=curated/verified; effect=ramp_ritual |
| action-000283 | 793 | 11 | draw_step | Lorehold | spell_resolved | Mana Geyser | ok | rule=curated/verified; effect=ramp_ritual; resolved_from_stack=True; destination=graveyard |
| action-000284 | 797 | 11 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000285 | 798 | 11 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000286 | 799 | 11 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000287 | 800 | 11 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000288 | 801 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000289 | 802 | 11 | - | Lorehold | combat | target=The Gitrog Monster #78 (real) | ok | - |
| action-000290 | 803 | 11 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000291 | 804 | 11 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000292 | 805 | 11 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000293 | 806 | 11 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000294 | 807 | 11 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000295 | 811 | 11 | - | Lorehold | turn_end | - | ok | hand=0; board=14; grave=7 |
| action-000296 | 812 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=32; hand=7 |
| action-000297 | 816 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | land_played | Gemstone Caverns | ok | rule=curated/active; effect=land |
| action-000298 | 820 | 11 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | cost_paid | Arbor Elf | ok | card=Arbor Elf; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=1->0; life=32->32 |
| action-000299 | 821 | 11 | precombat_main | Rograkh, Son of Rohgahh #119 (real) | creature_cast | Arbor Elf | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000112 |
| action-000300 | 825 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000301 | 829 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=6; board=1; grave=11 |
| action-000302 | 830 | 11 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=26; hand=7 |
| action-000303 | 839 | 11 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000304 | 840 | 11 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000305 | 841 | 11 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000306 | 842 | 11 | - | The Gitrog Monster #78 (real) | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000307 | 843 | 11 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000308 | 844 | 11 | - | The Gitrog Monster #78 (real) | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000309 | 845 | 11 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000310 | 851 | 11 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=10 |
| action-000311 | 852 | 12 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000312 | 856 | 12 | precombat_main | Lorehold | cost_paid | Giver of Runes | ok | card=Giver of Runes; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=10->9; life=39->39 |
| action-000313 | 857 | 12 | precombat_main | Lorehold | creature_cast | Giver of Runes | ok | rule=curated/verified; effect=creature; decision=decision-000118 |
| action-000314 | 861 | 12 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000315 | 862 | 12 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000316 | 863 | 12 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000317 | 864 | 12 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000318 | 865 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000319 | 866 | 12 | - | Lorehold | combat | target=The Gitrog Monster #78 (real) | ok | - |
| action-000320 | 867 | 12 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000321 | 868 | 12 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000322 | 869 | 12 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000323 | 870 | 12 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000324 | 871 | 12 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000325 | 875 | 12 | - | Lorehold | turn_end | - | ok | hand=0; board=15; grave=7 |
| action-000326 | 876 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=28; hand=6 |
| action-000327 | 883 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000328 | 884 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000329 | 885 | 12 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000330 | 886 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat | target=Lorehold | ok | - |
| action-000331 | 887 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000332 | 888 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000333 | 889 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000334 | 893 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=12 |
| action-000335 | 894 | 12 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=19; hand=7 |
| action-000336 | 903 | 12 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000337 | 904 | 12 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000338 | 905 | 12 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000339 | 906 | 12 | - | The Gitrog Monster #78 (real) | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000340 | 907 | 12 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000341 | 908 | 12 | - | The Gitrog Monster #78 (real) | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000342 | 909 | 12 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000343 | 915 | 12 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=11 |
| action-000344 | 916 | 13 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000345 | 919 | 13 | draw_step | Lorehold | miracle_cast | Rise of the Eldrazi | ok | rule=curated/verified; effect=composite_resolution |
| action-000346 | 923 | 13 | draw_step | Lorehold | spell_resolved | Rise of the Eldrazi | ok | rule=curated/verified; effect=composite_resolution; resolved_from_stack=True; destination=exile |
| action-000347 | 924 | 13 | - | Lorehold | removal_resolved | Rise of the Eldrazi | ok | - |
| action-000348 | 929 | 13 | - | Lorehold | land_played | Windswept Heath | ok | rule=curated/verified; effect=land |
| action-000349 | 931 | 13 | precombat_main | Lorehold | cost_paid | Esper Sentinel | ok | card=Esper Sentinel; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=9->8; life=39->39 |
| action-000350 | 932 | 13 | precombat_main | Lorehold | spell_cast | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; decision=decision-000128 |
| action-000351 | 936 | 13 | precombat_main | Lorehold | spell_resolved | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000352 | 938 | 13 | precombat_main | Lorehold | cost_paid | Past in Flames | ok | card=Past in Flames; cost={'colored': {'red': 1}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=8->4; life=39->39 |
| action-000353 | 939 | 13 | precombat_main | Lorehold | spell_cast | Past in Flames | ok | rule=curated/verified; effect=recursion; decision=decision-000129 |
| action-000354 | 940 | 13 | - | Lorehold | trigger_put_on_stack | Guttersnipe | ok | source=Guttersnipe; trigger=instant_sorcery_cast; stack=7 |
| action-000355 | 944 | 13 | precombat_main | Lorehold | trigger_resolved | Guttersnipe | ok | - |
| action-000356 | 948 | 13 | precombat_main | Lorehold | spell_resolved | Past in Flames | ok | rule=curated/verified; effect=recursion; resolved_from_stack=True; destination=graveyard |
| action-000357 | 949 | 13 | - | Lorehold | recursion_resolved | Past in Flames | ok | - |
| action-000358 | 951 | 13 | precombat_main | Lorehold | cost_paid | Path to Exile | ok | card=Path to Exile; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->3; life=39->39 |
| action-000359 | 952 | 13 | precombat_main | Lorehold | spell_cast | Path to Exile | ok | rule=curated/active; effect=remove_creature; target=Delighted Halfling; decision=decision-000130 |
| action-000360 | 953 | 13 | - | Lorehold | trigger_put_on_stack | Guttersnipe | ok | source=Guttersnipe; trigger=instant_sorcery_cast; stack=8 |
| action-000361 | 957 | 13 | precombat_main | Lorehold | trigger_resolved | Guttersnipe | ok | - |
| action-000362 | 961 | 13 | precombat_main | Lorehold | spell_resolved | Path to Exile | ok | rule=curated/active; effect=remove_creature; target=Delighted Halfling; resolved_from_stack=True; destination=graveyard |
| action-000363 | 962 | 13 | - | Lorehold | removal_resolved | Path to Exile | ok | - |
| action-000364 | 963 | 13 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000365 | 964 | 13 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000366 | 965 | 13 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000367 | 966 | 13 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000368 | 967 | 13 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000369 | 968 | 13 | - | Lorehold | combat | target=The Gitrog Monster #78 (real) | ok | - |
| action-000370 | 969 | 13 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000371 | 970 | 13 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000372 | 971 | 13 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000373 | 972 | 13 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000374 | 973 | 13 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000375 | 975 | 13 | postcombat_main | Lorehold | cost_paid | Boros Charm | ok | card=Boros Charm; cost={'colored': {'red': 1, 'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=3->1; life=39->39 |
| action-000376 | 976 | 13 | postcombat_main | Lorehold | spell_cast | Boros Charm | ok | rule=curated/verified; effect=modal_boros_charm; decision=decision-000132 |
| action-000377 | 977 | 13 | - | Lorehold | trigger_put_on_stack | Guttersnipe | ok | source=Guttersnipe; trigger=instant_sorcery_cast; stack=9 |
| action-000378 | 981 | 13 | postcombat_main | Lorehold | trigger_resolved | Guttersnipe | ok | - |
| action-000379 | 985 | 13 | postcombat_main | Lorehold | spell_resolved | Boros Charm | ok | rule=curated/verified; effect=modal_boros_charm; resolved_from_stack=True; destination=graveyard |
| action-000380 | 989 | 13 | - | Lorehold | turn_end | - | ok | hand=4; board=17; grave=7 |
| action-000381 | 990 | 13 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=18; hand=7 |
| action-000382 | 997 | 13 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000383 | 1001 | 13 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=13 |
| action-000384 | 1002 | 13 | - | The Gitrog Monster #78 (real) | turn_start | - | ok | life=5; hand=7 |
| action-000385 | 1010 | 13 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000386 | 1011 | 13 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000387 | 1012 | 13 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000388 | 1013 | 13 | - | The Gitrog Monster #78 (real) | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000389 | 1014 | 13 | - | The Gitrog Monster #78 (real) | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000390 | 1015 | 13 | - | The Gitrog Monster #78 (real) | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000391 | 1016 | 13 | - | The Gitrog Monster #78 (real) | combat_step | - | ok | target=-; power=- |
| action-000392 | 1022 | 13 | - | The Gitrog Monster #78 (real) | turn_end | - | ok | hand=7; board=1; grave=12 |
| action-000393 | 1023 | 14 | - | Lorehold | turn_start | - | ok | life=39; hand=4 |
| action-000394 | 1026 | 14 | draw_step | Lorehold | miracle_cast | Blasphemous Act | ok | rule=curated/verified; effect=board_wipe |
| action-000395 | 1030 | 14 | draw_step | Lorehold | spell_resolved | Blasphemous Act | ok | rule=curated/verified; effect=board_wipe; resolved_from_stack=True; destination=graveyard |
| action-000396 | 1031 | 14 | - | ? | replacement_applied | Lorehold, the Historian | ok | card=Lorehold, the Historian; affected_player=Lorehold; source=Blasphemous Act; reason=board_wipe; zone=battlefield->command_zone; value=0->0; replacement_rule_source=commander_replacement_rule |
| action-000397 | 1034 | 14 | precombat_main | Lorehold | cost_paid | Lorehold, the Historian | ok | card=Lorehold, the Historian; cost={'colored': {'red': 1, 'white': 1}, 'generic': 5, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=9->2; life=39->39 |
| action-000398 | 1035 | 14 | precombat_main | Lorehold | commander_cast | Lorehold, the Historian | ok | rule=curated/active; effect=passive; decision=decision-000141 |
| action-000399 | 1037 | 14 | precombat_main | Lorehold | cost_paid | Lotus Petal | ok | card=Lotus Petal; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=2->2; life=39->39 |
| action-000400 | 1038 | 14 | precombat_main | Lorehold | spell_cast | Lotus Petal | ok | rule=curated/verified; effect=ramp_ritual; decision=decision-000142 |
| action-000401 | 1040 | 14 | precombat_main | Lorehold | cost_paid | Reiterate | ok | card=Reiterate; cost={'colored': {'red': 2}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=3->0; life=39->39 |
| action-000402 | 1041 | 14 | precombat_main | Lorehold | spell_cast | Reiterate | ok | rule=curated/verified; effect=copy_spell; decision=decision-000143 |
| action-000403 | 1045 | 14 | precombat_main | Lorehold | spell_resolved | Reiterate | ok | rule=curated/verified; effect=copy_spell; resolved_from_stack=True; destination=graveyard |
| action-000404 | 1046 | 14 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000405 | 1047 | 14 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000406 | 1048 | 14 | - | The Gitrog Monster #78 (real) | combat_step | defender=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000407 | 1049 | 14 | - | Lorehold | combat | target=The Gitrog Monster #78 (real) | ok | - |
| action-000408 | 1050 | 14 | - | Lorehold | combat_step | target=The Gitrog Monster #78 (real) | ok | target=The Gitrog Monster #78 (real); power=- |
| action-000409 | 1051 | 14 | - | Lorehold | combat_result | target=The Gitrog Monster #78 (real) | ok | damage=-; target_life=- |
| action-000410 | 1052 | 14 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000411 | 1053 | 14 | - | The Gitrog Monster #78 (real) | player_eliminated | life_zero | ok | reason=life_zero |
| action-000412 | 1054 | 14 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=17; hand=7 |
| action-000413 | 1060 | 14 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000414 | 1063 | 14 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=14 |
| action-000415 | 1064 | 15 | - | Lorehold | turn_start | - | ok | life=39; hand=2 |
| action-000416 | 1067 | 15 | draw_step | Lorehold | miracle_cast | Mizzix's Mastery | ok | rule=curated/verified; effect=overload_recursion |
| action-000417 | 1068 | 15 | draw_step | Rograkh, Son of Rohgahh #119 (real) | spell_countered | target=Mizzix's Mastery | ok | rule=curated/verified; effect=counter; target=Mizzix's Mastery; stack_object=Mizzix's Mastery; result=countered; phase=draw_step; priority_window=stack_response |
| action-000418 | 1069 | 15 | - | Lorehold | land_played | Flooded Strand | ok | rule=curated/verified; effect=land |
| action-000419 | 1072 | 15 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000420 | 1073 | 15 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000421 | 1074 | 15 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000422 | 1075 | 15 | - | Lorehold | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000423 | 1076 | 15 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000424 | 1077 | 15 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000425 | 1078 | 15 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000426 | 1081 | 15 | - | Lorehold | turn_end | - | ok | hand=1; board=14; grave=15 |
| action-000427 | 1082 | 15 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=12; hand=6 |
| action-000428 | 1087 | 15 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000429 | 1090 | 15 | end_step | Lorehold | end_step_instant | Unexpected Windfall | ok | rule=curated/verified; effect=treasure_maker |
| action-000430 | 1091 | 15 | end_step | Lorehold | spell_resolved | Unexpected Windfall | ok | rule=curated/verified; effect=treasure_maker; resolved_from_stack=False; destination=graveyard |
| action-000431 | 1092 | 15 | - | Lorehold | additional_cost_failed | Unexpected Windfall | ok | - |
| action-000432 | 1093 | 15 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=15 |
| action-000433 | 1094 | 16 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000434 | 1097 | 16 | draw_step | Lorehold | miracle_cast | Storm Herd | ok | rule=curated/verified; effect=token_maker |
| action-000435 | 1100 | 16 | draw_step | Lorehold | spell_resolved | Storm Herd | ok | rule=curated/verified; effect=token_maker; resolved_from_stack=True; destination=graveyard |
| action-000436 | 1103 | 16 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000437 | 1104 | 16 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000438 | 1105 | 16 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000439 | 1106 | 16 | - | Lorehold | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000440 | 1107 | 16 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000441 | 1108 | 16 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000442 | 1109 | 16 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000443 | 1112 | 16 | - | Lorehold | turn_end | - | ok | hand=0; board=33; grave=17 |
| action-000444 | 1113 | 16 | - | Rograkh, Son of Rohgahh #119 (real) | turn_start | - | ok | life=7; hand=7 |
| action-000445 | 1119 | 16 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | - | ok | target=-; power=- |
| action-000446 | 1122 | 16 | - | Rograkh, Son of Rohgahh #119 (real) | turn_end | - | ok | hand=7; board=0; grave=16 |
| action-000447 | 1123 | 17 | - | Lorehold | turn_start | - | ok | life=39; hand=0 |
| action-000448 | 1127 | 17 | precombat_main | Lorehold | cost_paid | Mox Amber | ok | card=Mox Amber; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=12->12; life=39->39 |
| action-000449 | 1128 | 17 | precombat_main | Lorehold | spell_cast | Mox Amber | ok | rule=curated/verified; effect=ramp_permanent; decision=decision-000159 |
| action-000450 | 1131 | 17 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000451 | 1132 | 17 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000452 | 1133 | 17 | - | Rograkh, Son of Rohgahh #119 (real) | combat_step | defender=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000453 | 1134 | 17 | - | Lorehold | combat | target=Rograkh, Son of Rohgahh #119 (real) | ok | - |
| action-000454 | 1135 | 17 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #119 (real) | ok | target=Rograkh, Son of Rohgahh #119 (real); power=- |
| action-000455 | 1136 | 17 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #119 (real) | ok | damage=-; target_life=- |
| action-000456 | 1137 | 17 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000457 | 1138 | 17 | - | Rograkh, Son of Rohgahh #119 (real) | player_eliminated | life_zero | ok | reason=life_zero |
| action-000458 | 1139 | 17 | - | Lorehold | game_won | elimination | ok | winner=Lorehold |
