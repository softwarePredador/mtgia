BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg103_dawns_truce_gift_hexproof_indestructible_20260623_133226 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'dawn''s truce';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'dawn''s truce'
    AND md5(coalesce(oracle_text, '')) = '9cc2a1e412623ff79367f88b163c5216';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG103 abort: expected exactly one Dawn''s Truce card row with current Oracle hash, found %', v_card_rows;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG103: deprecated stale generated indestructible-only shadow after Oracle-backed Dawn''s Truce gift/hexproof/indestructible rule was promoted.'
    )
  WHERE r.normalized_name = 'dawn''s truce'
    AND r.logical_rule_key <> 'battle_rule_v1:74537642d9a7fded7b0e5616b88703ef'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'dawn''s truce'
    AND md5(coalesce(oracle_text, '')) = '9cc2a1e412623ff79367f88b163c5216'
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
    'dawn''s truce',
    target_card.id,
    target_card.name,
    '{"battle_model_scope":"gift_card_you_and_permanents_hexproof_gifted_indestructible_v1","effect":"gift_hexproof_indestructible","gift":"card","gift_card_draw":true,"gift_choice_model":"lowest_visible_threat_opponent","gift_default_promised":true,"gift_grants_permanents_indestructible":true,"grants_permanents_hexproof":true,"grants_player_hexproof":true,"instant":true,"target_scope":"you_and_permanents_you_control"}'::jsonb,
    '{"category":"protection","effect":"gift_hexproof_indestructible","timing":"instant"}'::jsonb,
    'curated',
    0.98,
    'verified',
    2,
    target_card.oracle_hash,
    'PG103: Oracle-backed Dawn''s Truce battle rule. Runtime promises the card gift to the lowest-visible-threat opponent, that opponent draws before protection applies, the controller gains hexproof, controlled permanents gain hexproof until EOT, and promised-gift mode grants controlled permanents indestructible until EOT.',
    'codex-pg103',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:74537642d9a7fded7b0e5616b88703ef',
    'auto'
  FROM target_card
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
SELECT count(*) AS upserted_rows
FROM upserted;

COMMIT;
