WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('first-time flyer', 'First-Time Flyer', 'bf16345caaaeec75bb000710167e3393', 'battle_rule_v1:5763612792e355d4e1307a7036bd7557', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","flying":true,"graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["lesson"],"graveyard_count_threshold":1,"keywords":["flying"],"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":1,"static_toughness_bonus":1,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirstTimeFlyer translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('syndicate infiltrator', 'Syndicate Infiltrator', 'fed0c52056fb74acc7b7f3354590a0db', 'battle_rule_v1:924726af62106442e2b37a6b53dcf238', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","flying":true,"graveyard_count_card_types":["card"],"graveyard_count_mode":"distinct_mana_values","graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":5,"keywords":["flying"],"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SyndicateInfiltrator translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg817_graveyard_threshold_subtype_mana_v_20260712_080836) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
