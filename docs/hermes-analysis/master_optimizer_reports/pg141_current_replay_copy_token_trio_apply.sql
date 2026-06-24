BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg141_current_replay_copy_token_trio_20260624_035857 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('flash photography', 'astral dragon', 'clone legion')
   OR normalized_name LIKE 'flash photography // %'
   OR normalized_name LIKE 'astral dragon // %'
   OR normalized_name LIKE 'clone legion // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('flash photography', 'Flash Photography', 'c3fb29c6ec7bd40a4d59959e9abe9ee8', 'battle_rule_v1:e5ea20bd49a563c1256183af42e86c71', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_permanent_v1","copy_target_types":["permanent"],"effect":"copy_creature_token","target_controller":"any","token_haste":false}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FlashPhotography mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('astral dragon', 'Astral Dragon', '5efa9ecc8bca6d341f1dc4dea3e51c49', 'battle_rule_v1:7f8364137188a184510b1cfc4ebeac33', '{"ability_kind":"triggered","battle_model_scope":"etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1","effect":"creature","etb_copy_force_creature":true,"etb_copy_target_types":["noncreature_permanent"],"etb_copy_token_count":2,"etb_copy_token_flying":true,"etb_copy_token_power":3,"etb_copy_token_subtype":"Dragon","etb_copy_token_toughness":3,"flying":true,"power":4,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AstralDragon mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clone legion', 'Clone Legion', 'd5300831d3df4276f01145ddeca85521', 'battle_rule_v1:391956936dfadf0b7bd0f0123226279f', '{"ability_kind":"one_shot","battle_model_scope":"copy_each_creature_target_player_controls_v1","copy_all_matching_targets":true,"copy_target_types":["creature"],"effect":"copy_creature_token","target_controller":"opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloneLegion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('flash photography', 'Flash Photography', 'c3fb29c6ec7bd40a4d59959e9abe9ee8', 'battle_rule_v1:e5ea20bd49a563c1256183af42e86c71', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_permanent_v1","copy_target_types":["permanent"],"effect":"copy_creature_token","target_controller":"any","token_haste":false}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FlashPhotography mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('astral dragon', 'Astral Dragon', '5efa9ecc8bca6d341f1dc4dea3e51c49', 'battle_rule_v1:7f8364137188a184510b1cfc4ebeac33', '{"ability_kind":"triggered","battle_model_scope":"etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1","effect":"creature","etb_copy_force_creature":true,"etb_copy_target_types":["noncreature_permanent"],"etb_copy_token_count":2,"etb_copy_token_flying":true,"etb_copy_token_power":3,"etb_copy_token_subtype":"Dragon","etb_copy_token_toughness":3,"flying":true,"power":4,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AstralDragon mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clone legion', 'Clone Legion', 'd5300831d3df4276f01145ddeca85521', 'battle_rule_v1:391956936dfadf0b7bd0f0123226279f', '{"ability_kind":"one_shot","battle_model_scope":"copy_each_creature_target_player_controls_v1","copy_all_matching_targets":true,"copy_target_types":["creature"],"effect":"copy_creature_token","target_controller":"opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloneLegion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('flash photography', 'Flash Photography', 'c3fb29c6ec7bd40a4d59959e9abe9ee8', 'battle_rule_v1:e5ea20bd49a563c1256183af42e86c71', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_permanent_v1","copy_target_types":["permanent"],"effect":"copy_creature_token","target_controller":"any","token_haste":false}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FlashPhotography mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('astral dragon', 'Astral Dragon', '5efa9ecc8bca6d341f1dc4dea3e51c49', 'battle_rule_v1:7f8364137188a184510b1cfc4ebeac33', '{"ability_kind":"triggered","battle_model_scope":"etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1","effect":"creature","etb_copy_force_creature":true,"etb_copy_target_types":["noncreature_permanent"],"etb_copy_token_count":2,"etb_copy_token_flying":true,"etb_copy_token_power":3,"etb_copy_token_subtype":"Dragon","etb_copy_token_toughness":3,"flying":true,"power":4,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AstralDragon mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clone legion', 'Clone Legion', 'd5300831d3df4276f01145ddeca85521', 'battle_rule_v1:391956936dfadf0b7bd0f0123226279f', '{"ability_kind":"one_shot","battle_model_scope":"copy_each_creature_target_player_controls_v1","copy_all_matching_targets":true,"copy_target_types":["creature"],"effect":"copy_creature_token","target_controller":"opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloneLegion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
