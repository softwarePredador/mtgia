WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('citanul stalwart', 'Citanul Stalwart', '7e8765a64a1d3c8775914745ee280f8d', 'battle_rule_v1:ab258dce31ac650782de9f06e8036162', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"artifact_or_creature","mana_produced":1,"mana_source_requires_untapped_artifact_or_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CitanulStalwart translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jaspera sentinel', 'Jaspera Sentinel', 'a9e1a252d2d06280c9f7a5f4b2ba213f', 'battle_rule_v1:53fddee02366902e529f36face750f2d', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["reach"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","ReachAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JasperaSentinel translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam dryad', 'Loam Dryad', 'bc0d67ab4c23dc0ffed1100c30eac1d5', 'battle_rule_v1:4d6e4eddb7fc0a7a794f0af96f4f5fe5', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamDryad translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saruli caretaker', 'Saruli Caretaker', '0b9879abab7f49482456a5969bbeabd2', 'battle_rule_v1:6cf57a838d0947fad3c0c9b6e13f9014', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":true,"mana_activation_tap_support_count":1,"mana_activation_tap_support_type":"creature","mana_produced":1,"mana_source_requires_untapped_creature":true,"mana_source_support_can_include_source":false,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":[],"xmage_mana_ability_classes":["AnyColorManaAbility","DefenderAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaruliCaretaker translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg743_mana_source_support_cost_new_serve_20260711_055411) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
