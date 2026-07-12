BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg842_target_player_mill_draw_new_server_20260712_200018 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('pilfered plans', 'thassa''s bounty', 'thought scour', 'weight of memory')
   OR normalized_name LIKE 'pilfered plans // %'
   OR normalized_name LIKE 'thassa''s bounty // %'
   OR normalized_name LIKE 'thought scour // %'
   OR normalized_name LIKE 'weight of memory // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('pilfered plans', 'Pilfered Plans', 'e490a59b9586ce4ec4d6b45ac4ec5069', 'battle_rule_v1:7ff51f5fdbd9cd76eeb3a28e8ce616f9', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PilferedPlans translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thassa''s bounty', 'Thassa''s Bounty', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThassasBounty translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought scour', 'Thought Scour', 'b5be321c4136f2a6c70da77a56edb7ab', 'battle_rule_v1:f66bbfb88f92a5b9aa93ced8b6ccff70', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtScour translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('weight of memory', 'Weight of Memory', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeightOfMemory translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('pilfered plans', 'Pilfered Plans', 'e490a59b9586ce4ec4d6b45ac4ec5069', 'battle_rule_v1:7ff51f5fdbd9cd76eeb3a28e8ce616f9', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PilferedPlans translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thassa''s bounty', 'Thassa''s Bounty', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThassasBounty translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought scour', 'Thought Scour', 'b5be321c4136f2a6c70da77a56edb7ab', 'battle_rule_v1:f66bbfb88f92a5b9aa93ced8b6ccff70', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtScour translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('weight of memory', 'Weight of Memory', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeightOfMemory translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('pilfered plans', 'Pilfered Plans', 'e490a59b9586ce4ec4d6b45ac4ec5069', 'battle_rule_v1:7ff51f5fdbd9cd76eeb3a28e8ce616f9', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":2,"draw_count":2,"effect":"composite_resolution","instant":false,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PilferedPlans translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thassa''s bounty', 'Thassa''s Bounty', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThassasBounty translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thought scour', 'Thought Scour', 'b5be321c4136f2a6c70da77a56edb7ab', 'battle_rule_v1:f66bbfb88f92a5b9aa93ced8b6ccff70', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":2,"effect":"mill_cards","mill_count":2,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"draw_count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"mill_count":2,"resolution_order":"mill_then_draw","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThoughtScour translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('weight of memory', 'Weight of Memory', 'f4c1a48e59f455d35e1525b4999e6a5a', 'battle_rule_v1:5058f463d4e7289465529065f2e16f55', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"draw_count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":3,"effect":"mill_cards","mill_count":3,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_mill_draw_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":false,"mill_count":3,"resolution_order":"draw_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["MillCardsTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WeightOfMemory translated into ManaLoom runtime scope xmage_fixed_target_player_mill_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
