\pset pager off

BEGIN;

UPDATE card_battle_rules cbr
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
  created_at = b.created_at,
  updated_at = now(),
  last_seen_at = b.last_seen_at
FROM manaloom_deploy_audit.pg086_deck608_angels_grace_20260623_084922 b
WHERE cbr.normalized_name = b.normalized_name
  AND cbr.logical_rule_key = b.logical_rule_key;

COMMIT;
