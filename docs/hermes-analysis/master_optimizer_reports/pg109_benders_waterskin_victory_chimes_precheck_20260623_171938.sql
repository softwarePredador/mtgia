WITH wanted(normalized_name, expected_key, expected_hash) AS (
  VALUES
    ('bender''s waterskin', 'battle_rule_v1:cf94f06a51a48080913a6c01290c7be2', '1bd371e1f09ed8b48837c3fc5cd2a2ff'),
    ('victory chimes', 'battle_rule_v1:85d354bb1522e745de9e1bac865fd5e0', '8ca84e1f2e9f3efd1fe740d16d216105')
),
target_cards AS (
  SELECT lower(name) AS normalized_name, id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) IN (SELECT normalized_name FROM wanted)
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name IN (SELECT normalized_name FROM wanted)
)
SELECT
  w.normalized_name,
  count(DISTINCT tc.id) AS target_card_rows,
  count(DISTINCT tc.id) FILTER (WHERE tc.oracle_hash = w.expected_hash) AS card_oracle_hash_match_rows,
  count(DISTINCT rr.logical_rule_key) AS existing_rule_rows,
  count(DISTINCT rr.logical_rule_key) FILTER (WHERE rr.logical_rule_key = w.expected_key) AS expected_rule_rows_before,
  count(DISTINCT rr.logical_rule_key) FILTER (WHERE rr.review_status IN ('verified', 'active') AND rr.execution_status IN ('auto', 'executable')) AS trusted_rule_rows_before,
  count(DISTINCT rr.logical_rule_key) FILTER (WHERE rr.logical_rule_key <> w.expected_key AND rr.review_status NOT IN ('deprecated', 'rejected') AND rr.execution_status <> 'disabled') AS would_deprecate_shadow_rows,
  count(DISTINCT rr.logical_rule_key) FILTER (WHERE rr.review_status IN ('verified', 'active') AND rr.execution_status IN ('auto', 'executable') AND coalesce(rr.oracle_hash, '') = '') AS trusted_missing_oracle_hash_rows_before,
  count(DISTINCT rr.logical_rule_key) FILTER (WHERE rr.effect_json->>'effect' = 'draw_engine' AND rr.review_status IN ('verified', 'active') AND rr.execution_status IN ('auto', 'executable')) AS active_draw_engine_rows_before
FROM wanted w
LEFT JOIN target_cards tc ON tc.normalized_name = w.normalized_name
LEFT JOIN rule_rows rr ON rr.normalized_name = w.normalized_name
GROUP BY w.normalized_name, w.expected_key, w.expected_hash
ORDER BY w.normalized_name;

SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM public.card_battle_rules
WHERE normalized_name IN ('bender''s waterskin', 'victory chimes')
ORDER BY normalized_name, logical_rule_key;
