WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('harvester druid', 'Harvester Druid', '9f540d1e11c82a5b4f6e4edfbc0b6e92', 'battle_rule_v1:fe64068eac1d183bb51c1467aebe641d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_land_color_dependent_mana_source_permanent_v1","conditionally_produces_controller_land_colors":true,"effect":"ramp_permanent","is_mana_source":true,"land_mana_dependency_allows_colorless":false,"land_mana_dependency_controller":"self","mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorLandsProduceManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorLandsProduceManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarvesterDruid translated into ManaLoom runtime scope xmage_simple_tap_land_color_dependent_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('naga vitalist', 'Naga Vitalist', 'd5147898bf9a0f7734782b2c557a01e8', 'battle_rule_v1:6ca9ca5eb412824f8cdc0139583e7d2f', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_land_color_dependent_mana_source_permanent_v1","conditionally_produces_controller_land_colors":true,"effect":"ramp_permanent","is_mana_source":true,"land_mana_dependency_allows_colorless":true,"land_mana_dependency_controller":"self","mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRGC","xmage_ability_classes":["AnyColorLandsProduceManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorLandsProduceManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NagaVitalist translated into ManaLoom runtime scope xmage_simple_tap_land_color_dependent_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quirion explorer', 'Quirion Explorer', 'd63befc8ac40d9a38732f9b5c1a7414a', 'battle_rule_v1:27c00f856175eeaad1cf5aea72d4f2bc', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_land_color_dependent_mana_source_permanent_v1","conditionally_produces_opponent_land_colors":true,"effect":"ramp_permanent","is_mana_source":true,"land_mana_dependency_allows_colorless":false,"land_mana_dependency_controller":"opponent","mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorLandsProduceManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorLandsProduceManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuirionExplorer translated into ManaLoom runtime scope xmage_simple_tap_land_color_dependent_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sylvok explorer', 'Sylvok Explorer', 'd63befc8ac40d9a38732f9b5c1a7414a', 'battle_rule_v1:27c00f856175eeaad1cf5aea72d4f2bc', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_land_color_dependent_mana_source_permanent_v1","conditionally_produces_opponent_land_colors":true,"effect":"ramp_permanent","is_mana_source":true,"land_mana_dependency_allows_colorless":false,"land_mana_dependency_controller":"opponent","mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorLandsProduceManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorLandsProduceManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SylvokExplorer translated into ManaLoom runtime scope xmage_simple_tap_land_color_dependent_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg735_land_color_mana_new_server_20260711_024205) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
