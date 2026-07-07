WITH expected(target_name, target_card_id, logical_rule_key, expected_oracle_hash, expected_role_category, expected_role_effect) AS (
  VALUES
    (
      'Birds of Paradise // Birds of Paradise',
      'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
      'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
      '2119fc1976cfab2480a9d86c57f1859b',
      'ramp',
      'creature'
    ),
    (
      'Sol Ring // Sol Ring',
      'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid,
      'battle_rule_v1:42621fcae461313f674d46db0da059af',
      '7d286f5619ac8934fb07abf152ffcb60',
      'ramp',
      'ramp_permanent'
    )
),
target_check AS (
  SELECT
    e.target_name,
    count(r.*) FILTER (
      WHERE r.card_id = e.target_card_id
        AND r.logical_rule_key = e.logical_rule_key
        AND r.review_status = 'verified'
        AND r.execution_status = 'auto'
        AND r.oracle_hash = e.expected_oracle_hash
    ) AS promoted_rule_rows,
    count(r.*) FILTER (
      WHERE r.card_id = e.target_card_id
        AND r.logical_rule_key = e.logical_rule_key
        AND r.deck_role_json->>'category' = e.expected_role_category
        AND r.deck_role_json->>'effect' = e.expected_role_effect
    ) AS promoted_role_rows,
    min(r.effect_json->>'effect') FILTER (WHERE r.card_id = e.target_card_id AND r.logical_rule_key = e.logical_rule_key) AS effect,
    min(r.effect_json->>'battle_model_scope') FILTER (WHERE r.card_id = e.target_card_id AND r.logical_rule_key = e.logical_rule_key) AS scope,
    min(r.deck_role_json::text) FILTER (WHERE r.card_id = e.target_card_id AND r.logical_rule_key = e.logical_rule_key) AS deck_role_json,
    bool_or((r.effect_json->>'is_mana_source')::boolean) FILTER (WHERE r.card_id = e.target_card_id AND r.logical_rule_key = e.logical_rule_key) AS is_mana_source,
    bool_or((r.effect_json->>'mana_activation_requires_tap')::boolean) FILTER (WHERE r.card_id = e.target_card_id AND r.logical_rule_key = e.logical_rule_key) AS mana_activation_requires_tap
  FROM expected e
  LEFT JOIN public.card_battle_rules r
    ON r.card_id = e.target_card_id
   AND r.logical_rule_key = e.logical_rule_key
  GROUP BY e.target_name
),
donor_check AS (
  SELECT
    r.card_name,
    r.logical_rule_key,
    r.deck_role_json->>'category' AS role_category,
    r.deck_role_json->>'effect' AS role_effect,
    r.effect_json->>'is_mana_source' AS is_mana_source,
    r.effect_json->>'mana_activation_requires_tap' AS mana_activation_requires_tap,
    r.review_status,
    r.execution_status
  FROM public.card_battle_rules r
  WHERE (r.card_name, r.logical_rule_key) IN (
    ('Birds of Paradise', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba'),
    ('Sol Ring', 'battle_rule_v1:42621fcae461313f674d46db0da059af')
  )
)
SELECT * FROM target_check ORDER BY target_name;

WITH donor_check AS (
  SELECT
    r.card_name,
    r.logical_rule_key,
    r.deck_role_json->>'category' AS role_category,
    r.deck_role_json->>'effect' AS role_effect,
    r.effect_json->>'is_mana_source' AS is_mana_source,
    r.effect_json->>'mana_activation_requires_tap' AS mana_activation_requires_tap,
    r.review_status,
    r.execution_status
  FROM public.card_battle_rules r
  WHERE (r.card_name, r.logical_rule_key) IN (
    ('Birds of Paradise', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba'),
    ('Sol Ring', 'battle_rule_v1:42621fcae461313f674d46db0da059af')
  )
)
SELECT * FROM donor_check ORDER BY card_name;
