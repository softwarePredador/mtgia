WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('adamaro, first to desire', 'Adamaro, First to Desire', 'f8a897b7ec5cc444b666fc52362a5261', 'battle_rule_v1:951695ee91b1beff938cc9b0260ccabf', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"opponent_max_hand_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"opponent_max_hand_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdamaroFirstToDesire translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maro', 'Maro', '88729c402888815a70e5ba2cf0a2b266', 'battle_rule_v1:7a6ac98595448a90c5be6ce4fe95cb03', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controller_hand_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"controller_hand_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Maro translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('masumaro, first to live', 'Masumaro, First to Live', 'b5eb2ac7602a08a549cccedacb4e17c4', 'battle_rule_v1:32eadb1d269955a7aff13bd501840668', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","stat_modifier_amount_source":"controller_hand_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":2,"static_power_toughness_source":"controller_hand_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MasumaroFirstToLive translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('multani, maro-sorcerer', 'Multani, Maro-Sorcerer', 'f301834c308f04da7735eedfd9e3864a', 'battle_rule_v1:6838948687551b209751bd8e3ee8ec44', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_power_toughness_equal_count_v1","dynamic_power_equals_count":true,"dynamic_toughness_equals_count":true,"effect":"creature","keywords":["shroud"],"shroud":true,"stat_modifier_amount_source":"all_players_hand_count","static_effect":"source_power_toughness_equal_count","static_power_toughness_base":0,"static_power_toughness_count_multiplier":1,"static_power_toughness_source":"all_players_hand_count","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"SetBasePowerToughnessSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MultaniMaroSorcerer translated into ManaLoom runtime scope xmage_static_source_power_toughness_equal_count_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg600_static_hand_count_pt_new_server_pg_20260707_070624) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
