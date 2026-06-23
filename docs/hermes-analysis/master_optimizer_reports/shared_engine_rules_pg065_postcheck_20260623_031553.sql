\pset pager off

WITH expected(card_name, normalized_name, logical_rule_key, expected_oracle_hash, expected_effect, expected_scope) AS (
  VALUES
    (
      'Scroll Rack',
      'scroll rack',
      'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2',
      '8133928f03d5a5a77f2beecfcbd09e30',
      'topdeck_manipulation',
      'scroll_rack_upkeep_single_exchange_v1'
    ),
    (
      'Smothering Tithe',
      'smothering tithe',
      'battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6',
      'bb7d29c1a84a53604c017da1b5f0620c',
      'ramp_engine',
      'opponent_draw_tax_treasure_v1'
    )
),
target_rules AS (
  SELECT
    e.card_name,
    e.normalized_name,
    e.logical_rule_key,
    e.expected_oracle_hash,
    e.expected_effect,
    e.expected_scope,
    cbr.effect_json,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.source,
    cbr.confidence,
    cbr.rule_version
  FROM expected e
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
),
all_target_rules AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name IN (SELECT normalized_name FROM expected)
)
SELECT
  (SELECT count(*) FROM target_rules WHERE logical_rule_key IS NOT NULL) AS target_rule_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS target_runtime_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE oracle_hash IS DISTINCT FROM expected_oracle_hash
  ) AS target_hash_mismatch_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE effect_json->>'effect' IS DISTINCT FROM expected_effect
  ) AS target_bad_effect_rows,
  (
    SELECT count(*)
    FROM target_rules
    WHERE effect_json->>'battle_model_scope' IS DISTINCT FROM expected_scope
  ) AS target_bad_scope_rows,
  (
    SELECT count(*)
    FROM all_target_rules tr
    WHERE tr.review_status NOT IN ('deprecated', 'rejected')
      AND tr.execution_status <> 'disabled'
      AND NOT EXISTS (
        SELECT 1
        FROM expected e
        WHERE e.normalized_name = tr.normalized_name
          AND e.logical_rule_key = tr.logical_rule_key
      )
  ) AS old_active_shadow_rows,
  (
    SELECT count(*)
    FROM all_target_rules tr
    WHERE tr.review_status IN ('verified', 'active')
      AND tr.execution_status IN ('auto', 'executable')
      AND nullif(tr.oracle_hash, '') IS NULL
  ) AS trusted_executable_without_oracle_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg065_shared_engine_rules_20260623_031553
  ) AS backup_rows,
  (
    SELECT jsonb_pretty(jsonb_agg(to_jsonb(target_rules) ORDER BY card_name))
    FROM target_rules
  ) AS target_rules;
