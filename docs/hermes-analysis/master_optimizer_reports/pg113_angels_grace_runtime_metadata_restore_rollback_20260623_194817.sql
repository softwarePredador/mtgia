\pset pager off

BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

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
FROM manaloom_deploy_audit.pg113_angels_grace_runtime_metadata_restore_20260623_194817;

COMMIT;
