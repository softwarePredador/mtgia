WITH targets AS (
  SELECT *
  FROM (
    VALUES
      (
        'everflowing chalice',
        'Everflowing Chalice',
        'battle_rule_v1:67f848a7a9f40c7337ec0c13e0c1de7c',
        'battle_rule_v1:b1b7f5c96002524c469ae4efa7f7bf71'
      ),
      (
        'vexing bauble',
        'Vexing Bauble',
        'battle_rule_v1:6a85170698c85498bf618c0c0283a770',
        'battle_rule_v1:ad19691a7b388a47b6775f5e16275403'
      ),
      (
        'soul-guide lantern',
        'Soul-Guide Lantern',
        'battle_rule_v1:3454aa122d10a4abd906132eb7745339',
        'battle_rule_v1:720260c93bdae63518a0721df51089c3'
      )
  ) AS t(normalized_name, card_name, reviewed_rule_key, manual_model_rule_key)
)
SELECT
  t.card_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json
FROM targets t
JOIN public.card_battle_rules r
  ON r.normalized_name = t.normalized_name
WHERE r.logical_rule_key IN (t.reviewed_rule_key, t.manual_model_rule_key)
ORDER BY t.card_name, r.logical_rule_key;
