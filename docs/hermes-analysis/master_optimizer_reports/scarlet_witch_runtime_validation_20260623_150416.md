# The Scarlet Witch Runtime Validation

- generated_at: `2026-06-23T18:04:17.213265+00:00`
- mutations_performed: `[]`
- xmage_path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheScarletWitch.java`
- scope: `static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1`

## Cases

### mv4_sorcery_reduced_by_source_power
- spell: `Red Audit Sorcery` `{3}{R}` `Sorcery` cmc=`4`
- locked_cost: `{"colored": {"red": 1}, "generic": 1, "hybrid": [], "monocolored_hybrid": [], "phyrexian": [], "phyrexian_hybrid": [], "spend_tags": ["instant_or_sorcery_spell", "noncreature_spell"], "static_cost_reduction_total": 2, "static_cost_reductions": [{"amount": 2, "amount_source": "source_power", "applied_amount": 2, "applies_to_card_types": ["instant", "sorcery"], "colors": [], "minimum_mana_value": 4, "scope": "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1", "source": "The Scarlet Witch"}]}`
- commit_result: `True`
- available_mana_after_commit: `0`

### mv3_instant_not_reduced
- spell: `Small Red Audit Instant` `{2}{R}` `Instant` cmc=`3`
- locked_cost: `{"colored": {"red": 1}, "generic": 2, "hybrid": [], "monocolored_hybrid": [], "phyrexian": [], "phyrexian_hybrid": [], "spend_tags": ["instant_or_sorcery_spell", "noncreature_spell"]}`
- commit_result: `False`
- available_mana_after_commit: `1`

### mv4_creature_not_reduced
- spell: `Large Red Audit Creature` `{3}{R}` `Creature` cmc=`4`
- locked_cost: `{"colored": {"red": 1}, "generic": 3, "hybrid": [], "monocolored_hybrid": [], "phyrexian": [], "phyrexian_hybrid": [], "spend_tags": ["creature_spell"]}`
- commit_result: `False`
- available_mana_after_commit: `1`
