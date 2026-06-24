BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg160_topdeck_tutors_20260624_092630 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('vampiric tutor', 'imperial seal', 'mystical tutor', 'worldly tutor')
   OR normalized_name LIKE 'vampiric tutor // %'
   OR normalized_name LIKE 'imperial seal // %'
   OR normalized_name LIKE 'mystical tutor // %'
   OR normalized_name LIKE 'worldly tutor // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('vampiric tutor', 'Vampiric Tutor', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:0d42202d79e9f7e0b0a65fe5848c9849', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":true,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VampiricTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('imperial seal', 'Imperial Seal', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:e8c744eeb299cbecc7234defb18d79ca', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":false,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImperialSeal mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mystical tutor', 'Mystical Tutor', '6a72f3c0228efaa3bb3bb616122ed036', 'battle_rule_v1:1252b9a6b4188206efa3cf5c921afaa3', '{"ability_kind":"one_shot","battle_model_scope":"instant_or_sorcery_tutor_to_top_v1","effect":"tutor","instant":true,"target":"instant_or_sorcery_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticalTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('worldly tutor', 'Worldly Tutor', '0d52403c7394f384077c7ddcfdd9fa12', 'battle_rule_v1:ac383562ba9547c71a9bb6932cf907b8', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_top_v1","effect":"tutor","instant":true,"target":"creature_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WorldlyTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('vampiric tutor', 'Vampiric Tutor', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:0d42202d79e9f7e0b0a65fe5848c9849', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":true,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VampiricTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('imperial seal', 'Imperial Seal', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:e8c744eeb299cbecc7234defb18d79ca', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":false,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImperialSeal mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mystical tutor', 'Mystical Tutor', '6a72f3c0228efaa3bb3bb616122ed036', 'battle_rule_v1:1252b9a6b4188206efa3cf5c921afaa3', '{"ability_kind":"one_shot","battle_model_scope":"instant_or_sorcery_tutor_to_top_v1","effect":"tutor","instant":true,"target":"instant_or_sorcery_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticalTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('worldly tutor', 'Worldly Tutor', '0d52403c7394f384077c7ddcfdd9fa12', 'battle_rule_v1:ac383562ba9547c71a9bb6932cf907b8', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_top_v1","effect":"tutor","instant":true,"target":"creature_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WorldlyTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('vampiric tutor', 'Vampiric Tutor', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:0d42202d79e9f7e0b0a65fe5848c9849', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":true,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VampiricTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('imperial seal', 'Imperial Seal', '7418e11fcf0c0158d2b754402dfaac8e', 'battle_rule_v1:e8c744eeb299cbecc7234defb18d79ca', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_top_lose_two_life_v1","controller_loses_life_after_tutor":2,"effect":"tutor","instant":false,"target":"any_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImperialSeal mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mystical tutor', 'Mystical Tutor', '6a72f3c0228efaa3bb3bb616122ed036', 'battle_rule_v1:1252b9a6b4188206efa3cf5c921afaa3', '{"ability_kind":"one_shot","battle_model_scope":"instant_or_sorcery_tutor_to_top_v1","effect":"tutor","instant":true,"target":"instant_or_sorcery_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MysticalTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('worldly tutor', 'Worldly Tutor', '0d52403c7394f384077c7ddcfdd9fa12', 'battle_rule_v1:ac383562ba9547c71a9bb6932cf907b8', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_top_v1","effect":"tutor","instant":true,"target":"creature_to_top"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WorldlyTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    p.notes
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
