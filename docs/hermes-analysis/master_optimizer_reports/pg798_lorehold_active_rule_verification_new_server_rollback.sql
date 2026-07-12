BEGIN;

UPDATE public.card_battle_rules r
SET
  card_id = b.card_id,
  card_name = b.card_name,
  effect_json = b.effect_json,
  deck_role_json = b.deck_role_json,
  source = b.source,
  confidence = b.confidence,
  review_status = b.review_status,
  rule_version = b.rule_version,
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  created_at = b.created_at,
  updated_at = b.updated_at,
  last_seen_at = b.last_seen_at,
  execution_status = b.execution_status
FROM manaloom_deploy_audit.pg798_lorehold_active_rule_verification_new_server_20260712 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
