BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg108_pearl_medallion_static_cost_reducer_20260623_170353 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'pearl medallion';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'pearl medallion'
    AND md5(coalesce(oracle_text, '')) = '77f7f449ee56143d6b63814fecd37176';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG108 abort: expected exactly one Pearl Medallion card row with current Oracle hash, found %', v_card_rows;
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
      'PG108: deprecated stale generated ramp_permanent shadow after Oracle/XMage-backed Pearl Medallion static cost-reduction rule was promoted.'
    )
  WHERE r.normalized_name = 'pearl medallion'
    AND r.logical_rule_key <> 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'pearl medallion'
    AND md5(coalesce(oracle_text, '')) = '77f7f449ee56143d6b63814fecd37176'
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
    'pearl medallion',
    target_card.id,
    target_card.name,
    '{"ability_kind":"static","applies_to_controller":"source_controller","applies_to_spell_colors":["W"],"battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cmc":2.0,"cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb,
    '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb,
    'curated',
    0.96,
    'verified',
    2,
    target_card.oracle_hash,
    'PG108: Oracle-backed Pearl Medallion battle rule. Runtime treats it as a static battlefield cost reducer, not a mana source: white spells its controller casts cost one generic mana less, never below zero.',
    'codex-pg108',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2',
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
