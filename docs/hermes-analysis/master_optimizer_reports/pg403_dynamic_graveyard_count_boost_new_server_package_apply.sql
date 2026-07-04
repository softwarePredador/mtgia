BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg403_dynamic_graveyard_count_boost_new_server_20260704_ AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('festive funeral', 'ghoul''s feast')
   OR normalized_name LIKE 'festive funeral // %'
   OR normalized_name LIKE 'ghoul''s feast // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('festive funeral', 'Festive Funeral', '6e9fbabe708f04c9ed322448d4f409db', 'battle_rule_v1:3e4f67f3eb47bd397f83c59fd964d38c', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":-1,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestiveFuneral translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghoul''s feast', 'Ghoul''s Feast', '661b340dc8c9f7d884d1d203edb060b2', 'battle_rule_v1:b7cb7a49d1c68ef3a1d9889ac4853f8d', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":0,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulsFeast translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('festive funeral', 'Festive Funeral', '6e9fbabe708f04c9ed322448d4f409db', 'battle_rule_v1:3e4f67f3eb47bd397f83c59fd964d38c', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":-1,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestiveFuneral translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghoul''s feast', 'Ghoul''s Feast', '661b340dc8c9f7d884d1d203edb060b2', 'battle_rule_v1:b7cb7a49d1c68ef3a1d9889ac4853f8d', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":0,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulsFeast translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('festive funeral', 'Festive Funeral', '6e9fbabe708f04c9ed322448d4f409db', 'battle_rule_v1:3e4f67f3eb47bd397f83c59fd964d38c', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":-1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":-1,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FestiveFuneral translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghoul''s feast', 'Ghoul''s Feast', '661b340dc8c9f7d884d1d203edb060b2', 'battle_rule_v1:b7cb7a49d1c68ef3a1d9889ac4853f8d', '{"battle_model_scope":"xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot","graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":true,"power_base_delta":0,"power_delta_per_graveyard_count":1,"sorcery":false,"stat_modifier_amount_source":"graveyard_card_count","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_base_delta":0,"toughness_delta_per_graveyard_count":0,"xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot","subtype":"temporary_pump","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GhoulsFeast translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
