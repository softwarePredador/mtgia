BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg167_copy_creature_applier_20260624_111913 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('imposter mech', 'mockingbird', 'flesh duplicate', 'phantasmal image')
   OR normalized_name LIKE 'imposter mech // %'
   OR normalized_name LIKE 'mockingbird // %'
   OR normalized_name LIKE 'flesh duplicate // %'
   OR normalized_name LIKE 'phantasmal image // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('imposter mech', 'Imposter Mech', '35f38b34bb79ee6327a68ece8587f7a1', 'battle_rule_v1:4f317236846bce55c91965bb4605762f', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_overwrite_subtypes":["Vehicle"],"copy_overwrite_types":["artifact"],"copy_target_types":["creature"],"copy_vehicle_crew_value":3,"effect":"copy_permanent_etb","target_controller":"opponent"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImposterMech mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mockingbird', 'Mockingbird', 'f3b499fed5cd401f51e14b49fc2c9edd', 'battle_rule_v1:43e3543e0e752d74fab3cf0a170d081e', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Bird"],"copy_granted_keywords":["flying"],"copy_target_mana_value_lte_source_mana_value":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mockingbird mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('flesh duplicate', 'Flesh Duplicate', '93e6894ab82a238b50dcbbbd1a8d9e68', 'battle_rule_v1:03e13973df9fbbf9ad781f5ace004f05', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_grant_vanishing_if_missing":3,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FleshDuplicate mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phantasmal image', 'Phantasmal Image', 'd354295810b0219eb38e5137a0ba0e9f', 'battle_rule_v1:e2b5d8a5284d2c8a2b986ecc343702cd', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Illusion"],"copy_sacrifice_when_targeted":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhantasmalImage mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('imposter mech', 'Imposter Mech', '35f38b34bb79ee6327a68ece8587f7a1', 'battle_rule_v1:4f317236846bce55c91965bb4605762f', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_overwrite_subtypes":["Vehicle"],"copy_overwrite_types":["artifact"],"copy_target_types":["creature"],"copy_vehicle_crew_value":3,"effect":"copy_permanent_etb","target_controller":"opponent"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImposterMech mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mockingbird', 'Mockingbird', 'f3b499fed5cd401f51e14b49fc2c9edd', 'battle_rule_v1:43e3543e0e752d74fab3cf0a170d081e', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Bird"],"copy_granted_keywords":["flying"],"copy_target_mana_value_lte_source_mana_value":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mockingbird mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('flesh duplicate', 'Flesh Duplicate', '93e6894ab82a238b50dcbbbd1a8d9e68', 'battle_rule_v1:03e13973df9fbbf9ad781f5ace004f05', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_grant_vanishing_if_missing":3,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FleshDuplicate mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phantasmal image', 'Phantasmal Image', 'd354295810b0219eb38e5137a0ba0e9f', 'battle_rule_v1:e2b5d8a5284d2c8a2b986ecc343702cd', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Illusion"],"copy_sacrifice_when_targeted":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhantasmalImage mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('imposter mech', 'Imposter Mech', '35f38b34bb79ee6327a68ece8587f7a1', 'battle_rule_v1:4f317236846bce55c91965bb4605762f', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_overwrite_subtypes":["Vehicle"],"copy_overwrite_types":["artifact"],"copy_target_types":["creature"],"copy_vehicle_crew_value":3,"effect":"copy_permanent_etb","target_controller":"opponent"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ImposterMech mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mockingbird', 'Mockingbird', 'f3b499fed5cd401f51e14b49fc2c9edd', 'battle_rule_v1:43e3543e0e752d74fab3cf0a170d081e', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Bird"],"copy_granted_keywords":["flying"],"copy_target_mana_value_lte_source_mana_value":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mockingbird mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('flesh duplicate', 'Flesh Duplicate', '93e6894ab82a238b50dcbbbd1a8d9e68', 'battle_rule_v1:03e13973df9fbbf9ad781f5ace004f05', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_grant_vanishing_if_missing":3,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FleshDuplicate mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('phantasmal image', 'Phantasmal Image', 'd354295810b0219eb38e5137a0ba0e9f', 'battle_rule_v1:e2b5d8a5284d2c8a2b986ecc343702cd', '{"ability_kind":"replacement","battle_model_scope":"etb_copy_target_creature_with_copy_applier_modifiers_v1","copy_additional_subtypes":["Illusion"],"copy_sacrifice_when_targeted":true,"copy_target_types":["creature"],"effect":"copy_permanent_etb","target_controller":"any"}'::jsonb, '{"category":"board_development","effect":"copy_permanent_etb","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PhantasmalImage mapped to family copy_permanent_etb; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
