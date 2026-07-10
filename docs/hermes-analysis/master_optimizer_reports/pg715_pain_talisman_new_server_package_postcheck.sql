WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('talisman of hierarchy', 'Talisman of Hierarchy', 'c3f90c58fc890387f9608a3549409f43', 'battle_rule_v1:954458c0931b6437bede6a45cc70f7f9', '{"ability_kind":"activated","activation_requires_tap":true,"battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","is_mana_source":true,"life_for_colored_mana":1,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"CWB","xmage_ability_classes":["BlackManaAbility","ColorlessManaAbility","WhiteManaAbility"],"xmage_effect_classes":["DamageControllerEffect"],"xmage_mana_ability_classes":["BlackManaAbility","ColorlessManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalismanOfHierarchy translated into ManaLoom runtime scope pain_talisman_color_pair_partial_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('talisman of unity', 'Talisman of Unity', '4c305e3cd5e26bba34476b11bf0ba586', 'battle_rule_v1:19e359edcda29948ab87cec015062f41', '{"ability_kind":"activated","activation_requires_tap":true,"battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","is_mana_source":true,"life_for_colored_mana":1,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"CGW","xmage_ability_classes":["ColorlessManaAbility","GreenManaAbility","WhiteManaAbility"],"xmage_effect_classes":["DamageControllerEffect"],"xmage_mana_ability_classes":["ColorlessManaAbility","GreenManaAbility","WhiteManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalismanOfUnity translated into ManaLoom runtime scope pain_talisman_color_pair_partial_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg715_pain_talisman_new_server_20260710_190359) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
