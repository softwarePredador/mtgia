BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg739_draw_discard_unless_new_server_20260711_034911 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('mystic meditation', 'thirst for discovery', 'thirst for identity', 'thirst for knowledge', 'thirst for meaning')
   OR normalized_name LIKE 'mystic meditation // %'
   OR normalized_name LIKE 'thirst for discovery // %'
   OR normalized_name LIKE 'thirst for identity // %'
   OR normalized_name LIKE 'thirst for knowledge // %'
   OR normalized_name LIKE 'thirst for meaning // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('mystic meditation', 'Mystic Meditation', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:c678f64df56cf307c5d9c3a15cad897a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticMeditation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for discovery', 'Thirst for Discovery', '9de9e1308d1010387496685c78374e66', 'battle_rule_v1:aefeda576530cf9ef2de5aed32c96bac', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_basic_land":true,"discard_unless_card_types":["land"],"discard_unless_count":1,"discard_unless_filter":"basic_land_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForDiscovery translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for identity', 'Thirst for Identity', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:236da04cc9f3583da4986ec711e3148b', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForIdentity translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for knowledge', 'Thirst for Knowledge', '0f757e71e8213ba2a660219d9262cecb', 'battle_rule_v1:02810d99f1cb96bec4b8d39623ba0751', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["artifact"],"discard_unless_count":1,"discard_unless_filter":"artifact_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for meaning', 'Thirst for Meaning', '7433d8f7f2b705ff1783ccf16c296b2f', 'battle_rule_v1:e9b8c97c26e35decce39a5544d12253f', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["enchantment"],"discard_unless_count":1,"discard_unless_filter":"enchantment_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForMeaning translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('mystic meditation', 'Mystic Meditation', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:c678f64df56cf307c5d9c3a15cad897a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticMeditation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for discovery', 'Thirst for Discovery', '9de9e1308d1010387496685c78374e66', 'battle_rule_v1:aefeda576530cf9ef2de5aed32c96bac', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_basic_land":true,"discard_unless_card_types":["land"],"discard_unless_count":1,"discard_unless_filter":"basic_land_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForDiscovery translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for identity', 'Thirst for Identity', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:236da04cc9f3583da4986ec711e3148b', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForIdentity translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for knowledge', 'Thirst for Knowledge', '0f757e71e8213ba2a660219d9262cecb', 'battle_rule_v1:02810d99f1cb96bec4b8d39623ba0751', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["artifact"],"discard_unless_count":1,"discard_unless_filter":"artifact_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for meaning', 'Thirst for Meaning', '7433d8f7f2b705ff1783ccf16c296b2f', 'battle_rule_v1:e9b8c97c26e35decce39a5544d12253f', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["enchantment"],"discard_unless_count":1,"discard_unless_filter":"enchantment_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForMeaning translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('mystic meditation', 'Mystic Meditation', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:c678f64df56cf307c5d9c3a15cad897a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticMeditation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for discovery', 'Thirst for Discovery', '9de9e1308d1010387496685c78374e66', 'battle_rule_v1:aefeda576530cf9ef2de5aed32c96bac', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_basic_land":true,"discard_unless_card_types":["land"],"discard_unless_count":1,"discard_unless_filter":"basic_land_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForDiscovery translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for identity', 'Thirst for Identity', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:236da04cc9f3583da4986ec711e3148b', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForIdentity translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for knowledge', 'Thirst for Knowledge', '0f757e71e8213ba2a660219d9262cecb', 'battle_rule_v1:02810d99f1cb96bec4b8d39623ba0751', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["artifact"],"discard_unless_count":1,"discard_unless_filter":"artifact_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for meaning', 'Thirst for Meaning', '7433d8f7f2b705ff1783ccf16c296b2f', 'battle_rule_v1:e9b8c97c26e35decce39a5544d12253f', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["enchantment"],"discard_unless_count":1,"discard_unless_filter":"enchantment_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForMeaning translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
