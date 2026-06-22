\pset pager off

WITH wanted(card_name, logical_rule_key, expected_oracle_hash, desired_scope) AS (
  VALUES
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', '77d31b859247e6129c25b4fa47be336e', 'silent_arbiter_global_single_attacker_v2'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'da1c62032e405fc6fc6151ccdf6df879', 'magus_of_the_moat_global_flying_attack_filter_v2'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'f5f24e3b4b9f6a52fb0afa1cef9ae3d3', 'ensnaring_bridge_controller_hand_size_power_filter_v2')
),
current_rows AS (
  SELECT
    w.card_name,
    w.logical_rule_key,
    w.expected_oracle_hash,
    w.desired_scope,
    c.id AS card_id,
    c.name AS pg_card_name,
    c.type_line,
    c.color_identity,
    cl.status AS commander_status,
    md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
    cbr.effect_json,
    cbr.deck_role_json,
    cbr.review_status,
    cbr.execution_status,
    cbr.notes
  FROM wanted w
  LEFT JOIN cards c ON lower(c.name) = lower(w.card_name)
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = lower(w.card_name)
   AND cbr.logical_rule_key = w.logical_rule_key
)
SELECT
  'pg021_global_attack_rule_scope_precheck_rows' AS check_name,
  *
FROM current_rows
ORDER BY card_name;

WITH wanted(card_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('Silent Arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7', '77d31b859247e6129c25b4fa47be336e'),
    ('Magus of the Moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a', 'da1c62032e405fc6fc6151ccdf6df879'),
    ('Ensnaring Bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5', 'f5f24e3b4b9f6a52fb0afa1cef9ae3d3')
),
checks AS (
  SELECT
    count(*) FILTER (WHERE c.id IS NOT NULL) AS cards_found,
    count(*) FILTER (WHERE cl.status = 'legal') AS commander_legal_rows,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) = w.expected_oracle_hash
    ) AS oracle_hash_matches,
    count(*) FILTER (WHERE cbr.logical_rule_key IS NOT NULL) AS existing_rule_rows,
    count(*) FILTER (WHERE cbr.review_status = 'verified' AND cbr.execution_status = 'auto') AS runtime_rule_rows
  FROM wanted w
  LEFT JOIN cards c ON lower(c.name) = lower(w.card_name)
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = lower(w.card_name)
   AND cbr.logical_rule_key = w.logical_rule_key
)
SELECT
  'pg021_global_attack_rule_scope_precheck_ready' AS check_name,
  cards_found,
  commander_legal_rows,
  oracle_hash_matches,
  existing_rule_rows,
  runtime_rule_rows,
  (
    cards_found = 3
    AND commander_legal_rows = 3
    AND oracle_hash_matches = 3
    AND existing_rule_rows = 3
    AND runtime_rule_rows = 3
  ) AS ready_to_apply
FROM checks;
