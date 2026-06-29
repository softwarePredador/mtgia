BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc057_glittering_massif_cycling_runtime_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC057 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc057_glittering_massif_cycling_runtime_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'glittering massif'
  AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be';

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || $json${
      "battle_model_scope": "land_enters_tapped_mana_source_with_cycling_runtime_v1",
      "oracle_runtime_scope": "mountain_plains_enters_tapped_red_white_mana_and_cycling_two_runtime_v1",
      "cycling_cost": "{2}",
      "cycling_status": "runtime_executor_v1",
      "cycling_draw_count": 1,
      "cycling_discard_self_status": "runtime_executor_v1"
    }$json$::jsonb,
    rule_version = greatest(r.rule_version + 1, 2),
    reviewed_by = 'codex-pgc057',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC057: promoted Glittering Massif cycling {2} from annotation_only to runtime_executor_v1 after Scryfall/XMage audit.'
    )
  WHERE r.normalized_name = 'glittering massif'
    AND r.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.oracle_hash = '71d8d9152563d51114543ed1a9289903';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC057 expected to update 1 Glittering Massif row, updated %', updated_count;
  END IF;
END $$;

COMMIT;
