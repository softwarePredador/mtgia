# Battle Action Critic

## Summary

- total_actions: 337
- events_total: 756
- event_types_total: 38
- event_contract_class_counts: `{"action_audited": 337, "ignored_with_reason": 6, "renderer_only": 1, "strategy_signal": 9, "technical": 361, "unclassified": 42}`
- events_unclassified: 42
- event_types_unclassified: `["countered_spell_moved_to_graveyard", "focus_card_access_snapshot", "permanent_moved_from_battlefield"]`
- findings: 0
- verdict_counts: `{"ok": 337}`
- technical_events_included: False
- technical_events_mode: default_action_only

## Findings

- No action findings.

## Action Ledger

| Action | Line | Turn | Phase | Player | Event | Label | Verdict | Evidence |
| --- | ---: | ---: | --- | --- | --- | --- | --- | --- |
| action-000001 | 22 | 1 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000002 | 27 | 1 | - | Lorehold | land_played | Glittering Massif | ok | rule=curated/verified; effect=land |
| action-000003 | 38 | 1 | - | Lorehold | turn_end | - | ok | hand=7; board=1; grave=0 |
| action-000004 | 39 | 1 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000005 | 41 | 1 | - | Kinnan, Bonder Prodigy #72 (real) | land_played | Tropical Island | ok | rule=curated/verified; effect=land |
| action-000006 | 43 | 1 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Crop Rotation | ok | card=Crop Rotation; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=40->40 |
| action-000007 | 44 | 1 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | spell_cast | Crop Rotation | ok | rule=curated/verified; effect=land_ramp; decision=decision-000008 |
| action-000008 | 48 | 1 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Walking Ballista | ok | card=Walking Ballista; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=0->0; life=40->40 |
| action-000009 | 49 | 1 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | creature_cast | Walking Ballista | ok | rule=curated/verified; effect=creature; decision=decision-000009 |
| action-000010 | 59 | 1 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=5; board=1; grave=3 |
| action-000011 | 60 | 1 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000012 | 62 | 1 | - | Rograkh, Son of Rohgahh #63 (real) | land_played | Flooded Strand | ok | rule=curated/verified; effect=land |
| action-000013 | 71 | 1 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=7; board=1; grave=0 |
| action-000014 | 72 | 1 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000015 | 74 | 1 | - | Rowan, Scion of War #32 (real) | land_played | Blood Crypt | ok | rule=curated/verified; effect=land |
| action-000016 | 76 | 1 | precombat_main | Rowan, Scion of War #32 (real) | cost_paid | Reanimate | ok | card=Reanimate; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=38->38 |
| action-000017 | 77 | 1 | precombat_main | Rowan, Scion of War #32 (real) | spell_cast | Reanimate | ok | rule=curated/verified; effect=recursion; decision=decision-000014 |
| action-000018 | 82 | 1 | precombat_main | Rowan, Scion of War #32 (real) | spell_resolved | Reanimate | ok | rule=curated/verified; effect=recursion; resolved_from_stack=True; destination=graveyard |
| action-000019 | 83 | 1 | - | Rowan, Scion of War #32 (real) | recursion_resolved | Reanimate | ok | - |
| action-000020 | 92 | 1 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=6; board=1; grave=1 |
| action-000021 | 93 | 2 | - | Lorehold | turn_start | - | ok | life=40; hand=7 |
| action-000022 | 98 | 2 | - | Lorehold | land_played | Sacred Foundry | ok | rule=curated/verified; effect=land |
| action-000023 | 100 | 2 | precombat_main | Lorehold | cost_paid | Hexing Squelcher | ok | card=Hexing Squelcher; cost={'colored': {'red': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=2->0; life=38->38 |
| action-000024 | 101 | 2 | precombat_main | Lorehold | creature_cast | Hexing Squelcher | ok | rule=curated/verified; effect=creature; decision=decision-000017 |
| action-000025 | 107 | 2 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000026 | 113 | 2 | - | Lorehold | turn_end | - | ok | hand=6; board=3; grave=0 |
| action-000027 | 114 | 2 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000028 | 116 | 2 | - | Kinnan, Bonder Prodigy #72 (real) | land_played | Exotic Orchard | ok | rule=curated/verified; effect=land |
| action-000029 | 118 | 2 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Kinnan, Bonder Prodigy | ok | card=Kinnan, Bonder Prodigy; cost={'colored': {'blue': 1, 'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=2->0; life=40->40 |
| action-000030 | 119 | 2 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | commander_cast | Kinnan, Bonder Prodigy | ok | rule=curated/verified; effect=creature; decision=decision-000020 |
| action-000031 | 124 | 2 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000032 | 129 | 2 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=5; board=3; grave=3 |
| action-000033 | 130 | 2 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=40; hand=7 |
| action-000034 | 132 | 2 | - | Rograkh, Son of Rohgahh #63 (real) | land_played | Volcanic Island | ok | rule=curated/verified; effect=land |
| action-000035 | 134 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Rograkh, Son of Rohgahh | ok | card=Rograkh, Son of Rohgahh; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=1->1; life=40->40 |
| action-000036 | 135 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | commander_cast | Rograkh, Son of Rohgahh | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000023 |
| action-000037 | 137 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Shield Sphere | ok | card=Shield Sphere; cost={'colored': {}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=1->1; life=40->40 |
| action-000038 | 138 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | creature_cast | Shield Sphere | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000024 |
| action-000039 | 140 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Into the Flood Maw | ok | card=Into the Flood Maw; cost={'colored': {'blue': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=40->40 |
| action-000040 | 141 | 2 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Into the Flood Maw | ok | rule=curated/verified; effect=remove_creature; target=Hexing Squelcher; decision=decision-000025 |
| action-000041 | 142 | 2 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | spell_countered | target=Into the Flood Maw | ok | rule=curated/verified; effect=counter; target=Into the Flood Maw; stack_object=Into the Flood Maw; result=countered; phase=precombat_main; priority_window=stack_response |
| action-000042 | 144 | 2 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000043 | 149 | 2 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=5; board=4; grave=1 |
| action-000044 | 150 | 2 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=38; hand=6 |
| action-000045 | 152 | 2 | - | Rowan, Scion of War #32 (real) | land_played | Multiversal Passage | ok | rule=curated/verified; effect=land |
| action-000046 | 157 | 2 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000047 | 162 | 2 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=6; board=2; grave=1 |
| action-000048 | 163 | 3 | - | Lorehold | turn_start | - | ok | life=38; hand=6 |
| action-000049 | 168 | 3 | - | Lorehold | land_played | Plains // Plains | ok | rule=curated/verified; effect=land |
| action-000050 | 170 | 3 | precombat_main | Lorehold | cost_paid | Jeska's Will | ok | card=Jeska's Will; cost={'colored': {'red': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=3->0; life=38->38 |
| action-000051 | 171 | 3 | precombat_main | Lorehold | spell_cast | Jeska's Will | ok | rule=curated/verified; effect=ramp_ritual; decision=decision-000030 |
| action-000052 | 172 | 3 | precombat_main | Lorehold | spell_resolved | Jeska's Will | ok | rule=curated/verified; effect=ramp_ritual; resolved_from_stack=False; destination=graveyard |
| action-000053 | 175 | 3 | precombat_main | Lorehold | cost_paid | Thor, God of Thunder | ok | card=Thor, God of Thunder; cost={'colored': {'red': 2}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=6->1; life=38->38 |
| action-000054 | 176 | 3 | precombat_main | Lorehold | creature_cast | Thor, God of Thunder | ok | rule=curated/active; effect=creature; decision=decision-000031 |
| action-000055 | 182 | 3 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000056 | 183 | 3 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000057 | 184 | 3 | - | Rowan, Scion of War #32 (real) | combat_step | defender=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000058 | 185 | 3 | - | Lorehold | combat | target=Rowan, Scion of War #32 (real) | ok | - |
| action-000059 | 186 | 3 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000060 | 187 | 3 | - | Lorehold | combat_result | target=Rowan, Scion of War #32 (real) | ok | damage=-; target_life=- |
| action-000061 | 188 | 3 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000062 | 194 | 3 | - | Lorehold | turn_end | - | ok | hand=4; board=5; grave=1 |
| action-000063 | 195 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=38; hand=4 |
| action-000064 | 197 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | land_played | Command Tower | ok | rule=curated/verified; effect=land |
| action-000065 | 199 | 3 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Birds of Paradise | ok | card=Birds of Paradise; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->2; life=38->38 |
| action-000066 | 200 | 3 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | creature_cast | Birds of Paradise | ok | rule=curated/verified; effect=creature; decision=decision-000035 |
| action-000067 | 205 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000068 | 206 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000069 | 207 | 3 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000070 | 208 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat | target=Lorehold | ok | - |
| action-000071 | 209 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000072 | 210 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000073 | 211 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000074 | 216 | 3 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=3; board=5; grave=4 |
| action-000075 | 217 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=40; hand=5 |
| action-000076 | 219 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | land_played | Command Tower | ok | rule=curated/verified; effect=land |
| action-000077 | 221 | 3 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Fellwar Stone | ok | card=Fellwar Stone; cost={'colored': {}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=2->0; life=40->40 |
| action-000078 | 222 | 3 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Fellwar Stone | ok | rule=curated/active; effect=ramp_permanent; decision=decision-000039 |
| action-000079 | 224 | 3 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Dark Ritual | ok | card=Dark Ritual; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=40->40 |
| action-000080 | 225 | 3 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Dark Ritual | ok | rule=curated/verified; effect=ramp_ritual; decision=decision-000040 |
| action-000081 | 230 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000082 | 231 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000083 | 232 | 3 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000084 | 233 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat | target=Lorehold | ok | - |
| action-000085 | 234 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000086 | 235 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000087 | 236 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000088 | 237 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000089 | 242 | 3 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=3; board=6; grave=2 |
| action-000090 | 243 | 3 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=34; hand=6 |
| action-000091 | 245 | 3 | - | Rowan, Scion of War #32 (real) | land_played | Starting Town | ok | rule=curated/verified; effect=land |
| action-000092 | 247 | 3 | precombat_main | Rowan, Scion of War #32 (real) | cost_paid | Opposition Agent | ok | card=Opposition Agent; cost={'colored': {'black': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->0; life=34->34 |
| action-000093 | 248 | 3 | precombat_main | Rowan, Scion of War #32 (real) | creature_cast | Opposition Agent | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000044 |
| action-000094 | 253 | 3 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000095 | 258 | 3 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=5; board=4; grave=1 |
| action-000096 | 259 | 4 | - | Lorehold | turn_start | - | ok | life=34; hand=4 |
| action-000097 | 265 | 4 | precombat_main | Lorehold | cost_paid | Esper Sentinel | ok | card=Esper Sentinel; cost={'colored': {'white': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'creature_spell']}; mana=3->2; life=34->34 |
| action-000098 | 266 | 4 | precombat_main | Lorehold | spell_cast | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; decision=decision-000047 |
| action-000099 | 271 | 4 | precombat_main | Lorehold | spell_resolved | Esper Sentinel | ok | rule=curated/verified; effect=draw_engine; resolved_from_stack=True; destination=battlefield |
| action-000100 | 277 | 4 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000101 | 278 | 4 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000102 | 279 | 4 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000103 | 280 | 4 | - | Rowan, Scion of War #32 (real) | combat_step | defender=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000104 | 281 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | defender=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000105 | 282 | 4 | - | Lorehold | combat | target=Rowan, Scion of War #32 (real) | ok | - |
| action-000106 | 283 | 4 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000107 | 284 | 4 | - | Lorehold | combat_result | target=Rowan, Scion of War #32 (real) | ok | damage=-; target_life=- |
| action-000108 | 285 | 4 | - | Lorehold | combat_step | target=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000109 | 286 | 4 | - | Lorehold | combat_result | target=Kinnan, Bonder Prodigy #72 (real) | ok | damage=-; target_life=- |
| action-000110 | 287 | 4 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000111 | 293 | 4 | - | Lorehold | turn_end | - | ok | hand=6; board=6; grave=1 |
| action-000112 | 294 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=36; hand=3 |
| action-000113 | 297 | 4 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Valley Floodcaller | ok | card=Valley Floodcaller; cost={'colored': {'blue': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->1; life=36->36 |
| action-000114 | 298 | 4 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | creature_cast | Valley Floodcaller | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000051 |
| action-000115 | 303 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000116 | 304 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000117 | 305 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000118 | 306 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat | target=Lorehold | ok | - |
| action-000119 | 307 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000120 | 308 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000121 | 309 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000122 | 314 | 4 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=3; board=6; grave=4 |
| action-000123 | 315 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=40; hand=3 |
| action-000124 | 318 | 4 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Vampiric Tutor | ok | card=Vampiric Tutor; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=3->2; life=40->40 |
| action-000125 | 319 | 4 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Vampiric Tutor | ok | rule=curated/verified; effect=tutor; decision=decision-000055 |
| action-000126 | 320 | 4 | - | Lorehold | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_noncreature_spell; stack=0 |
| action-000127 | 325 | 4 | precombat_main | Lorehold | trigger_resolved | Esper Sentinel | ok | - |
| action-000128 | 330 | 4 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_resolved | Vampiric Tutor | ok | rule=curated/verified; effect=tutor; resolved_from_stack=True; destination=graveyard |
| action-000129 | 331 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | tutor_resolved | Vampiric Tutor | ok | - |
| action-000130 | 334 | 4 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Infernal Plunge | ok | card=Infernal Plunge; cost={'colored': {'red': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=1->0; life=38->38 |
| action-000131 | 335 | 4 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Infernal Plunge | ok | rule=curated/verified; effect=ramp_ritual; decision=decision-000057 |
| action-000132 | 342 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000133 | 343 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000134 | 344 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000135 | 345 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat | target=Lorehold | ok | - |
| action-000136 | 346 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000137 | 347 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000138 | 348 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000139 | 349 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000140 | 354 | 4 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=2; board=5; grave=5 |
| action-000141 | 355 | 4 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=29; hand=5 |
| action-000142 | 357 | 4 | - | Rowan, Scion of War #32 (real) | land_played | Ancient Tomb | ok | rule=curated/verified; effect=land |
| action-000143 | 363 | 4 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000144 | 364 | 4 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000145 | 365 | 4 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000146 | 366 | 4 | - | Rowan, Scion of War #32 (real) | combat | target=Lorehold | ok | - |
| action-000147 | 367 | 4 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000148 | 368 | 4 | - | Rowan, Scion of War #32 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000149 | 369 | 4 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000150 | 374 | 4 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=5; board=5; grave=1 |
| action-000151 | 375 | 5 | - | Lorehold | turn_start | - | ok | life=28; hand=6 |
| action-000152 | 380 | 5 | - | Lorehold | land_played | Flooded Strand | ok | rule=curated/verified; effect=land |
| action-000153 | 382 | 5 | precombat_main | Lorehold | cost_paid | Swiftfoot Boots | ok | card=Swiftfoot Boots; cost={'colored': {}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['artifact_spell', 'noncreature_spell']}; mana=3->1; life=28->28 |
| action-000154 | 383 | 5 | precombat_main | Lorehold | spell_cast | Swiftfoot Boots | ok | rule=curated/verified; effect=equipment_static_attachment; decision=decision-000064 |
| action-000155 | 384 | 5 | - | Lorehold | trigger_put_on_stack | Thor, God of Thunder | ok | source=Thor, God of Thunder; trigger=noncreature_spell_cast; stack=1 |
| action-000156 | 389 | 5 | - | ? | replacement_applied | Kinnan, Bonder Prodigy | ok | card=Kinnan, Bonder Prodigy; affected_player=Kinnan, Bonder Prodigy #72 (real); source=Thor, God of Thunder; reason=damage; zone=battlefield->command_zone; value=0->0; replacement_rule_source=commander_replacement_rule |
| action-000157 | 391 | 5 | precombat_main | Lorehold | trigger_resolved | Thor, God of Thunder | ok | - |
| action-000158 | 396 | 5 | precombat_main | Lorehold | spell_resolved | Swiftfoot Boots | ok | rule=curated/verified; effect=equipment_static_attachment; resolved_from_stack=True; destination=battlefield |
| action-000159 | 403 | 5 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000160 | 404 | 5 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000161 | 405 | 5 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000162 | 406 | 5 | - | Rowan, Scion of War #32 (real) | combat_step | defender=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000163 | 407 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | defender=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000164 | 408 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | defender=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000165 | 409 | 5 | - | Lorehold | combat | target=Rowan, Scion of War #32 (real) | ok | - |
| action-000166 | 410 | 5 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000167 | 411 | 5 | - | Lorehold | combat_result | target=Rowan, Scion of War #32 (real) | ok | damage=-; target_life=- |
| action-000168 | 412 | 5 | - | Lorehold | combat_step | target=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000169 | 413 | 5 | - | Lorehold | combat_result | target=Kinnan, Bonder Prodigy #72 (real) | ok | damage=-; target_life=- |
| action-000170 | 414 | 5 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000171 | 415 | 5 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #63 (real) | ok | damage=-; target_life=- |
| action-000172 | 416 | 5 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000173 | 422 | 5 | - | Lorehold | turn_end | - | ok | hand=6; board=8; grave=1 |
| action-000174 | 423 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=34; hand=3 |
| action-000175 | 426 | 5 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Kinnan, Bonder Prodigy | ok | card=Kinnan, Bonder Prodigy; cost={'colored': {'blue': 1, 'green': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->0; life=34->34 |
| action-000176 | 427 | 5 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | commander_cast | Kinnan, Bonder Prodigy | ok | rule=curated/verified; effect=creature; decision=decision-000068 |
| action-000177 | 432 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000178 | 433 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000179 | 434 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000180 | 435 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat | target=Lorehold | ok | - |
| action-000181 | 436 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000182 | 437 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000183 | 438 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000184 | 443 | 5 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=4; board=6; grave=4 |
| action-000185 | 444 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=37; hand=2 |
| action-000186 | 447 | 5 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Borne Upon a Wind | ok | card=Borne Upon a Wind; cost={'colored': {'blue': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=3->1; life=37->37 |
| action-000187 | 448 | 5 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Borne Upon a Wind | ok | rule=curated/verified; effect=draw_cards; decision=decision-000072 |
| action-000188 | 449 | 5 | - | Lorehold | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_noncreature_spell; stack=2 |
| action-000189 | 454 | 5 | precombat_main | Lorehold | trigger_resolved | Esper Sentinel | ok | - |
| action-000190 | 459 | 5 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_resolved | Borne Upon a Wind | ok | rule=curated/verified; effect=draw_cards; resolved_from_stack=True; destination=graveyard |
| action-000191 | 465 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000192 | 466 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000193 | 467 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000194 | 468 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat | target=Lorehold | ok | - |
| action-000195 | 469 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000196 | 470 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000197 | 471 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000198 | 472 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000199 | 477 | 5 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=3; board=5; grave=6 |
| action-000200 | 478 | 5 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=24; hand=5 |
| action-000201 | 482 | 5 | precombat_main | Rowan, Scion of War #32 (real) | cost_paid | Blood Celebrant | ok | card=Blood Celebrant; cost={'colored': {'black': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->3; life=24->24 |
| action-000202 | 483 | 5 | precombat_main | Rowan, Scion of War #32 (real) | spell_cast | Blood Celebrant | ok | rule=functional_tags_json/heuristic; effect=ramp_permanent; decision=decision-000076 |
| action-000203 | 488 | 5 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000204 | 489 | 5 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000205 | 490 | 5 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000206 | 491 | 5 | - | Rowan, Scion of War #32 (real) | combat | target=Lorehold | ok | - |
| action-000207 | 492 | 5 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000208 | 493 | 5 | - | Rowan, Scion of War #32 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000209 | 494 | 5 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000210 | 499 | 5 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=5; board=6; grave=1 |
| action-000211 | 500 | 6 | - | Lorehold | turn_start | - | ok | life=22; hand=6 |
| action-000212 | 505 | 6 | - | Lorehold | land_played | Urza's Saga | ok | rule=curated/verified; effect=land |
| action-000213 | 507 | 6 | precombat_main | Lorehold | cost_paid | Generous Gift | ok | card=Generous Gift; cost={'colored': {'white': 1}, 'generic': 2, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->1; life=22->22 |
| action-000214 | 508 | 6 | precombat_main | Lorehold | spell_cast | Generous Gift | ok | rule=curated/verified; effect=remove_permanent; target=Kinnan, Bonder Prodigy; decision=decision-000080 |
| action-000215 | 509 | 6 | - | Lorehold | trigger_put_on_stack | Thor, God of Thunder | ok | source=Thor, God of Thunder; trigger=noncreature_spell_cast; stack=3 |
| action-000216 | 514 | 6 | - | ? | replacement_applied | Kinnan, Bonder Prodigy | ok | card=Kinnan, Bonder Prodigy; affected_player=Kinnan, Bonder Prodigy #72 (real); source=Thor, God of Thunder; reason=damage; zone=battlefield->command_zone; value=0->0; replacement_rule_source=commander_replacement_rule |
| action-000217 | 516 | 6 | precombat_main | Lorehold | trigger_resolved | Thor, God of Thunder | ok | - |
| action-000218 | 521 | 6 | precombat_main | Lorehold | spell_resolved | Generous Gift | ok | rule=curated/verified; effect=remove_permanent; target=Kinnan, Bonder Prodigy; resolved_from_stack=True; destination=graveyard |
| action-000219 | 522 | 6 | - | Lorehold | removal_resolved | Generous Gift | ok | - |
| action-000220 | 528 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000221 | 529 | 6 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000222 | 530 | 6 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000223 | 531 | 6 | - | Rowan, Scion of War #32 (real) | combat_step | defender=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000224 | 532 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | defender=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000225 | 533 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | defender=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000226 | 534 | 6 | - | Lorehold | combat | target=Rowan, Scion of War #32 (real) | ok | - |
| action-000227 | 535 | 6 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000228 | 536 | 6 | - | Lorehold | combat_result | target=Rowan, Scion of War #32 (real) | ok | damage=-; target_life=- |
| action-000229 | 537 | 6 | - | Lorehold | combat_step | target=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000230 | 538 | 6 | - | Lorehold | combat_result | target=Kinnan, Bonder Prodigy #72 (real) | ok | damage=-; target_life=- |
| action-000231 | 539 | 6 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000232 | 540 | 6 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #63 (real) | ok | damage=-; target_life=- |
| action-000233 | 541 | 6 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000234 | 548 | 6 | - | Lorehold | turn_end | - | ok | hand=6; board=9; grave=2 |
| action-000235 | 549 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=32; hand=4 |
| action-000236 | 552 | 6 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Boreal Druid | ok | card=Boreal Druid; cost={'colored': {'green': 1}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=4->3; life=32->32 |
| action-000237 | 553 | 6 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | spell_cast | Boreal Druid | ok | rule=functional_tags_json/heuristic; effect=ramp_permanent; decision=decision-000084 |
| action-000238 | 555 | 6 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Gilded Drake | ok | card=Gilded Drake; cost={'colored': {'blue': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=3->1; life=32->32 |
| action-000239 | 556 | 6 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | creature_cast | Gilded Drake | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000085 |
| action-000240 | 561 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000241 | 562 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000242 | 563 | 6 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000243 | 564 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat | target=Lorehold | ok | - |
| action-000244 | 565 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000245 | 566 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000246 | 567 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000247 | 572 | 6 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=3; board=7; grave=4 |
| action-000248 | 573 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=36; hand=3 |
| action-000249 | 575 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | land_played | Polluted Delta | ok | rule=curated/verified; effect=land |
| action-000250 | 578 | 6 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Brain Freeze | ok | card=Brain Freeze; cost={'colored': {'blue': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->2; life=35->35 |
| action-000251 | 579 | 6 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Brain Freeze | ok | rule=curated/verified; effect=brain_freeze; decision=decision-000090 |
| action-000252 | 580 | 6 | - | Lorehold | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_noncreature_spell; stack=4 |
| action-000253 | 585 | 6 | precombat_main | Lorehold | trigger_resolved | Esper Sentinel | ok | - |
| action-000254 | 590 | 6 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_resolved | Brain Freeze | ok | rule=curated/verified; effect=brain_freeze; resolved_from_stack=True; destination=graveyard |
| action-000255 | 596 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000256 | 597 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000257 | 598 | 6 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000258 | 599 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat | target=Lorehold | ok | - |
| action-000259 | 600 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000260 | 601 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000261 | 602 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000262 | 603 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000263 | 608 | 6 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=2; board=6; grave=8 |
| action-000264 | 609 | 6 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=19; hand=5 |
| action-000265 | 613 | 6 | precombat_main | Rowan, Scion of War #32 (real) | cost_paid | Rowan, Scion of War | ok | card=Rowan, Scion of War; cost={'colored': {'black': 1, 'red': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=5->2; life=19->19 |
| action-000266 | 614 | 6 | precombat_main | Rowan, Scion of War #32 (real) | commander_cast | Rowan, Scion of War | ok | rule=type_line_creature/fact; effect=creature; decision=decision-000094 |
| action-000267 | 619 | 6 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000268 | 620 | 6 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000269 | 621 | 6 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000270 | 622 | 6 | - | Rowan, Scion of War #32 (real) | combat | target=Lorehold | ok | - |
| action-000271 | 623 | 6 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000272 | 624 | 6 | - | Rowan, Scion of War #32 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000273 | 625 | 6 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000274 | 630 | 6 | - | Rowan, Scion of War #32 (real) | turn_end | - | ok | hand=6; board=7; grave=1 |
| action-000275 | 631 | 7 | - | Lorehold | turn_start | - | ok | life=15; hand=6 |
| action-000276 | 637 | 7 | - | Lorehold | land_played | Mountain // Mountain | ok | rule=curated/verified; effect=land |
| action-000277 | 639 | 7 | precombat_main | Lorehold | cost_paid | Lorehold, the Historian | ok | card=Lorehold, the Historian; cost={'colored': {'red': 1, 'white': 1}, 'generic': 3, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=5->0; life=15->15 |
| action-000278 | 640 | 7 | precombat_main | Lorehold | commander_cast | Lorehold, the Historian | ok | rule=curated/active; effect=passive; decision=decision-000098 |
| action-000279 | 646 | 7 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000280 | 647 | 7 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000281 | 648 | 7 | - | Lorehold | multi_defender_attack | - | ok | - |
| action-000282 | 649 | 7 | - | Rowan, Scion of War #32 (real) | combat_step | defender=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000283 | 650 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | defender=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000284 | 651 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | defender=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000285 | 652 | 7 | - | Lorehold | combat | target=Rowan, Scion of War #32 (real) | ok | - |
| action-000286 | 653 | 7 | - | Lorehold | combat_step | target=Rowan, Scion of War #32 (real) | ok | target=Rowan, Scion of War #32 (real); power=- |
| action-000287 | 654 | 7 | - | Lorehold | combat_result | target=Rowan, Scion of War #32 (real) | ok | damage=-; target_life=- |
| action-000288 | 655 | 7 | - | Lorehold | combat_step | target=Kinnan, Bonder Prodigy #72 (real) | ok | target=Kinnan, Bonder Prodigy #72 (real); power=- |
| action-000289 | 656 | 7 | - | Lorehold | combat_result | target=Kinnan, Bonder Prodigy #72 (real) | ok | damage=-; target_life=- |
| action-000290 | 657 | 7 | - | Lorehold | combat_step | target=Rograkh, Son of Rohgahh #63 (real) | ok | target=Rograkh, Son of Rohgahh #63 (real); power=- |
| action-000291 | 658 | 7 | - | Lorehold | combat_result | target=Rograkh, Son of Rohgahh #63 (real) | ok | damage=-; target_life=- |
| action-000292 | 659 | 7 | - | Lorehold | combat_step | - | ok | target=-; power=- |
| action-000293 | 666 | 7 | - | Lorehold | turn_end | - | ok | hand=7; board=11; grave=5 |
| action-000294 | 667 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | turn_start | - | ok | life=27; hand=3 |
| action-000295 | 670 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | land_played | Seat of the Synod | ok | rule=curated/verified; effect=land |
| action-000296 | 672 | 7 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | cost_paid | Kinnan, Bonder Prodigy | ok | card=Kinnan, Bonder Prodigy; cost={'colored': {'blue': 1, 'green': 1}, 'generic': 4, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['creature_spell']}; mana=6->0; life=27->27 |
| action-000297 | 673 | 7 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | commander_cast | Kinnan, Bonder Prodigy | ok | rule=curated/verified; effect=creature; decision=decision-000103 |
| action-000298 | 678 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000299 | 679 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000300 | 680 | 7 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000301 | 681 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat | target=Lorehold | ok | - |
| action-000302 | 682 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000303 | 683 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000304 | 684 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | combat_step | - | ok | target=-; power=- |
| action-000305 | 689 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | turn_end | - | ok | hand=3; board=9; grave=4 |
| action-000306 | 690 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | turn_start | - | ok | life=33; hand=2 |
| action-000307 | 694 | 7 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | cost_paid | Snap | ok | card=Snap; cost={'colored': {'blue': 1}, 'generic': 1, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=4->2; life=33->33 |
| action-000308 | 695 | 7 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_cast | Snap | ok | rule=curated/verified; effect=remove_creature; target=Lorehold, the Historian; decision=decision-000108 |
| action-000309 | 696 | 7 | - | Lorehold | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_noncreature_spell; stack=5 |
| action-000310 | 701 | 7 | precombat_main | Lorehold | trigger_resolved | Esper Sentinel | ok | - |
| action-000311 | 706 | 7 | precombat_main | Rograkh, Son of Rohgahh #63 (real) | spell_resolved | Snap | ok | rule=curated/verified; effect=remove_creature; target=Lorehold, the Historian; resolved_from_stack=True; destination=graveyard |
| action-000312 | 707 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | removal_resolved | Snap | ok | - |
| action-000313 | 708 | 7 | - | ? | replacement_applied | Lorehold, the Historian | ok | card=Lorehold, the Historian; affected_player=Lorehold; source=Snap; reason=removal; zone=battlefield->command_zone; value=0->0; replacement_rule_source=commander_replacement_rule |
| action-000314 | 714 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000315 | 715 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000316 | 716 | 7 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000317 | 717 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat | target=Lorehold | ok | - |
| action-000318 | 718 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000319 | 719 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000320 | 720 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000321 | 721 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | combat_step | - | ok | target=-; power=- |
| action-000322 | 726 | 7 | - | Rograkh, Son of Rohgahh #63 (real) | turn_end | - | ok | hand=2; board=6; grave=9 |
| action-000323 | 727 | 7 | - | Rowan, Scion of War #32 (real) | turn_start | - | ok | life=13; hand=6 |
| action-000324 | 731 | 7 | precombat_main | Rowan, Scion of War #32 (real) | cost_paid | Torment of Hailfire | ok | card=Torment of Hailfire; cost={'colored': {'black': 2}, 'generic': 0, 'hybrid': [], 'monocolored_hybrid': [], 'phyrexian': [], 'phyrexian_hybrid': [], 'spend_tags': ['instant_or_sorcery_spell', 'noncreature_spell']}; mana=5->3; life=13->13 |
| action-000325 | 732 | 7 | precombat_main | Rowan, Scion of War #32 (real) | spell_cast | Torment of Hailfire | ok | rule=known_cards_canonical_snapshot/review_only; effect=passive; decision=decision-000112 |
| action-000326 | 733 | 7 | - | Lorehold | trigger_put_on_stack | Esper Sentinel | ok | source=Esper Sentinel; trigger=opponent_noncreature_spell; stack=6 |
| action-000327 | 738 | 7 | precombat_main | Lorehold | trigger_resolved | Esper Sentinel | ok | - |
| action-000328 | 743 | 7 | precombat_main | Rowan, Scion of War #32 (real) | spell_resolved | Torment of Hailfire | ok | rule=known_cards_canonical_snapshot/review_only; effect=passive; resolved_from_stack=True; destination=graveyard |
| action-000329 | 748 | 7 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000330 | 749 | 7 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000331 | 750 | 7 | - | Lorehold | combat_step | defender=Lorehold | ok | target=Lorehold; power=- |
| action-000332 | 751 | 7 | - | Rowan, Scion of War #32 (real) | combat | target=Lorehold | ok | - |
| action-000333 | 752 | 7 | - | Rowan, Scion of War #32 (real) | combat_step | target=Lorehold | ok | target=Lorehold; power=- |
| action-000334 | 753 | 7 | - | Rowan, Scion of War #32 (real) | combat_result | target=Lorehold | ok | damage=-; target_life=- |
| action-000335 | 754 | 7 | - | Rowan, Scion of War #32 (real) | combat_step | - | ok | target=-; power=- |
| action-000336 | 755 | 7 | - | Lorehold | player_eliminated | life_zero | ok | reason=life_zero |
| action-000337 | 756 | 7 | - | Kinnan, Bonder Prodigy #72 (real) | game_won | elimination | ok | winner=Kinnan, Bonder Prodigy #72 (real) |
