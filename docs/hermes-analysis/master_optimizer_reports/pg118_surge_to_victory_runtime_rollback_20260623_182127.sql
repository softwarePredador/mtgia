BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'surge to victory'
  AND logical_rule_key IN (
    'battle_rule_v1:44a0c5f4d0c51f52db6a36d12f9db98e',
    'battle_rule_v1:4ea05a4d2ce8454073d85afff5e3f790',
    'battle_rule_v1:cc95729e96832afbdb1eb194ec6212d4'
  );

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
FROM manaloom_deploy_audit.pg118_surge_to_victory_runtime_20260623_182127;

COMMIT;
