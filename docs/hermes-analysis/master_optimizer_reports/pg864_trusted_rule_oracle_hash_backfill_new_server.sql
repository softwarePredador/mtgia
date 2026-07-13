\echo 'PG864 trusted rule oracle_hash backfill precheck'
WITH candidates AS (
  SELECT
    br.normalized_name,
    br.card_id,
    br.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.execution_status IN ('auto', 'enabled')
    AND br.review_status = 'verified'
    AND (br.oracle_hash IS NULL OR btrim(br.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
)
SELECT count(*) AS candidate_rows
FROM candidates;

\echo 'PG864 trusted rule oracle_hash backfill apply'
WITH updated AS (
  UPDATE card_battle_rules br
     SET oracle_hash = md5(coalesce(c.oracle_text, '')),
         updated_at = now(),
         notes = concat_ws(
           E'\n',
           nullif(br.notes, ''),
           'PG864 trusted rule oracle_hash backfill from cards.oracle_text.'
         )
    FROM cards c
   WHERE c.id = br.card_id
     AND br.execution_status IN ('auto', 'enabled')
     AND br.review_status = 'verified'
     AND (br.oracle_hash IS NULL OR btrim(br.oracle_hash) = '')
     AND btrim(coalesce(c.oracle_text, '')) <> ''
  RETURNING br.normalized_name, br.card_id, br.logical_rule_key, br.oracle_hash
)
SELECT count(*) AS backfilled_rows
FROM updated;

\echo 'PG864 trusted rule oracle_hash backfill postcheck'
SELECT count(*) AS remaining_trusted_missing_hash_rows
FROM card_battle_rules
WHERE execution_status IN ('auto', 'enabled')
  AND review_status = 'verified'
  AND (oracle_hash IS NULL OR btrim(oracle_hash) = '');
