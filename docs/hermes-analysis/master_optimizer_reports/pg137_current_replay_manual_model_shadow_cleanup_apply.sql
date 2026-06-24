BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg137_current_replay_manual_model_shadow_cleanup_20260624_02 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN (
  'everflowing chalice',
  'vexing bauble',
  'soul-guide lantern'
);

DO $$
DECLARE
  v_missing_reviewed integer;
  v_missing_manual integer;
BEGIN
  SELECT count(*)
    INTO v_missing_reviewed
  FROM (
    VALUES
      ('everflowing chalice', 'battle_rule_v1:67f848a7a9f40c7337ec0c13e0c1de7c'),
      ('vexing bauble', 'battle_rule_v1:6a85170698c85498bf618c0c0283a770'),
      ('soul-guide lantern', 'battle_rule_v1:3454aa122d10a4abd906132eb7745339')
  ) AS expected(normalized_name, logical_rule_key)
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = expected.normalized_name
   AND r.logical_rule_key = expected.logical_rule_key
  WHERE r.logical_rule_key IS NULL;

  SELECT count(*)
    INTO v_missing_manual
  FROM (
    VALUES
      ('everflowing chalice', 'battle_rule_v1:b1b7f5c96002524c469ae4efa7f7bf71'),
      ('vexing bauble', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403'),
      ('soul-guide lantern', 'battle_rule_v1:720260c93bdae63518a0721df51089c3')
  ) AS expected(normalized_name, logical_rule_key)
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = expected.normalized_name
   AND r.logical_rule_key = expected.logical_rule_key
  WHERE r.logical_rule_key IS NULL;

  IF v_missing_reviewed <> 0 OR v_missing_manual <> 0 THEN
    RAISE EXCEPTION
      'PG137 abort: expected reviewed/manual-model rows missing (reviewed_missing=%, manual_missing=%)',
      v_missing_reviewed,
      v_missing_manual;
  END IF;
END $$;

UPDATE public.card_battle_rules
SET
  review_status = 'verified',
  execution_status = 'auto',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG137 cleanup: restored reviewed curated rule after stale XMage manual_model shadow.'
  )
WHERE (normalized_name, logical_rule_key) IN (
  ('everflowing chalice', 'battle_rule_v1:67f848a7a9f40c7337ec0c13e0c1de7c'),
  ('vexing bauble', 'battle_rule_v1:6a85170698c85498bf618c0c0283a770'),
  ('soul-guide lantern', 'battle_rule_v1:3454aa122d10a4abd906132eb7745339')
);

UPDATE public.card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG137 cleanup: deprecated stale XMage manual_model shadow after reviewed curated rule restoration.'
  )
WHERE (normalized_name, logical_rule_key) IN (
  ('everflowing chalice', 'battle_rule_v1:b1b7f5c96002524c469ae4efa7f7bf71'),
  ('vexing bauble', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403'),
  ('soul-guide lantern', 'battle_rule_v1:720260c93bdae63518a0721df51089c3')
);

COMMIT;
