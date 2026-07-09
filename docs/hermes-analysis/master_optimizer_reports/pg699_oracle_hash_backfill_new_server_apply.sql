BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg699_oracle_hash_backfill_new_server_20260709 AS
SELECT
  br.normalized_name,
  br.card_id,
  br.card_name,
  br.logical_rule_key,
  br.oracle_hash AS old_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS new_oracle_hash,
  br.notes AS old_notes,
  br.updated_at AS old_updated_at,
  now() AS backed_up_at
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND nullif(br.oracle_hash, '') IS NULL
  AND c.oracle_text IS NOT NULL;

WITH updated AS (
  UPDATE card_battle_rules br
     SET oracle_hash = b.new_oracle_hash,
         notes = concat_ws(
           ' | ',
           nullif(br.notes, ''),
           'pg699 oracle_hash backfill from cards.oracle_text md5'
         ),
         updated_at = now()
    FROM manaloom_deploy_audit.pg699_oracle_hash_backfill_new_server_20260709 b
   WHERE br.card_id = b.card_id
     AND br.logical_rule_key = b.logical_rule_key
     AND nullif(br.oracle_hash, '') IS NULL
  RETURNING br.card_name, br.normalized_name, br.logical_rule_key, br.oracle_hash
)
SELECT count(*) AS backfilled_rows FROM updated;

COMMIT;
