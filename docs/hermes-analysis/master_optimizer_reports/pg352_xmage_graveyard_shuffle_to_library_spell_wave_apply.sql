BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg352_xmage_graveyard_shuffle_to_library_spell_wave_2026 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dwell on the past', 'krosan reclamation', 'memory''s journey', 'stream of consciousness')
   OR normalized_name LIKE 'dwell on the past // %'
   OR normalized_name LIKE 'krosan reclamation // %'
   OR normalized_name LIKE 'memory''s journey // %'
   OR normalized_name LIKE 'stream of consciousness // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dwell on the past', 'Dwell on the Past', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:c8d07ae1642f1792017f5037a500f23d', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":false,"library_controller":"target_player","sorcery":true,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwellOnThePast translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan reclamation', 'Krosan Reclamation', 'bce73a05bed813794d698fe9623dc47c', 'battle_rule_v1:96e29173e026d208c085eba9c46eeb90', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":2,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{1}{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanReclamation translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('memory''s journey', 'Memory''s Journey', '6c9de0cfefccac64e5774ae0c6510a59', 'battle_rule_v1:50505be06d0d57f05f3dadbfbe32fd43', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":3,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MemorysJourney translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stream of consciousness', 'Stream of Consciousness', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:8ead478fb37e561206c410fdf144df3a', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StreamOfConsciousness translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dwell on the past', 'Dwell on the Past', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:c8d07ae1642f1792017f5037a500f23d', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":false,"library_controller":"target_player","sorcery":true,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwellOnThePast translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan reclamation', 'Krosan Reclamation', 'bce73a05bed813794d698fe9623dc47c', 'battle_rule_v1:96e29173e026d208c085eba9c46eeb90', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":2,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{1}{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanReclamation translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('memory''s journey', 'Memory''s Journey', '6c9de0cfefccac64e5774ae0c6510a59', 'battle_rule_v1:50505be06d0d57f05f3dadbfbe32fd43', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":3,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MemorysJourney translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stream of consciousness', 'Stream of Consciousness', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:8ead478fb37e561206c410fdf144df3a', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StreamOfConsciousness translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dwell on the past', 'Dwell on the Past', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:c8d07ae1642f1792017f5037a500f23d', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":false,"library_controller":"target_player","sorcery":true,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwellOnThePast translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan reclamation', 'Krosan Reclamation', 'bce73a05bed813794d698fe9623dc47c', 'battle_rule_v1:96e29173e026d208c085eba9c46eeb90', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":2,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{1}{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanReclamation translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('memory''s journey', 'Memory''s Journey', '6c9de0cfefccac64e5774ae0c6510a59', 'battle_rule_v1:50505be06d0d57f05f3dadbfbe32fd43', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":3,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MemorysJourney translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stream of consciousness', 'Stream of Consciousness', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:8ead478fb37e561206c410fdf144df3a', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StreamOfConsciousness translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
