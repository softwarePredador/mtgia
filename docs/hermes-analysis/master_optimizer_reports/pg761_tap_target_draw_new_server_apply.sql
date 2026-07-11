BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg761_tap_target_draw_new_server_tap_tar_20260711_124020 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('pressure point', 'repel the darkness')
   OR normalized_name LIKE 'pressure point // %'
   OR normalized_name LIKE 'repel the darkness // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('pressure point', 'Pressure Point', '7c6c85b7c5b7c81fb53d9900f1131e9d', 'battle_rule_v1:2d79a8d3c535e40c978c6d6cfea88fea', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PressurePoint translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repel the darkness', 'Repel the Darkness', '4fcd88b3ec68ed702fbf52c83508086f', 'battle_rule_v1:4dab45dedaed04eec5e2d944587c99b0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RepelTheDarkness translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('pressure point', 'Pressure Point', '7c6c85b7c5b7c81fb53d9900f1131e9d', 'battle_rule_v1:2d79a8d3c535e40c978c6d6cfea88fea', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PressurePoint translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repel the darkness', 'Repel the Darkness', '4fcd88b3ec68ed702fbf52c83508086f', 'battle_rule_v1:4dab45dedaed04eec5e2d944587c99b0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RepelTheDarkness translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('pressure point', 'Pressure Point', '7c6c85b7c5b7c81fb53d9900f1131e9d', 'battle_rule_v1:2d79a8d3c535e40c978c6d6cfea88fea', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PressurePoint translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repel the darkness', 'Repel the Darkness', '4fcd88b3ec68ed702fbf52c83508086f', 'battle_rule_v1:4dab45dedaed04eec5e2d944587c99b0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RepelTheDarkness translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
