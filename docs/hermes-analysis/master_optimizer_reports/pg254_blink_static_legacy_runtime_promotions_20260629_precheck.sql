WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, shadow_handling) AS (
  VALUES
    ('reckless barbarian', 'Reckless Barbarian', '2624a42fe38948a6225a247ba102d11d', 'battle_rule_v1:3e4644b909f23750472f43f57c3992c9', 'deprecate_nonmatching_rows'),
    ('sacrifice', 'Sacrifice', '57ca43a79d7a466b97c5be6afddbbe37', 'battle_rule_v1:9f494d943f370fc23f70ab219b82c70b', 'deprecate_nonmatching_rows'),
    ('geosurge', 'Geosurge', 'a19284fe4a3b41b3e37b14f037c91621', 'battle_rule_v1:2323eaddfebeeae63ff261b27cd676f8', 'deprecate_nonmatching_rows'),
    ('mardu devotee', 'Mardu Devotee', '95569a7b24c32433f2f8386c32688a50', 'battle_rule_v1:163c8c72b0d88900703479b29584941d', 'deprecate_nonmatching_rows'),
    ('orcish lumberjack', 'Orcish Lumberjack', 'b63a428ffc3dff109028c603c0f54923', 'battle_rule_v1:3928f623fa6bea3e5c2fac2983d8df26', 'deprecate_nonmatching_rows'),
    ('faeburrow elder', 'Faeburrow Elder', '85c90e2fe09a1b85984007a14e3db900', 'battle_rule_v1:ba732f55ab31865df49e463277d20469', 'deprecate_nonmatching_rows'),
    ('neoform', 'Neoform', 'ae81715abd94b17c07451a09cf5b8db6', 'battle_rule_v1:1a244213e27ba84cc802817d801fdfbd', 'deprecate_nonmatching_rows'),
    ('ephemerate', 'Ephemerate', '4671452857f7b532c0c9cc6088b3e25c', 'battle_rule_v1:8e1b9773684b97c3d24b091de88a5517', 'deprecate_nonmatching_rows'),
    ('displacer kitten', 'Displacer Kitten', '16da6e6f7355a5732ee2f80d55f35ebc', 'battle_rule_v1:0bb2c233457a8f1bb2420ff43b813d05', 'deprecate_nonmatching_rows'),
    ('emiel the blessed', 'Emiel the Blessed', '9c568dbb78c72979a6e2e528f2ea5385', 'battle_rule_v1:c060974bde14bba7412e05ae3fae7c9d', 'deprecate_nonmatching_rows'),
    ('deafening silence', 'Deafening Silence', '7ee68f02b4a79a4c3e00fbe14caceda1', 'battle_rule_v1:3acd8f1cd0385cea4d18af84cb76b7bf', 'deprecate_nonmatching_rows'),
    ('archon of emeria', 'Archon of Emeria', 'a52d85813ecf212a3bfc84e249a2c90a', 'battle_rule_v1:160715b74767da0ffe53d66b25a44936', 'deprecate_nonmatching_rows'),
    ('eidolon of rhetoric', 'Eidolon of Rhetoric', 'cf8c850002241fd1afe4e8ca46884774', 'battle_rule_v1:137c1bd9ef3c7095ba82cef057c36d20', 'deprecate_nonmatching_rows'),
    ('ethersworn canonist', 'Ethersworn Canonist', 'e8466942a00d320a7a9c067c0861fb27', 'battle_rule_v1:34c3e895d3a7ef2fdb960e8de4403308', 'deprecate_nonmatching_rows')
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
