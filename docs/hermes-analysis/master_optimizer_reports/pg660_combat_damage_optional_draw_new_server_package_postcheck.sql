WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('academy raider', 'Academy Raider', '3e46e09ecb55365da7e4dd2e732481fe', 'battle_rule_v1:a4d063281c448f4bec8585f7e7dcb67b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_draw_optional":true,"combat_damage_draw_optional_cost":"discard_card","combat_damage_draw_optional_cost_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","intimidate":true,"keywords":["intimidate"],"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcademyRaider translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impaler shrike', 'Impaler Shrike', '6156a6fef3833f7cf07af940eb2d4444', 'battle_rule_v1:8af13cd3416861af948a408a70633ecf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":3,"combat_damage_draw_optional":true,"combat_damage_draw_optional_cost":"sacrifice_source","combat_damage_draw_optional_cost_count":1,"combat_damage_player_draw":true,"draw_count":3,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpalerShrike translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg660_combat_damage_optional_draw_new_se_20260708_142516) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
