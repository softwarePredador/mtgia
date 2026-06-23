-- PG066 deck6 Birgi spell-cast resource engine precheck.
-- PostgreSQL is the source of truth; this query must pass before apply.

WITH target_names(normalized_name, card_name, expected_oracle_hash, new_logical_rule_key) AS (
  VALUES (
    'birgi, god of storytelling // harnfel, horn of bounty',
    'Birgi, God of Storytelling // Harnfel, Horn of Bounty',
    '5f1ed696a63cd668fd46a2fe9971a54e',
    'battle_rule_v1:05576012d8fca56910da7ea072abe15e'
  )
),
live_cards AS (
  SELECT t.*, c.id AS card_id, c.name, c.type_line, c.oracle_text,
         md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
  FROM target_names t
  LEFT JOIN cards c ON lower(c.name) = t.normalized_name
),
target_rules AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_names t USING (normalized_name)
),
deck6_cards AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  (SELECT count(*) FROM live_cards WHERE card_id IS NOT NULL) AS target_cards,
  (SELECT count(*) FROM deck6_cards d JOIN target_names t USING (normalized_name)) AS target_in_deck6,
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE source = 'curated'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS current_curated_runtime_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE source = 'generated'
      AND review_status = 'needs_review'
      AND execution_status = 'review_only'
  ) AS current_generated_review_only_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND coalesce(oracle_hash, '') = ''
  ) AS current_trusted_missing_hash_rows,
  (
    SELECT count(*)
    FROM target_rules tr
    JOIN target_names t USING (normalized_name)
    WHERE tr.logical_rule_key = t.new_logical_rule_key
  ) AS new_rule_key_rows_already_present,
  (
    SELECT count(*)
    FROM live_cards
    WHERE live_oracle_hash = expected_oracle_hash
  ) AS live_oracle_hash_matches,
  (
    SELECT count(*)
    FROM target_rules
    WHERE review_status NOT IN ('deprecated', 'rejected')
      AND (
        review_status = 'needs_review'
        OR execution_status IN ('review_only', 'disabled')
      )
  ) AS active_review_only_rows,
  (
    SELECT CASE
      WHEN to_regclass('manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200') IS NULL THEN 0
      ELSE 1
    END
  ) AS backup_table_exists;
