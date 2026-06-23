BEGIN;

UPDATE card_battle_rules r
SET
  card_id = b.card_id,
  card_name = b.card_name,
  effect_json = b.effect_json,
  deck_role_json = b.deck_role_json,
  source = b.source,
  confidence = b.confidence,
  review_status = b.review_status,
  execution_status = b.execution_status,
  rule_version = b.rule_version,
  oracle_hash = b.oracle_hash,
  notes = b.notes,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg097_valakut_simple_hash_restore_20260623_113918 b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

COMMIT;
