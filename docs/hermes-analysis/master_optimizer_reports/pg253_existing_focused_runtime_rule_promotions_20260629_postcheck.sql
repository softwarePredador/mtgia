WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('heroes remembered', 'Heroes Remembered', '0a349cd92e9d1e5f0f4887e6f12c75b7', 'battle_rule_v1:4978416393dc912bc2d6d090afde8dc8'),
    ('single combat', 'Single Combat', 'be6bde23599b29cf800eefe5f11416f6', 'battle_rule_v1:45c2a4f6d6d4930fb4cb54b8fa886bc2'),
    ('the warring triad', 'The Warring Triad', '4b71a0484cf31247d62e92ca0bf27efd', 'battle_rule_v1:1b92340f98d8dd60da33dbd03e915d23'),
    ('toralf, god of fury // toralf''s hammer', 'Toralf, God of Fury // Toralf''s Hammer', '900c199972617df82c6ddf796e2cf04f', 'battle_rule_v1:733e913423b3c4471520195c8a814097'),
    ('unstable glyphbridge // sandswirl wanderglyph', 'Unstable Glyphbridge // Sandswirl Wanderglyph', 'e56f55f81b1f72be8c4e3752f1916898', 'battle_rule_v1:f4168e92445f0a9b9b2de0ef32f4b78d'),
    ('vedalken orrery', 'Vedalken Orrery', '1fa2fc4b26db2e2d0691f8170d03b4db', 'battle_rule_v1:9e2c7c96d5b2a117731924d511bb0e2a'),
    ('wand of vertebrae', 'Wand of Vertebrae', '71de2615587654002b225714c5130a68', 'battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131'),
    ('whispersilk cloak', 'Whispersilk Cloak', '5384a7231f4c91ab45b4007b0ac7f8dc', 'battle_rule_v1:776e69f786c18a8398012554b8e22907'),
    ('wild ricochet', 'Wild Ricochet', 'c7d62b1c3e0178970919cd0fc3b6b995', 'battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a')
), promoted AS (
  SELECT p.card_name, p.normalized_name, p.logical_rule_key, r.review_status, r.execution_status, r.oracle_hash, r.effect_json->>'effect' AS effect, r.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM proposed p
  LEFT JOIN public.card_battle_rules r ON r.normalized_name = p.normalized_name AND r.logical_rule_key = p.logical_rule_key AND r.oracle_hash = p.oracle_hash
), shadows AS (
  SELECT p.normalized_name, count(*) AS backup_rows
  FROM proposed p
  LEFT JOIN public.pg253_existing_focused_runtime_rule_promotions_backup b ON b.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
)
SELECT pr.card_name, pr.normalized_name, pr.logical_rule_key, pr.review_status, pr.execution_status, pr.oracle_hash, pr.effect, pr.battle_model_scope, (pr.review_status = 'verified' AND coalesce(pr.execution_status, 'auto') IN ('auto','executable')) AS promoted_runtime_rule, coalesce(sh.backup_rows, 0) AS backup_rows
FROM promoted pr
LEFT JOIN shadows sh ON sh.normalized_name = pr.normalized_name
ORDER BY pr.card_name;
