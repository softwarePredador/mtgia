\pset pager off

WITH expected(card_name, normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    (
      'Scroll Rack',
      'scroll rack',
      'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2',
      '8133928f03d5a5a77f2beecfcbd09e30'
    ),
    (
      'Smothering Tithe',
      'smothering tithe',
      'battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6',
      'bb7d29c1a84a53604c017da1b5f0620c'
    )
),
target_cards AS (
  SELECT
    e.card_name,
    e.normalized_name,
    e.logical_rule_key,
    e.expected_oracle_hash,
    c.id AS card_id,
    c.type_line,
    c.mana_cost,
    c.cmc,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    c.oracle_text
  FROM expected e
  LEFT JOIN cards c ON lower(c.name) = lower(e.card_name)
),
target_rules AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT normalized_name FROM expected)
)
SELECT
  (SELECT count(*) FROM target_cards WHERE card_id IS NOT NULL) AS target_card_rows,
  (SELECT count(*) FROM target_cards WHERE target_oracle_hash = expected_oracle_hash) AS expected_oracle_hash_rows,
  (SELECT count(*) FROM target_rules) AS existing_rule_rows,
  (SELECT count(*) FROM target_rules tr JOIN expected e USING (normalized_name, logical_rule_key)) AS expected_rule_key_rows,
  (
    SELECT count(*)
    FROM target_rules tr
    WHERE tr.review_status IN ('verified', 'active')
      AND tr.execution_status IN ('auto', 'executable')
      AND nullif(tr.oracle_hash, '') IS NULL
  ) AS trusted_executable_without_oracle_hash_rows,
  (
    SELECT count(*)
    FROM target_rules tr
    WHERE tr.review_status NOT IN ('deprecated', 'rejected')
      AND tr.execution_status <> 'disabled'
      AND NOT EXISTS (
        SELECT 1
        FROM expected e
        WHERE e.normalized_name = tr.normalized_name
          AND e.logical_rule_key = tr.logical_rule_key
      )
  ) AS active_shadow_rows,
  (
    SELECT jsonb_pretty(jsonb_agg(to_jsonb(target_cards) ORDER BY card_name))
    FROM target_cards
  ) AS target_cards;
