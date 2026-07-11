WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('battle hymn', 'Battle Hymn', 'd10736bf0f1c20741e6573e8a0f9756f', 'battle_rule_v1:ecc388cb0b7a7b6053fa356c319a35d0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_battlefield_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_battlefield_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleHymn translated into ManaLoom runtime scope xmage_controlled_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('channel the suns', 'Channel the Suns', '00f37ae750187d98c2ee7ef1cefe2d81', 'battle_rule_v1:99bac902f7bd0c57a57d2986e5798b55', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","effect":"ramp_ritual","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":5,"produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":true,"xmage_effect_class":"AddManaToManaPoolSourceControllerEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChannelTheSuns translated into ManaLoom runtime scope xmage_fixed_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inner fire', 'Inner Fire', '8a7377dabd39dd4288983536683a62c2', 'battle_rule_v1:5c3ffd7cf5ad80a9c9334df4e439b863', '{"ability_kind":"one_shot","battle_model_scope":"xmage_hand_size_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_hand_size","effect":"ramp_ritual","instant":false,"mana_amount_model":"controller_hand_size","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":true,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnerFire translated into ManaLoom runtime scope xmage_hand_size_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('songs of the damned', 'Songs of the Damned', 'bd0c43c5486b85ec17a57ad84ebfef68', 'battle_rule_v1:5a7a56cb9e6b6ff52ebe704b292915ba', '{"ability_kind":"one_shot","battle_model_scope":"xmage_graveyard_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_graveyard_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_graveyard_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"B","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SongsOfTheDamned translated into ManaLoom runtime scope xmage_graveyard_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
