BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg138_current_replay_batch_three_strike_pillage_electrod AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('electroduplicate', 'pirate''s pillage', 'strike it rich')
   OR normalized_name LIKE 'electroduplicate // %'
   OR normalized_name LIKE 'pirate''s pillage // %'
   OR normalized_name LIKE 'strike it rich // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('electroduplicate', 'Electroduplicate', '336afa048144f8fb9a88dfc3b6588f4b', 'battle_rule_v1:e62445a8a1b5b420bad5215efdc00137', '{"ability_kind":"triggered","battle_model_scope":"copy_target_creature_you_control_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Electroduplicate mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('pirate''s pillage', 'Pirate''s Pillage', '9c4fbe06104051a2e8b1d295d307b26a', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e', '{"ability_kind":"one_shot","battle_model_scope":"discard_draw_two_create_two_treasures_v1","draw_count":2,"effect":"treasure_maker","requires_discard_card":true,"treasure_count":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PiratesPillage mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('strike it rich', 'Strike It Rich', 'ac6a1738bb963034e826d875966ffca4', 'battle_rule_v1:64d1b921f178816f331ef011862f40ae', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StrikeItRich mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('electroduplicate', 'Electroduplicate', '336afa048144f8fb9a88dfc3b6588f4b', 'battle_rule_v1:e62445a8a1b5b420bad5215efdc00137', '{"ability_kind":"triggered","battle_model_scope":"copy_target_creature_you_control_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Electroduplicate mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('pirate''s pillage', 'Pirate''s Pillage', '9c4fbe06104051a2e8b1d295d307b26a', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e', '{"ability_kind":"one_shot","battle_model_scope":"discard_draw_two_create_two_treasures_v1","draw_count":2,"effect":"treasure_maker","requires_discard_card":true,"treasure_count":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PiratesPillage mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('strike it rich', 'Strike It Rich', 'ac6a1738bb963034e826d875966ffca4', 'battle_rule_v1:64d1b921f178816f331ef011862f40ae', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StrikeItRich mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('electroduplicate', 'Electroduplicate', '336afa048144f8fb9a88dfc3b6588f4b', 'battle_rule_v1:e62445a8a1b5b420bad5215efdc00137', '{"ability_kind":"triggered","battle_model_scope":"copy_target_creature_you_control_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Electroduplicate mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('pirate''s pillage', 'Pirate''s Pillage', '9c4fbe06104051a2e8b1d295d307b26a', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e', '{"ability_kind":"one_shot","battle_model_scope":"discard_draw_two_create_two_treasures_v1","draw_count":2,"effect":"treasure_maker","requires_discard_card":true,"treasure_count":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PiratesPillage mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('strike it rich', 'Strike It Rich', 'ac6a1738bb963034e826d875966ffca4', 'battle_rule_v1:64d1b921f178816f331ef011862f40ae', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StrikeItRich mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
