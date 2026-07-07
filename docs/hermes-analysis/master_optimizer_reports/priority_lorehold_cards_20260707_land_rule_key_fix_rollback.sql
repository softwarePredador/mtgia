BEGIN;

UPDATE public.card_battle_rules
SET logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be',
    updated_at = CURRENT_TIMESTAMP
WHERE normalized_name = 'command tower'
  AND logical_rule_key = 'battle_rule_v1:8a974d0b2c767176f8066c7932447896'
  AND effect_json->>'battle_model_scope' = 'commander_identity_land_mana_source_v1';

UPDATE public.card_battle_rules
SET logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be',
    updated_at = CURRENT_TIMESTAMP
WHERE normalized_name = 'turbulent steppe'
  AND logical_rule_key = 'battle_rule_v1:a614845f052c61eaa22e619e7b288e17'
  AND effect_json->>'battle_model_scope' = 'land_enters_tapped_unless_opponents_control_lands_count_mana_source_v1';

COMMIT;
