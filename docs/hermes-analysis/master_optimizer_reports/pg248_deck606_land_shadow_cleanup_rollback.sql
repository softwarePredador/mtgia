BEGIN;

WITH backup AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg248_deck606_land_shadow_cleanup_20260628
)
DELETE FROM public.card_battle_rules r
USING backup b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

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
FROM manaloom_deploy_audit.pg248_deck606_land_shadow_cleanup_20260628;

COMMIT;
