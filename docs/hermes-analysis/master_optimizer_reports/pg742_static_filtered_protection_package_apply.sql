BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg742_static_filtered_protection_20260711_052106 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('enemy of the guildpact', 'guardian of the guildpact', 'mistmeadow skulk', 'warren-scourge elf')
   OR normalized_name LIKE 'enemy of the guildpact // %'
   OR normalized_name LIKE 'guardian of the guildpact // %'
   OR normalized_name LIKE 'mistmeadow skulk // %'
   OR normalized_name LIKE 'warren-scourge elf // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('enemy of the guildpact', 'Enemy of the Guildpact', 'cd1d44d04de0397a22c65b802740a2d1', 'battle_rule_v1:2a8232286b6b473126a81d5f3696ffba', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"multicolored","protection_from_color_profile":"multicolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnemyOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of the guildpact', 'Guardian of the Guildpact', '6db300085ae20d24e50370ea523fd3ff', 'battle_rule_v1:ba763549dc3ab9cc7a3df072b0d5f6cc', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"monocolored","protection_from_color_profile":"monocolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistmeadow skulk', 'Mistmeadow Skulk', '68ade6cbc5d9e6fd742fffa9aa9de5eb', 'battle_rule_v1:335843a14f97a88cee79ec82f82c4600', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","keywords":["lifelink"],"lifelink":true,"protection_filter":"mana_value_gte","protection_from_mana_value_min":3,"static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistmeadowSkulk translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warren-scourge elf', 'Warren-Scourge Elf', '05409a998adab6569dded35c77248cde', 'battle_rule_v1:d8530a0ec0e100d63494854d035f7a2e', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["goblin"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarrenScourgeElf translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('enemy of the guildpact', 'Enemy of the Guildpact', 'cd1d44d04de0397a22c65b802740a2d1', 'battle_rule_v1:2a8232286b6b473126a81d5f3696ffba', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"multicolored","protection_from_color_profile":"multicolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnemyOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of the guildpact', 'Guardian of the Guildpact', '6db300085ae20d24e50370ea523fd3ff', 'battle_rule_v1:ba763549dc3ab9cc7a3df072b0d5f6cc', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","protection_filter":"monocolored","protection_from_color_profile":"monocolored","static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfTheGuildpact translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistmeadow skulk', 'Mistmeadow Skulk', '68ade6cbc5d9e6fd742fffa9aa9de5eb', 'battle_rule_v1:335843a14f97a88cee79ec82f82c4600', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_filtered_creature_v1","effect":"creature","keywords":["lifelink"],"lifelink":true,"protection_filter":"mana_value_gte","protection_from_mana_value_min":3,"static_effect":"self_protection_from_filtered","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistmeadowSkulk translated into ManaLoom runtime scope xmage_static_self_protection_from_filtered_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warren-scourge elf', 'Warren-Scourge Elf', '05409a998adab6569dded35c77248cde', 'battle_rule_v1:d8530a0ec0e100d63494854d035f7a2e', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["goblin"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarrenScourgeElf translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
