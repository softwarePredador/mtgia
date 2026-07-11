WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('enemy of the guildpact', 'Enemy of the Guildpact', 'cd1d44d04de0397a22c65b802740a2d1', 'battle_rule_v1:2a8232286b6b473126a81d5f3696ffba', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"multicolored","protection_from_color_profile":"multicolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnemyOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of the guildpact', 'Guardian of the Guildpact', '6db300085ae20d24e50370ea523fd3ff', 'battle_rule_v1:ba763549dc3ab9cc7a3df072b0d5f6cc', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"monocolored","protection_from_color_profile":"monocolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistmeadow skulk', 'Mistmeadow Skulk', '68ade6cbc5d9e6fd742fffa9aa9de5eb', 'battle_rule_v1:335843a14f97a88cee79ec82f82c4600', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","keywords":["lifelink"],"lifelink":true,"protection_filter":"mana_value_gte","protection_from_mana_value_min":3,"static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistmeadowSkulk translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warren-scourge elf', 'Warren-Scourge Elf', '05409a998adab6569dded35c77248cde', 'battle_rule_v1:d8530a0ec0e100d63494854d035f7a2e', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["goblin"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarrenScourgeElf translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg742_static_filtered_protection_20260711_052106) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
