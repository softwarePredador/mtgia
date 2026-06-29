WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, shadow_handling) AS (
  VALUES
    ('ancient copper dragon', 'Ancient Copper Dragon', '776a45094149ed3e1cc8c1a408fb6318', 'battle_rule_v1:e2ac43c9f6e03e11e9fab994a5c15258', 'deprecate_nonmatching_rows'),
    ('beacon of immortality', 'Beacon of Immortality', '642c17cb019f4299d5af9954f812f8a6', 'battle_rule_v1:655c7da1b9d381d24b94b64487226598', 'deprecate_nonmatching_rows'),
    ('invincible hymn', 'Invincible Hymn', '1ef3fc195072cd1c0c2f7dd03fa875f6', 'battle_rule_v1:de6504fa068c924a1bad5f1ada35a026', 'deprecate_nonmatching_rows'),
    ('planetarium of wan shi tong', 'Planetarium of Wan Shi Tong', '67433ff9a3bb75652404373a2949a53a', 'battle_rule_v1:a2082ebdf6e7e169b97eccecbb22b36a', 'deprecate_nonmatching_rows'),
    ('radiant performer', 'Radiant Performer', '893b8d4958e842209180034ee424d134', 'battle_rule_v1:fa12ce53b0a0c4b963f4071b4fde2c9b', 'deprecate_nonmatching_rows'),
    ('rem karolus, stalwart slayer', 'Rem Karolus, Stalwart Slayer', '7d58da0feedf10778e5f0a84b724e08c', 'battle_rule_v1:1a987670b594e446e4b1a122214e549e', 'deprecate_nonmatching_rows'),
    ('rune-tail, kitsune ascendant // rune-tail''s essence', 'Rune-Tail, Kitsune Ascendant // Rune-Tail''s Essence', '41538153d9a8b81b8233170efee5f9da', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e', 'deprecate_nonmatching_rows'),
    ('sawhorn nemesis', 'Sawhorn Nemesis', '93e3f5684069bf77d7219e17f3e04a6c', 'battle_rule_v1:93e3f5684069bf77d7219e17f3e04a6c:sawhorn_nemesis_runtime_v1', 'deprecate_nonmatching_rows'),
    ('screaming nemesis', 'Screaming Nemesis', '77190ec2e1e1dcb8b15429e5d53e68bd', 'battle_rule_v1:77190ec2e1e1dcb8b15429e5d53e68bd:screaming_nemesis_runtime_v1', 'deprecate_nonmatching_rows'),
    ('semblance anvil', 'Semblance Anvil', '32a67417a2ff0e86b36986f3d0973d8c', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e', 'deprecate_nonmatching_rows'),
    ('serra ascendant', 'Serra Ascendant', 'a08a773363e4484f37512d57594b56eb', 'battle_rule_v1:c3124030acfa1668606aca59dbbb7e2e', 'deprecate_nonmatching_rows'),
    ('slickshot show-off', 'Slickshot Show-Off', '24ce626e7e7957d8e01f615ea00d9d08', 'battle_rule_v1:9fd2ff72170533330fc8ba9165bd99b4', 'deprecate_nonmatching_rows'),
    ('stuffy doll', 'Stuffy Doll', 'b3404d9b844875e0e427a0eda8011c83', 'battle_rule_v1:e7b60d9805dbf2701195f627c6ca1600', 'deprecate_nonmatching_rows'),
    ('taunt from the rampart', 'Taunt from the Rampart', '8edc08d877978569fe4b5bc7120bb771', 'battle_rule_v1:16e15ea414a18410acd151d43276651c', 'deprecate_nonmatching_rows'),
    ('the walls of ba sing se', 'The Walls of Ba Sing Se', '3eda937f066b2e5ab8fff222caecafab', 'battle_rule_v1:1e5bcf3b45fcae347879976d74d2ef84', 'deprecate_nonmatching_rows'),
    ('zirda, the dawnwaker', 'Zirda, the Dawnwaker', '23860bc4072cc27137ba346b82b9f548', 'battle_rule_v1:45c3e1db1be4f2f97a3337ce3de8f767', 'deprecate_nonmatching_rows')
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
