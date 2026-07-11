WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('enemy of the guildpact', 'Enemy of the Guildpact', 'cd1d44d04de0397a22c65b802740a2d1', 'battle_rule_v1:2a8232286b6b473126a81d5f3696ffba', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"multicolored","protection_from_color_profile":"multicolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnemyOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of the guildpact', 'Guardian of the Guildpact', '6db300085ae20d24e50370ea523fd3ff', 'battle_rule_v1:ba763549dc3ab9cc7a3df072b0d5f6cc', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"monocolored","protection_from_color_profile":"monocolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistmeadow skulk', 'Mistmeadow Skulk', '68ade6cbc5d9e6fd742fffa9aa9de5eb', 'battle_rule_v1:335843a14f97a88cee79ec82f82c4600', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","keywords":["lifelink"],"lifelink":true,"protection_filter":"mana_value_gte","protection_from_mana_value_min":3,"static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistmeadowSkulk translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warren-scourge elf', 'Warren-Scourge Elf', '05409a998adab6569dded35c77248cde', 'battle_rule_v1:d8530a0ec0e100d63494854d035f7a2e', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["goblin"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarrenScourgeElf translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
