WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, shadow_handling) AS (
  VALUES
    ('hazel''s brewmaster', 'Hazel''s Brewmaster', 'a6e600363c1a67a7d0d507a0ae00021d', 'battle_rule_v1:68abb87ba90186e55c4e4341506b1c4f', 'deprecate_nonmatching_rows'),
    ('adagia, windswept bastion', 'Adagia, Windswept Bastion', 'e6878f05503ba8e6454108ddcbfca84d', 'battle_rule_v1:cc429e2792076144a1d51f692c70d726', 'preserve_existing_rows'),
    ('purphoros, god of the forge', 'Purphoros, God of the Forge', '01ee853118a4f1e5fe31a9d1e3ec6c5d', 'battle_rule_v1:2fb771380609b4d180c1e6816bf8b556', 'preserve_existing_rows')
), target_cards AS (
  SELECT
    p.normalized_name,
    p.card_name AS proposed_card_name,
    p.oracle_hash AS proposed_oracle_hash,
    p.logical_rule_key,
    p.shadow_handling,
    c.id,
    c.name AS pg_card_name,
    md5(coalesce(c.oracle_text, '')) AS pg_oracle_hash
  FROM proposed p
  LEFT JOIN public.cards c
    ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
), current_rules AS (
  SELECT
    p.normalized_name,
    count(r.*) AS current_rule_rows,
    count(*) FILTER (WHERE r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable')) AS active_runtime_rows,
    jsonb_agg(to_jsonb(r) ORDER BY r.logical_rule_key) FILTER (WHERE r.normalized_name IS NOT NULL) AS current_rules
  FROM proposed p
  LEFT JOIN public.card_battle_rules r ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  p.shadow_handling,
  count(tc.id) AS oracle_matched_card_rows,
  coalesce(max(cr.current_rule_rows), 0) AS current_rule_rows,
  coalesce(max(cr.active_runtime_rows), 0) AS active_runtime_rows,
  max(cr.current_rules::text) AS current_rules
FROM proposed p
LEFT JOIN target_cards tc ON tc.normalized_name = p.normalized_name
LEFT JOIN current_rules cr ON cr.normalized_name = p.normalized_name
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.shadow_handling
ORDER BY p.card_name;
