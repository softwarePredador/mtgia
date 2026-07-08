WITH missing AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
)
SELECT
  count(*) AS trusted_executable_rules_missing_oracle_hash
FROM missing;

WITH touched AS (
  SELECT
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') <> ''
    AND r.updated_at >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
)
SELECT
  count(*) AS recently_hashed_trusted_executable_rules
FROM touched;
