WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('hazel''s brewmaster', 'Hazel''s Brewmaster', 'a6e600363c1a67a7d0d507a0ae00021d', 'battle_rule_v1:68abb87ba90186e55c4e4341506b1c4f'),
    ('adagia, windswept bastion', 'Adagia, Windswept Bastion', 'e6878f05503ba8e6454108ddcbfca84d', 'battle_rule_v1:cc429e2792076144a1d51f692c70d726'),
    ('purphoros, god of the forge', 'Purphoros, God of the Forge', '01ee853118a4f1e5fe31a9d1e3ec6c5d', 'battle_rule_v1:2fb771380609b4d180c1e6816bf8b556')
), promoted AS (
  SELECT p.card_name, p.normalized_name, p.logical_rule_key, r.review_status, r.execution_status, r.oracle_hash, r.effect_json->>'effect' AS effect, r.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
   AND r.oracle_hash = p.oracle_hash
), shadows AS (
  SELECT p.normalized_name, count(*) AS backup_rows
  FROM proposed p
  LEFT JOIN manaloom_deploy_audit.pg251_adagia_hazel_purphoros_runtime_batch_20260629_151845 b ON b.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
)
SELECT
  pr.card_name,
  pr.normalized_name,
  pr.logical_rule_key,
  pr.review_status,
  pr.execution_status,
  pr.oracle_hash,
  pr.effect,
  pr.battle_model_scope,
  (pr.review_status = 'verified' AND pr.execution_status = 'auto') AS promoted_verified_auto,
  coalesce(sh.backup_rows, 0) AS backup_rows
FROM promoted pr
LEFT JOIN shadows sh ON sh.normalized_name = pr.normalized_name
ORDER BY pr.card_name;
