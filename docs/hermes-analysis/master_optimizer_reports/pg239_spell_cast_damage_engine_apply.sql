BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg239_spell_cast_damage_engine_20260626_101944 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('longshot, rebel bowman', 'guttersnipe', 'coruscation mage', 'fiery inscription', 'vivi ornitier')
   OR normalized_name LIKE 'longshot, rebel bowman // %'
   OR normalized_name LIKE 'guttersnipe // %'
   OR normalized_name LIKE 'coruscation mage // %'
   OR normalized_name LIKE 'fiery inscription // %'
   OR normalized_name LIKE 'vivi ornitier // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('longshot, rebel bowman', 'Longshot, Rebel Bowman', '262ee0e8c9dd03d7ef792501201f0df9', 'battle_rule_v1:17f2c09b361ae9a707f4c27cece88bd0', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":3,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LongshotRebelBowman mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('guttersnipe', 'Guttersnipe', 'f80fdc6153bf00a2198027bfa8b326db', 'battle_rule_v1:5b634b726647d3bd833233759968be5a', '{"ability_kind":"triggered","battle_model_scope":"spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Guttersnipe mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('coruscation mage', 'Coruscation Mage', '825fa07365c51b116f5b708afc4f15ed', 'battle_rule_v1:e3aad3351d48453dc40be9bc1a246917', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CoruscationMage mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fiery inscription', 'Fiery Inscription', '78584ef3b8696dacc27441e4952b68f1', 'battle_rule_v1:1bd00fa75c597d366720ac22dd18a8fd', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"instant_sorcery_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FieryInscription mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('vivi ornitier', 'Vivi Ornitier', 'f2eaad7fdd9f97fcb314e495fd4f4a4e', 'battle_rule_v1:6a804c9cfcf1b619a6ea8f29e18b790a', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":0,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ViviOrnitier mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('longshot, rebel bowman', 'Longshot, Rebel Bowman', '262ee0e8c9dd03d7ef792501201f0df9', 'battle_rule_v1:17f2c09b361ae9a707f4c27cece88bd0', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":3,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LongshotRebelBowman mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('guttersnipe', 'Guttersnipe', 'f80fdc6153bf00a2198027bfa8b326db', 'battle_rule_v1:5b634b726647d3bd833233759968be5a', '{"ability_kind":"triggered","battle_model_scope":"spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Guttersnipe mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('coruscation mage', 'Coruscation Mage', '825fa07365c51b116f5b708afc4f15ed', 'battle_rule_v1:e3aad3351d48453dc40be9bc1a246917', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CoruscationMage mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fiery inscription', 'Fiery Inscription', '78584ef3b8696dacc27441e4952b68f1', 'battle_rule_v1:1bd00fa75c597d366720ac22dd18a8fd', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"instant_sorcery_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FieryInscription mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('vivi ornitier', 'Vivi Ornitier', 'f2eaad7fdd9f97fcb314e495fd4f4a4e', 'battle_rule_v1:6a804c9cfcf1b619a6ea8f29e18b790a', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":0,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ViviOrnitier mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('longshot, rebel bowman', 'Longshot, Rebel Bowman', '262ee0e8c9dd03d7ef792501201f0df9', 'battle_rule_v1:17f2c09b361ae9a707f4c27cece88bd0', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":3,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LongshotRebelBowman mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('guttersnipe', 'Guttersnipe', 'f80fdc6153bf00a2198027bfa8b326db', 'battle_rule_v1:5b634b726647d3bd833233759968be5a', '{"ability_kind":"triggered","battle_model_scope":"spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Guttersnipe mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('coruscation mage', 'Coruscation Mage', '825fa07365c51b116f5b708afc4f15ed', 'battle_rule_v1:e3aad3351d48453dc40be9bc1a246917', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CoruscationMage mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fiery inscription', 'Fiery Inscription', '78584ef3b8696dacc27441e4952b68f1', 'battle_rule_v1:1bd00fa75c597d366720ac22dd18a8fd', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"instant_sorcery_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FieryInscription mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('vivi ornitier', 'Vivi Ornitier', 'f2eaad7fdd9f97fcb314e495fd4f4a4e', 'battle_rule_v1:6a804c9cfcf1b619a6ea8f29e18b790a', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":0,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ViviOrnitier mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
