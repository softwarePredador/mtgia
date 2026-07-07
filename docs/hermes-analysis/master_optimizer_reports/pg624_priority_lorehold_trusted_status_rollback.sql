BEGIN;

UPDATE public.card_battle_rules rule
SET
  card_id = backup.card_id,
  card_name = backup.card_name,
  effect_json = backup.effect_json,
  deck_role_json = backup.deck_role_json,
  source = backup.source,
  confidence = backup.confidence,
  review_status = backup.review_status,
  execution_status = backup.execution_status,
  rule_version = backup.rule_version,
  oracle_hash = backup.oracle_hash,
  notes = backup.notes,
  reviewed_by = backup.reviewed_by,
  reviewed_at = backup.reviewed_at,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = backup.last_seen_at
FROM manaloom_deploy_audit.pg624_priority_lorehold_trusted_status_20260707_backup backup
WHERE rule.normalized_name = backup.normalized_name
  AND rule.logical_rule_key = backup.logical_rule_key;

COMMIT;
