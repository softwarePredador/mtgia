BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg828_dynamic_draw_discard_new_server_20260712_111415 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('flow of knowledge', 'pull from tomorrow')
   OR normalized_name LIKE 'flow of knowledge // %'
   OR normalized_name LIKE 'pull from tomorrow // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('flow of knowledge', 'Flow of Knowledge', 'bbc4cd94086b5d8b8c60987d2c541b83', 'battle_rule_v1:0e6ff4345f8868715ae1cef6ebe7e2b0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["island"],"count":0,"discard_count":2,"discard_random":false,"draw_count":0,"draw_count_source":"battlefield_permanent_count","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlowOfKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pull from tomorrow', 'Pull from Tomorrow', 'c628593ab13ce79b59fa35aec2f65c97', 'battle_rule_v1:5c92cd65e2f74fcff2ff572db18adcf0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":0,"discard_count":1,"discard_random":false,"draw_count":0,"draw_count_source":"x_value","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PullFromTomorrow translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('flow of knowledge', 'Flow of Knowledge', 'bbc4cd94086b5d8b8c60987d2c541b83', 'battle_rule_v1:0e6ff4345f8868715ae1cef6ebe7e2b0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["island"],"count":0,"discard_count":2,"discard_random":false,"draw_count":0,"draw_count_source":"battlefield_permanent_count","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlowOfKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pull from tomorrow', 'Pull from Tomorrow', 'c628593ab13ce79b59fa35aec2f65c97', 'battle_rule_v1:5c92cd65e2f74fcff2ff572db18adcf0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":0,"discard_count":1,"discard_random":false,"draw_count":0,"draw_count_source":"x_value","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PullFromTomorrow translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('flow of knowledge', 'Flow of Knowledge', 'bbc4cd94086b5d8b8c60987d2c541b83', 'battle_rule_v1:0e6ff4345f8868715ae1cef6ebe7e2b0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","battlefield_count_card_types":["land"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["island"],"count":0,"discard_count":2,"discard_random":false,"draw_count":0,"draw_count_source":"battlefield_permanent_count","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlowOfKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pull from tomorrow', 'Pull from Tomorrow', 'c628593ab13ce79b59fa35aec2f65c97', 'battle_rule_v1:5c92cd65e2f74fcff2ff572db18adcf0', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":0,"discard_count":1,"discard_random":false,"draw_count":0,"draw_count_source":"x_value","draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PullFromTomorrow translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
