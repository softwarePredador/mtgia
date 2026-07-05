WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('akki rockspeaker', 'Akki Rockspeaker', '2c1c6bf2eb1ec865d84ff82c4f54029f', 'battle_rule_v1:03d10668e241154656a14f9ac5949550', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":1,"etb_produced_mana_symbols":["R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkkiRockspeaker translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('burning-tree emissary', 'Burning-Tree Emissary', 'e48292b20c3297f830d2490664f3be82', 'battle_rule_v1:26c40d0b0bdd51355b5247591324af4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":2,"etb_produced_mana_symbols":["R","G"],"etb_produces":"RG","instant":false,"is_mana_source":false,"mana_produced":2,"permanent_type":"creature","produced_mana_symbols":["R","G"],"produces":"RG","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurningTreeEmissary translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of gix', 'Priest of Gix', '53270f2d1fd5d1d54f791d3b097b3138', 'battle_rule_v1:2d3e4b8f02be6791b9d9707558b0ccd6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["B","B","B"],"etb_produces":"B","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfGix translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of urabrask', 'Priest of Urabrask', '473d8c63d1fcef29a0a4a634f4f6c847', 'battle_rule_v1:e98b5dbd90254c3b996852a344bcfc08', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["R","R","R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfUrabrask translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
