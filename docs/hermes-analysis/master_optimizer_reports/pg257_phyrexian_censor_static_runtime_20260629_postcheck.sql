WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('phyrexian censor', 'Phyrexian Censor', 'deafed84b14f2008e85145ee17c162a7', 'battle_rule_v1:166240c94a4f8ba33fc80549c236deb7')
)
SELECT p.card_name, r.normalized_name, r.logical_rule_key, r.source, r.review_status, r.execution_status, r.oracle_hash,
       (r.oracle_hash = p.oracle_hash) AS oracle_hash_matches,
       (r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS promoted_runtime_rule
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
ORDER BY p.card_name;
