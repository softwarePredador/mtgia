BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hazel''s brewmaster', 'adagia, windswept bastion', 'purphoros, god of the forge');

INSERT INTO public.card_battle_rules
SELECT * FROM manaloom_deploy_audit.pg251_adagia_hazel_purphoros_runtime_batch_20260629_151845
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  created_at = EXCLUDED.created_at,
  updated_at = EXCLUDED.updated_at,
  last_seen_at = EXCLUDED.last_seen_at;

COMMIT;
