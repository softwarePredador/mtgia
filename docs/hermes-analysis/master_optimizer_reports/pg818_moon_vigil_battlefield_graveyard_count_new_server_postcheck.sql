WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('moon-vigil adherents', 'Moon-Vigil Adherents', '9cee561f4c31037d7e00016470bc710f', 'battle_rule_v1:6977607d38bfd0e099168453a2429947', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","keywords":["trample"],"stat_modifier_amount_source":"battlefield_plus_graveyard_card_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"battlefield_plus_graveyard_card_count","target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MoonVigilAdherents translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg818_moon_vigil_battlefield_graveyard_c_20260712_081746) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
