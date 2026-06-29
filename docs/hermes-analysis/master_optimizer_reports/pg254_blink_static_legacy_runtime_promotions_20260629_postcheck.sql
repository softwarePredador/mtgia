WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key) AS (
  VALUES
    ('reckless barbarian', 'Reckless Barbarian', '2624a42fe38948a6225a247ba102d11d', 'battle_rule_v1:3e4644b909f23750472f43f57c3992c9'), ('sacrifice', 'Sacrifice', '57ca43a79d7a466b97c5be6afddbbe37', 'battle_rule_v1:9f494d943f370fc23f70ab219b82c70b'), ('geosurge', 'Geosurge', 'a19284fe4a3b41b3e37b14f037c91621', 'battle_rule_v1:2323eaddfebeeae63ff261b27cd676f8'), ('mardu devotee', 'Mardu Devotee', '95569a7b24c32433f2f8386c32688a50', 'battle_rule_v1:163c8c72b0d88900703479b29584941d'), ('orcish lumberjack', 'Orcish Lumberjack', 'b63a428ffc3dff109028c603c0f54923', 'battle_rule_v1:3928f623fa6bea3e5c2fac2983d8df26'), ('faeburrow elder', 'Faeburrow Elder', '85c90e2fe09a1b85984007a14e3db900', 'battle_rule_v1:ba732f55ab31865df49e463277d20469'), ('neoform', 'Neoform', 'ae81715abd94b17c07451a09cf5b8db6', 'battle_rule_v1:1a244213e27ba84cc802817d801fdfbd'), ('ephemerate', 'Ephemerate', '4671452857f7b532c0c9cc6088b3e25c', 'battle_rule_v1:8e1b9773684b97c3d24b091de88a5517'), ('displacer kitten', 'Displacer Kitten', '16da6e6f7355a5732ee2f80d55f35ebc', 'battle_rule_v1:0bb2c233457a8f1bb2420ff43b813d05'), ('emiel the blessed', 'Emiel the Blessed', '9c568dbb78c72979a6e2e528f2ea5385', 'battle_rule_v1:c060974bde14bba7412e05ae3fae7c9d'), ('deafening silence', 'Deafening Silence', '7ee68f02b4a79a4c3e00fbe14caceda1', 'battle_rule_v1:3acd8f1cd0385cea4d18af84cb76b7bf'), ('archon of emeria', 'Archon of Emeria', 'a52d85813ecf212a3bfc84e249a2c90a', 'battle_rule_v1:160715b74767da0ffe53d66b25a44936'), ('eidolon of rhetoric', 'Eidolon of Rhetoric', 'cf8c850002241fd1afe4e8ca46884774', 'battle_rule_v1:137c1bd9ef3c7095ba82cef057c36d20'), ('ethersworn canonist', 'Ethersworn Canonist', 'e8466942a00d320a7a9c067c0861fb27', 'battle_rule_v1:34c3e895d3a7ef2fdb960e8de4403308')
)
SELECT p.card_name, r.normalized_name, r.logical_rule_key, r.source, r.review_status, r.execution_status, r.oracle_hash,
       (r.oracle_hash = p.oracle_hash) AS oracle_hash_matches,
       (r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS promoted_runtime_rule
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
ORDER BY p.card_name;
