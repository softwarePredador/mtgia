WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('treasonous ogre', 'Treasonous Ogre', '741590c7114b82776c38a21056cfed58', 'battle_rule_v1:7470f49a9a616bd658adeee6c6d2f1d8')
)
SELECT p.card_name, r.normalized_name, r.logical_rule_key, r.source, r.review_status, r.execution_status, r.oracle_hash,
       (r.oracle_hash = p.oracle_hash) AS oracle_hash_matches,
       (r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS promoted_runtime_rule
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
ORDER BY p.card_name;
