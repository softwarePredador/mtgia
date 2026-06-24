BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg173_x_tutor_battlefield_spells_20260624_123404 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('nature''s rhythm', 'chord of calling', 'green sun''s zenith', 'whir of invention')
   OR normalized_name LIKE 'nature''s rhythm // %'
   OR normalized_name LIKE 'chord of calling // %'
   OR normalized_name LIKE 'green sun''s zenith // %'
   OR normalized_name LIKE 'whir of invention // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('nature''s rhythm', 'Nature''s Rhythm', '109e64b1ea27da04b6266d4e86b52aad', 'battle_rule_v1:6763f8258c7027a341e182900af5e8fc', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1","effect":"tutor","harmonize":true,"instant":false,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NaturesRhythm mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('chord of calling', 'Chord of Calling', '8399842a5c007c7f4b890bfdf3f84521', 'battle_rule_v1:1250cdd03a9389a2fe31e53ac5766394', '{"ability_kind":"one_shot","battle_model_scope":"convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1","convoke":true,"effect":"tutor","instant":true,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ChordOfCalling mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('green sun''s zenith', 'Green Sun''s Zenith', 'cfaabe0e9d9d20d134845c8f4b946e1e', 'battle_rule_v1:c1c56ae7a9b9e0cae540e39cecb4f157', '{"ability_kind":"one_shot","battle_model_scope":"green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1","effect":"tutor","instant":false,"shuffle_self_into_library_on_resolution":true,"target":"green_creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GreenSunsZenith mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('whir of invention', 'Whir of Invention', '47a15ce5ca279f509f387d3909695959', 'battle_rule_v1:719bc165cd6259a33d138d4fe2b1d2a2', '{"ability_kind":"one_shot","battle_model_scope":"improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1","effect":"tutor","improvise":true,"instant":true,"target":"artifact_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WhirOfInvention mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('nature''s rhythm', 'Nature''s Rhythm', '109e64b1ea27da04b6266d4e86b52aad', 'battle_rule_v1:6763f8258c7027a341e182900af5e8fc', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1","effect":"tutor","harmonize":true,"instant":false,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NaturesRhythm mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('chord of calling', 'Chord of Calling', '8399842a5c007c7f4b890bfdf3f84521', 'battle_rule_v1:1250cdd03a9389a2fe31e53ac5766394', '{"ability_kind":"one_shot","battle_model_scope":"convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1","convoke":true,"effect":"tutor","instant":true,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ChordOfCalling mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('green sun''s zenith', 'Green Sun''s Zenith', 'cfaabe0e9d9d20d134845c8f4b946e1e', 'battle_rule_v1:c1c56ae7a9b9e0cae540e39cecb4f157', '{"ability_kind":"one_shot","battle_model_scope":"green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1","effect":"tutor","instant":false,"shuffle_self_into_library_on_resolution":true,"target":"green_creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GreenSunsZenith mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('whir of invention', 'Whir of Invention', '47a15ce5ca279f509f387d3909695959', 'battle_rule_v1:719bc165cd6259a33d138d4fe2b1d2a2', '{"ability_kind":"one_shot","battle_model_scope":"improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1","effect":"tutor","improvise":true,"instant":true,"target":"artifact_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WhirOfInvention mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('nature''s rhythm', 'Nature''s Rhythm', '109e64b1ea27da04b6266d4e86b52aad', 'battle_rule_v1:6763f8258c7027a341e182900af5e8fc', '{"ability_kind":"one_shot","battle_model_scope":"creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1","effect":"tutor","harmonize":true,"instant":false,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NaturesRhythm mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('chord of calling', 'Chord of Calling', '8399842a5c007c7f4b890bfdf3f84521', 'battle_rule_v1:1250cdd03a9389a2fe31e53ac5766394', '{"ability_kind":"one_shot","battle_model_scope":"convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1","convoke":true,"effect":"tutor","instant":true,"target":"creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ChordOfCalling mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('green sun''s zenith', 'Green Sun''s Zenith', 'cfaabe0e9d9d20d134845c8f4b946e1e', 'battle_rule_v1:c1c56ae7a9b9e0cae540e39cecb4f157', '{"ability_kind":"one_shot","battle_model_scope":"green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1","effect":"tutor","instant":false,"shuffle_self_into_library_on_resolution":true,"target":"green_creature_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GreenSunsZenith mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('whir of invention', 'Whir of Invention', '47a15ce5ca279f509f387d3909695959', 'battle_rule_v1:719bc165cd6259a33d138d4fe2b1d2a2', '{"ability_kind":"one_shot","battle_model_scope":"improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1","effect":"tutor","improvise":true,"instant":true,"target":"artifact_to_battlefield","target_mana_value_max_from_x":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WhirOfInvention mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
