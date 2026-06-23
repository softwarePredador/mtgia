\pset pager off

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
),
target_rows AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    c.name,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.confidence,
    cbr.rule_version,
    cbr.oracle_hash,
    cbr.effect_json,
    cbr.deck_role_json,
    backup.payload AS backup_payload
  FROM target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
  LEFT JOIN manaloom_deploy_audit.pg077_deck6_hash_provenance_restore_20260623_062156 backup
    ON backup.payload->>'normalized_name' = cbr.normalized_name
   AND backup.payload->>'logical_rule_key' = cbr.logical_rule_key
),
shadow_rows AS (
  SELECT count(*) AS active_shadow_rows
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT normalized_name FROM target_rules)
    AND NOT EXISTS (
      SELECT 1
      FROM target_rules t
      WHERE t.normalized_name = cbr.normalized_name
        AND t.logical_rule_key = cbr.logical_rule_key
    )
    AND cbr.execution_status NOT IN ('disabled', 'review_only')
    AND cbr.review_status NOT IN ('deprecated', 'needs_review')
)
SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE execution_status = 'auto' AND review_status IN ('active', 'verified')) AS trusted_auto_rows,
  count(*) FILTER (WHERE backup_payload IS NOT NULL) AS target_backup_rows,
  count(*) FILTER (WHERE effect_json = backup_payload->'effect_json') AS effect_json_unchanged_rows,
  count(*) FILTER (WHERE deck_role_json = backup_payload->'deck_role_json') AS deck_role_json_unchanged_rows,
  (SELECT active_shadow_rows FROM shadow_rows) AS old_active_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg077_deck6_hash_provenance_restore_20260623_062156) AS total_backup_rows
FROM target_rows;

WITH target_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
)
SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.rule_version,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  cbr.effect_json,
  cbr.notes
FROM target_rules t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY c.name;
