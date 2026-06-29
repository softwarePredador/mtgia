WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, shadow_handling) AS (
  VALUES
    ('treasonous ogre', 'Treasonous Ogre', '741590c7114b82776c38a21056cfed58', 'battle_rule_v1:7470f49a9a616bd658adeee6c6d2f1d8', 'deprecate_nonmatching_rows')
), pg_cards AS (
  SELECT p.*, c.id AS card_id, c.name AS pg_card_name, md5(coalesce(c.oracle_text, '')) AS pg_oracle_hash
  FROM proposed p
  LEFT JOIN public.cards c
    ON (lower(c.name) = p.normalized_name OR split_part(lower(c.name), ' // ', 1) = p.normalized_name)
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
), current_rules AS (
  SELECT p.normalized_name, count(r.*) AS current_rule_rows,
         count(*) FILTER (WHERE r.review_status IN ('verified','active') AND coalesce(r.execution_status,'auto') IN ('auto','executable')) AS active_runtime_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
)
SELECT p.card_name, p.normalized_name, p.oracle_hash AS proposed_oracle_hash,
       count(pc.card_id) AS oracle_matched_card_rows,
       coalesce(max(cr.current_rule_rows), 0) AS current_rule_rows,
       coalesce(max(cr.active_runtime_rows), 0) AS active_runtime_rows,
       p.shadow_handling
FROM proposed p
LEFT JOIN pg_cards pc ON pc.normalized_name = p.normalized_name
LEFT JOIN current_rules cr ON cr.normalized_name = p.normalized_name
GROUP BY p.card_name, p.normalized_name, p.oracle_hash, p.shadow_handling
ORDER BY p.card_name;
