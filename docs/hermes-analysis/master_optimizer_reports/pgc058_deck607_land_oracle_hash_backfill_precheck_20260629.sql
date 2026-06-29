WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('ancient tomb', 'battle_rule_v1:c364544e9bd651211acf851db2313ccd', '5f61966c5bfc67508502d929ca891af3'),
    ('command beacon', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '6dd67a5b15e472ba84c942ab36ac1786'),
    ('eiganjo, seat of the empire', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', '25b37ca517c49d61b17a9dc180dc8ea8'),
    ('reliquary tower', 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be', 'ff80b35ee08bb1b68ec7c0be24d6eaaa'),
    ('sunbaked canyon', 'battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61', 'eae946655b75e4666adfbdb760bee0ff'),
    ('urza''s saga', 'battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498', '43e3b1636425f22bbd834442ddb93bc0'),
    ('war room', 'battle_rule_v1:9cdb33ac0e813c0a25d960b65dbc7417', 'd9c250570bb91d94ceae9fcd74081ef5')
),
target AS (
  SELECT
    r.normalized_name,
    r.card_name,
    r.logical_rule_key,
    r.card_id,
    r.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    e.expected_oracle_hash,
    r.review_status,
    r.execution_status
  FROM expected e
  JOIN public.card_battle_rules r
    ON r.normalized_name = e.normalized_name
   AND r.logical_rule_key = e.logical_rule_key
  JOIN public.cards c
    ON c.id = r.card_id
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE computed_oracle_hash = expected_oracle_hash
  ) AS expected_hash_rows,
  count(*) FILTER (
    WHERE coalesce(current_oracle_hash, '') = ''
  ) AS missing_hash_rows,
  count(*) FILTER (
    WHERE coalesce(current_oracle_hash, '') <> ''
      AND current_oracle_hash IS DISTINCT FROM expected_oracle_hash
  ) AS unexpected_existing_hash_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS trusted_executable_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc058_deck607_land_oracle_hash_backfill_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
