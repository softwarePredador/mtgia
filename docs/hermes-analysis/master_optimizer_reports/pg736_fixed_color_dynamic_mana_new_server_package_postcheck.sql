WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('karametra''s acolyte', 'Karametra''s Acolyte', '86ef6a0e66d69ce98708d5ce0b56042b', 'battle_rule_v1:dd227cb6ed995b861940b1a20fd98c61', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"devotion_to_green","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{3}{G}","source_type_line":"Creature \u2014 Human Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KarametrasAcolyte translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magus of the coffers', 'Magus of the Coffers', '67510b2a763e30208e8994fe303f2aa8', 'battle_rule_v1:b062dff12fc4c68a00586a403c0d2a17', '{"ability_kind":"activated_mana","activation_mana_cost":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"controller_battlefield","dynamic_mana_battlefield_count_subtypes":["swamp"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"B","source_mana_cost":"{4}{B}","source_type_line":"Creature \u2014 Human Wizard","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagusOfTheCoffers translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of titania', 'Priest of Titania', '6e8046fc4e2e3861e3c4640df24c7a58', 'battle_rule_v1:444642bee4291bcee2fa0714a3de442d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"battlefield_permanent_count","dynamic_mana_battlefield_count_scope":"all_battlefield","dynamic_mana_battlefield_count_subtypes":["elf"],"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{1}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfTitania translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viridian joiner', 'Viridian Joiner', '314025c76fd5612c62ec3a071d193fd4', 'battle_rule_v1:5184680f67f1492cf91f168740b71798', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_fixed_color_dynamic_mana_source_permanent_v1","dynamic_mana_amount_source":"source_power","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"G","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Druid","xmage_ability_classes":["DynamicManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["DynamicManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViridianJoiner translated into ManaLoom runtime scope xmage_fixed_color_dynamic_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg736_fixed_color_dynamic_mana_new_serve_20260711_025659) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
