BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg106_everything_comes_to_dust_convoke_exile_20260623_140650 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'everything comes to dust';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'everything comes to dust'
    AND md5(coalesce(oracle_text, '')) = '1d823f07340ed6833c15a9c6065a1742';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG106 abort: expected exactly one Everything Comes to Dust card row with current Oracle hash, found %', v_card_rows;
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
      'PG106: deprecated stale generated plain board_wipe shadow after Oracle-backed Everything Comes to Dust convoke exception exile wipe rule was promoted.'
    )
  WHERE r.normalized_name = 'everything comes to dust'
    AND r.logical_rule_key <> 'battle_rule_v1:42d629a9ccceff95dbed01e2226291a7'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'everything comes to dust'
    AND md5(coalesce(oracle_text, '')) = '1d823f07340ed6833c15a9c6065a1742'
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
    'everything comes to dust',
    target_card.id,
    target_card.name,
    '{"battle_model_scope":"exile_creatures_except_convoked_types_artifacts_enchantments_v1","convoke_creature_type_source":"explicit_or_controller_creature_inference","convoke_exception":"share_creature_type_with_convoked_creature","destination":"exile","effect":"exile_artifact_enchantment_creature_convoke_wipe","exile_artifacts":true,"exile_creatures_except_convoked_types":true,"exile_enchantments":true,"infer_convoked_types_from_controller_creatures":true,"sorcery":true}'::jsonb,
    '{"category":"wipe","effect":"exile_artifact_enchantment_creature_convoke_wipe","timing":"sorcery"}'::jsonb,
    'curated',
    0.98,
    'verified',
    2,
    target_card.oracle_hash,
    'PG106: Oracle-backed Everything Comes to Dust battle rule. Runtime exiles all artifacts and enchantments, exiles creatures that do not share a creature type with a creature that convoked the spell, preserves shared-type creatures, and records when convoked creature types are inferred rather than explicitly observed.',
    'codex-pg106',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:42d629a9ccceff95dbed01e2226291a7',
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
