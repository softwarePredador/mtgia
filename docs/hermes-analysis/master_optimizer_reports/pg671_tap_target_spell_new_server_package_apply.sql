BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg671_tap_target_spell_new_server_20260708_201937 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('downpour', 'early frost', 'gridlock', 'lead astray', 'terashi''s cry', 'word of binding')
   OR normalized_name LIKE 'downpour // %'
   OR normalized_name LIKE 'early frost // %'
   OR normalized_name LIKE 'gridlock // %'
   OR normalized_name LIKE 'lead astray // %'
   OR normalized_name LIKE 'terashi''s cry // %'
   OR normalized_name LIKE 'word of binding // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('downpour', 'Downpour', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:97b5de80477f9460ef784533e6024927', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Downpour translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('early frost', 'Early Frost', '92375c3d37f9d764358fb389cadb5e48', 'battle_rule_v1:4fc24a112121a24561daf0f372287872', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"land","target_constraints":{"card_types":["land"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarlyFrost translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gridlock', 'Gridlock', 'f3799a0d79c5a1e04a784fdd1702acea', 'battle_rule_v1:5bebfc1427545887eb7efb9e503d4fe8', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gridlock translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lead astray', 'Lead Astray', 'c9ce98f65a5953a641363e2edeb41de7', 'battle_rule_v1:db6c12f90bdf648e5a86a83c2164ff64', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeadAstray translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terashi''s cry', 'Terashi''s Cry', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:005cb5d615bbf9ed00e95157bdae79f4', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerashisCry translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of binding', 'Word of Binding', '61e37e31093d1088e19be84db7c70d19', 'battle_rule_v1:a28fb929f055841a3fbe611c9dc7ca67', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfBinding translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('downpour', 'Downpour', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:97b5de80477f9460ef784533e6024927', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Downpour translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('early frost', 'Early Frost', '92375c3d37f9d764358fb389cadb5e48', 'battle_rule_v1:4fc24a112121a24561daf0f372287872', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"land","target_constraints":{"card_types":["land"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarlyFrost translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gridlock', 'Gridlock', 'f3799a0d79c5a1e04a784fdd1702acea', 'battle_rule_v1:5bebfc1427545887eb7efb9e503d4fe8', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gridlock translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lead astray', 'Lead Astray', 'c9ce98f65a5953a641363e2edeb41de7', 'battle_rule_v1:db6c12f90bdf648e5a86a83c2164ff64', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeadAstray translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terashi''s cry', 'Terashi''s Cry', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:005cb5d615bbf9ed00e95157bdae79f4', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerashisCry translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of binding', 'Word of Binding', '61e37e31093d1088e19be84db7c70d19', 'battle_rule_v1:a28fb929f055841a3fbe611c9dc7ca67', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfBinding translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('downpour', 'Downpour', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:97b5de80477f9460ef784533e6024927', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Downpour translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('early frost', 'Early Frost', '92375c3d37f9d764358fb389cadb5e48', 'battle_rule_v1:4fc24a112121a24561daf0f372287872', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"land","target_constraints":{"card_types":["land"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EarlyFrost translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gridlock', 'Gridlock', 'f3799a0d79c5a1e04a784fdd1702acea', 'battle_rule_v1:5bebfc1427545887eb7efb9e503d4fe8', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Gridlock translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lead astray', 'Lead Astray', 'c9ce98f65a5953a641363e2edeb41de7', 'battle_rule_v1:db6c12f90bdf648e5a86a83c2164ff64', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeadAstray translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terashi''s cry', 'Terashi''s Cry', 'd68899a467f06f7eb5a4978ed3531b0f', 'battle_rule_v1:005cb5d615bbf9ed00e95157bdae79f4', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TerashisCry translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of binding', 'Word of Binding', '61e37e31093d1088e19be84db7c70d19', 'battle_rule_v1:a28fb929f055841a3fbe611c9dc7ca67', '{"battle_model_scope":"xmage_tap_target_spell_v1","effect":"tap_target","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count_from_x":true,"target_count_source":"x_value","up_to_count":false,"xmage_effect_class":"TapTargetEffect"}'::jsonb, '{"category":"unknown","effect":"tap_target","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfBinding translated into ManaLoom runtime scope xmage_tap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
