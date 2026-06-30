# Commander Deckbuilding Flow Research Audit

- Generated at: `2026-06-30T17:33:55.410346+00:00`
- Status: `pass`

## External Learning Imported

| Source | Imported Learning | URL |
| --- | --- | --- |
| Wizards Commander format page | official 99+1, singleton, color identity, multiplayer, and bracket framing | https://magic.wizards.com/en/formats/commander |
| EDHREC How to Build a Commander Deck | start from card categories and test whether the list plays as intended | https://edhrec.com/articles/how-to-build-a-commander-deck |
| The Command Zone template via EDHREC | balance ramp, card draw, disruption, and other core ratios | https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering |
| EDHREC Ramp in Commander | ramp quality depends on curve, commander mana value, and timing | https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander |
| EDHREC Top/Staples | global staple popularity is a floor and consistency signal, not commander-specific truth | https://edhrec.com/top |
| BinderBrew Commander template | core slots come before commander-specific payoffs and then tune by table/budget | https://binderbrew.com/commander-deck-building-template |
| Card Kingdom ramp/draw article | ramp, draw, removal, and recursion are structural pillars | https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/ |
| Commander Spellbook | use combo search for deterministic lines and variants, not overall deck balance | https://commanderspellbook.com/ |

## Flow

1. `format_legality_and_power_bracket`
2. `commander_intent_and_archetype`
3. `primary_and_backup_win_plan`
4. `mana_foundation_and_curve`
5. `card_flow_and_resource_engine`
6. `interaction_protection_and_resilience`
7. `commander_specific_packages`
8. `combo_synergy_and_finishers`
9. `reference_corpus_and_learned_usage`
10. `staple_impact_and_role_policy`
11. `lane_balanced_cuts_and_anchor_protection`
12. `goldfish_battle_replay_iteration`

## Checks

| Status | Check | Missing |
| --- | --- | --- |
| pass | `contract_has_researched_flow` |  |
| pass | `backend_exposes_planning_flow` |  |
| pass | `tests_lock_planning_flow` |  |
| pass | `source_learning_wizards_commander_format_page` |  |
| pass | `source_learning_edhrec_how_to_build_a_commander_deck` |  |
| pass | `source_learning_the_command_zone_template_via_edhrec` |  |
| pass | `source_learning_edhrec_ramp_in_commander` |  |
| pass | `source_learning_edhrec_top/staples` |  |
| pass | `source_learning_binderbrew_commander_template` |  |
| pass | `source_learning_card_kingdom_ramp/draw_article` |  |
| pass | `source_learning_commander_spellbook` |  |
