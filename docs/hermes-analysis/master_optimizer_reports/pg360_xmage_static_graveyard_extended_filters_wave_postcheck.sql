WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('runaway trash-bot', 'Runaway Trash-Bot', '3e2e7609e4267fc6e89824d487e207a1', 'battle_rule_v1:913735c6f27a40d02848b0feb763d625', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["artifact","enchantment"],"graveyard_count_scope":"controller_graveyard","keywords":["trample"],"static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":0,"target":"self","target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RunawayTrashBot translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('xande, dark mage', 'Xande, Dark Mage', '7492ac3535b38c79b1b59cece65be02a', 'battle_rule_v1:4e025c36a4e055acfdf8f7f974c35192', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_equal_graveyard_count_v1","effect":"creature","graveyard_count_card_types":["noncreature_nonland"],"graveyard_count_scope":"controller_graveyard","keywords":["menace"],"menace":true,"static_effect":"source_power_toughness_boost_equal_graveyard_count","static_power_bonus_per_graveyard_count":1,"static_toughness_bonus_per_graveyard_count":1,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class XandeDarkMage translated into ManaLoom runtime scope xmage_static_source_boost_equal_graveyard_count_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost equal to graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg360_xmage_static_graveyard_extended_filters_wave_20260) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
