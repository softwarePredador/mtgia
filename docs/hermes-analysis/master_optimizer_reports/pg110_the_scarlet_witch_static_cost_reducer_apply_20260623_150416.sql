BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg110_the_scarlet_witch_static_cost_reducer_20260623_150416 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'the scarlet witch';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'the scarlet witch'
    AND md5(coalesce(oracle_text, '')) = '6129fda2f5ae1f8edad5a2f2e77d05c2';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG110 abort: expected exactly one The Scarlet Witch card row with current Oracle hash, found %', v_card_rows;
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
      'PG110: deprecated stale generated/review-only shadow after Oracle/XMage-backed The Scarlet Witch static source-power cost-reduction rule was prepared.'
    )
  WHERE r.normalized_name = 'the scarlet witch'
    AND r.logical_rule_key <> 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'the scarlet witch'
    AND md5(coalesce(oracle_text, '')) = '6129fda2f5ae1f8edad5a2f2e77d05c2'
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
    'the scarlet witch',
    target_card.id,
    target_card.name,
    '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cmc":3.0,"cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb,
    '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb,
    'curated',
    0.96,
    'verified',
    2,
    target_card.oracle_hash,
    'PG110: Oracle/XMage-backed The Scarlet Witch battle rule. Runtime treats it as a static battlefield cost reducer: instant and sorcery spells its controller casts with mana value 4 or greater cost X less, where X is the source permanent power, never below zero.',
    'codex-pg110',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc',
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
