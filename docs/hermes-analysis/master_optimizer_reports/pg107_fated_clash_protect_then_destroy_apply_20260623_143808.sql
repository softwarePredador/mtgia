BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg107_fated_clash_protect_then_destroy_20260623_143808 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'fated clash';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'fated clash'
    AND md5(coalesce(oracle_text, '')) = '14445ec4dd93171e67d19058efe24d9c';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG107 abort: expected exactly one Fated Clash card row with current Oracle hash, found %', v_card_rows;
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
      'PG107: deprecated stale generated plain board_wipe shadow after Oracle-backed Fated Clash target-protection wipe rule was promoted.'
    )
  WHERE r.normalized_name = 'fated clash'
    AND r.logical_rule_key <> 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'fated clash'
    AND md5(coalesce(oracle_text, '')) = '14445ec4dd93171e67d19058efe24d9c'
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
    'fated clash',
    target_card.id,
    target_card.name,
    '{"battle_model_scope":"own_and_opponent_creature_indestructible_then_destroy_all_creatures_v1","conditional_flash_if_attacking_and_blocking":true,"effect":"fated_clash_protect_then_destroy","grants_targets_indestructible_until_eot":true,"sorcery":true,"target_scope":"own_creature_and_opponent_creature","then_destroy_all_creatures":true}'::jsonb,
    '{"category":"wipe","effect":"fated_clash_protect_then_destroy","timing":"sorcery_conditional_flash"}'::jsonb,
    'curated',
    0.97,
    'verified',
    2,
    target_card.oracle_hash,
    'PG107: Oracle-backed Fated Clash battle rule. Runtime declares one creature you control and one opponent creature as targets, grants those targets indestructible until end of turn, then destroys all other non-indestructible creatures. The opponent target is chosen as the lowest-value legal opponent creature because it survives the wipe.',
    'codex-pg107',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326',
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
