WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('celestial prism', 'Celestial Prism', 'd4fbeac453cff388c63c90d13b51a63b', 'battle_rule_v1:8abc926d110e8c26fb4143c78b705d4a', '{"activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CelestialPrism translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chromatic sphere', 'Chromatic Sphere', '9feea6f9709f43a5e6cebccf273b2ebc', 'battle_rule_v1:f3f232b22d73b373966715bfc102dc89', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage self-sacrifice mana ability is executable in this rule; listed auxiliary ability/effect classes and same-ability non-mana tails remain unmodeled.","_runtime_partial_sacrifice_mana_tail":"draw a card.","ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_class":"AnyColorManaAbility","xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_effect_classes":["DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChromaticSphere translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana cylix', 'Mana Cylix', 'e7da6ddd05e9302702b6f8a48bba9fd6', 'battle_rule_v1:5bddc6f173c531e5421b248587ad9200', '{"activation_mana_cost":"{1}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaCylix translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('manalith', 'Manalith', '2cb86f263cc7e5d235b1db55361d97ae', 'battle_rule_v1:a58e029d95561381bb71d4cea43788df', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Manalith translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian altar', 'Phyrexian Altar', 'b7c5a22696e90cd9ed2601073ce9551d', 'battle_rule_v1:37b8c3fa5a8d0e1058c9fa50c55f73fb', '{"ability_kind":"activated_mana","activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"creature","battle_model_scope":"xmage_target_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice_target":true,"mana_activation_requires_tap":false,"mana_produced":1,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility"],"xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeTargetCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianAltar translated into ManaLoom runtime scope xmage_target_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg596_any_color_mana_rock_alias_new_serv_20260707_052414) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
