WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gnarlwood dryad', 'Gnarlwood Dryad', '931248cb730afdeffa72975c843822b8', 'battle_rule_v1:86d2e2c36b3bec8ff5dd9be436cf3dae', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","deathtouch":true,"effect":"creature","graveyard_count_card_types":["card_type"],"graveyard_count_mode":"distinct_card_types","graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"keywords":["deathtouch"],"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GnarlwoodDryad translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moldgraf scavenger', 'Moldgraf Scavenger', '75a9e03fe95688a3b46eedb435597e3b', 'battle_rule_v1:737bfeb625f5b9540007a1aefbfa9685', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card_type"],"graveyard_count_mode":"distinct_card_types","graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":3,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MoldgrafScavenger translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg636_delirium_threshold_boost_new_serve_20260707_201340) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
