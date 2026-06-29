WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('ashnod''s altar', 'Ashnod''s Altar', 'dd3e1f004f2b178f31b638fad9cad591', 'battle_rule_v1:5fd05007191c6e481e8371724035031c'), ('chrome mox', 'Chrome Mox', '44481be7f5347792ede1a9b679a424b3', 'battle_rule_v1:4b4ae6ec37e017046c6671e1a5985f17'), ('mox diamond', 'Mox Diamond', '517f664e6c81ce9c204c09a20e14be2d', 'battle_rule_v1:0a78dec9b9b2b0b5218b7d0a64a9afb3')
)
SELECT p.card_name, r.normalized_name, r.logical_rule_key, r.source, r.review_status, r.execution_status, r.oracle_hash,
       (r.oracle_hash = p.oracle_hash) AS oracle_hash_matches,
       (r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS promoted_runtime_rule
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
ORDER BY p.card_name;
