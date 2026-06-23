BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg099_avatars_wrath_airbend_rule_20260623_093427 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'avatar''s wrath';

DO $$
DECLARE
  v_card_rows integer;
BEGIN
  SELECT count(*)
    INTO v_card_rows
  FROM public.cards
  WHERE lower(name) = 'avatar''s wrath'
    AND md5(coalesce(oracle_text, '')) = '21a711291b98f2e66a6d94a6c806945d';

  IF v_card_rows <> 1 THEN
    RAISE EXCEPTION 'PG099 abort: expected exactly one Avatar''s Wrath card row with current Oracle hash, found %', v_card_rows;
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
      'PG099: deprecated stale Avatar''s Wrath shadow after Oracle-backed airbend tempo wipe + non-hand cast lock rule was promoted.'
    )
  WHERE r.normalized_name = 'avatar''s wrath'
    AND r.logical_rule_key <> 'battle_rule_v1:2dc2965ea9c97ebdb62c2b351bf29bf5'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'avatar''s wrath'
    AND md5(coalesce(oracle_text, '')) = '21a711291b98f2e66a6d94a6c806945d'
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
    'avatar''s wrath',
    target_card.id,
    target_card.name,
    '{"airbend_recast_cost":"{2}","airbend_recast_permission":"owner_may_cast_from_exile","airbend_recast_permission_status":"tracked_for_cast_from_exile","airbend_scope":"all_other_creatures","battle_model_scope":"avatars_wrath_airbend_all_other_creatures_nonhand_lock_self_exile_v1","destination":"exile","effect":"airbend_other_creatures","exile_creatures":true,"exiles_self":true,"opponents_non_hand_cast_lock":true,"opponents_non_hand_cast_lock_duration":"until_your_next_turn","sorcery":true,"target":"creature","target_choice":"up_to_one_creature_to_spare","target_scope":"any_creature"}'::jsonb,
    '{"category":"wipe","effect":"airbend_other_creatures","role":"tempo_wipe_nonhand_cast_lock","timing":"sorcery"}'::jsonb,
    'curated',
    0.98,
    'verified',
    2,
    target_card.oracle_hash,
    'PG099: Oracle-backed Avatar''s Wrath battle rule. Runtime executes airbend all other creatures to exile, tracks owner recast for {2}, applies opponents cannot-cast-from-non-hand-zones lock until the caster''s next turn, and self-exiles the spell.',
    'codex-pg099',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:2dc2965ea9c97ebdb62c2b351bf29bf5',
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
