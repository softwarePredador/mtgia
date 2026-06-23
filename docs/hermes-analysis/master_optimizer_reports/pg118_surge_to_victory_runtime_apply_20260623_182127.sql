BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg118_surge_to_victory_runtime_20260623_182127 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'surge to victory';

DO $$
DECLARE
  v_matched_rows integer;
BEGIN
  SELECT count(c.id)
    INTO v_matched_rows
  FROM public.cards c
  WHERE lower(c.name) = 'surge to victory'
    AND md5(coalesce(c.oracle_text, '')) = '5381f78ff0798b9afad371e0fa495831';

  IF v_matched_rows <> 1 THEN
    RAISE EXCEPTION 'PG118 abort: expected exactly one Oracle-hash-matched Surge to Victory card row, got %', v_matched_rows;
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
      'PG118: deprecated legacy Surge to Victory row after Oracle/XMage-backed runtime promotion.'
    )
  WHERE r.normalized_name = 'surge to victory'
    AND r.logical_rule_key IN (
      'battle_rule_v1:4ea05a4d2ce8454073d85afff5e3f790',
      'battle_rule_v1:cc95729e96832afbdb1eb194ec6212d4'
    )
  RETURNING r.logical_rule_key
),
target_card AS (
  SELECT id, name
  FROM public.cards
  WHERE lower(name) = 'surge to victory'
    AND md5(coalesce(oracle_text, '')) = '5381f78ff0798b9afad371e0fa495831'
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
    'surge to victory',
    tc.id,
    tc.name,
    '{
      "battle_model_scope":"graveyard_spell_exile_team_pump_combat_damage_copy_cast_until_eot_v1",
      "casts_copies_without_paying_mana":true,
      "cmc":6.0,
      "combat_damage_player_copies_exiled_card":true,
      "effect":"pump_all",
      "exiles_target_from_graveyard":true,
      "pump_power_from_exiled_card_mana_value":true,
      "target":"instant_or_sorcery_graveyard"
    }'::jsonb,
    '{"category":"combat","effect":"pump_all","subtype":"graveyard_spell_exile_team_pump_copy_cast","timing":"combat"}'::jsonb,
    'curated',
    0.95,
    'verified',
    2,
    '5381f78ff0798b9afad371e0fa495831',
    'PG118: Oracle/XMage-backed Surge to Victory runtime. Exiles the best instant or sorcery from your graveyard, grants your creatures +X/+0 until end of turn where X is that mana value, then copies and casts that exiled spell each time one of your creatures deals combat damage to a player that turn.',
    'codex-pg118',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e',
    'auto'
  FROM target_card tc
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
SELECT
  (SELECT count(*) FROM deprecated) AS deprecated_legacy_rows,
  count(*) AS upserted_rows
FROM upserted;

COMMIT;
