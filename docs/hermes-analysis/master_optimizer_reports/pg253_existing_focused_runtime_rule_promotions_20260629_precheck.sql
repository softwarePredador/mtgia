WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, shadow_handling) AS (
  VALUES
    ('heroes remembered', 'Heroes Remembered', '0a349cd92e9d1e5f0f4887e6f12c75b7', 'battle_rule_v1:4978416393dc912bc2d6d090afde8dc8', 'deprecate_nonmatching_rows'),
    ('single combat', 'Single Combat', 'be6bde23599b29cf800eefe5f11416f6', 'battle_rule_v1:45c2a4f6d6d4930fb4cb54b8fa886bc2', 'deprecate_nonmatching_rows'),
    ('the warring triad', 'The Warring Triad', '4b71a0484cf31247d62e92ca0bf27efd', 'battle_rule_v1:1b92340f98d8dd60da33dbd03e915d23', 'deprecate_nonmatching_rows'),
    ('toralf, god of fury // toralf''s hammer', 'Toralf, God of Fury // Toralf''s Hammer', '900c199972617df82c6ddf796e2cf04f', 'battle_rule_v1:733e913423b3c4471520195c8a814097', 'deprecate_nonmatching_rows'),
    ('unstable glyphbridge // sandswirl wanderglyph', 'Unstable Glyphbridge // Sandswirl Wanderglyph', 'e56f55f81b1f72be8c4e3752f1916898', 'battle_rule_v1:f4168e92445f0a9b9b2de0ef32f4b78d', 'deprecate_nonmatching_rows'),
    ('vedalken orrery', 'Vedalken Orrery', '1fa2fc4b26db2e2d0691f8170d03b4db', 'battle_rule_v1:9e2c7c96d5b2a117731924d511bb0e2a', 'deprecate_nonmatching_rows'),
    ('wand of vertebrae', 'Wand of Vertebrae', '71de2615587654002b225714c5130a68', 'battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131', 'deprecate_nonmatching_rows'),
    ('whispersilk cloak', 'Whispersilk Cloak', '5384a7231f4c91ab45b4007b0ac7f8dc', 'battle_rule_v1:776e69f786c18a8398012554b8e22907', 'deprecate_nonmatching_rows'),
    ('wild ricochet', 'Wild Ricochet', 'c7d62b1c3e0178970919cd0fc3b6b995', 'battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a', 'deprecate_nonmatching_rows')
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
