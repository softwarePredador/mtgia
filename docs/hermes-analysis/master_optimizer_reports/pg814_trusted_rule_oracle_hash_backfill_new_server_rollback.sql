BEGIN;

UPDATE card_battle_rules r
SET oracle_hash = b.oracle_hash,
    updated_at = NOW()
FROM card_battle_rules_backup_pg814_hash_new_server b
WHERE r.card_id = b.card_id
  AND COALESCE(r.normalized_name, '') = COALESCE(b.normalized_name, '')
  AND COALESCE(r.logical_rule_key, '') = COALESCE(b.logical_rule_key, '')
  AND COALESCE(r.source, '') = COALESCE(b.source, '');

COMMIT;
