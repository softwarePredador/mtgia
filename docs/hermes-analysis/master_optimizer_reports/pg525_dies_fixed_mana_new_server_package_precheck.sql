WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cathodion', 'Cathodion', '8eee9f6f80a8f71952699262b53de665', 'battle_rule_v1:99e2345f9e2822ce6c5f437fa28dbfe4', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":3,"dies_produced_mana_symbols":["C","C","C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cathodion translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr moonvessel', 'Myr Moonvessel', 'bedc3ee1326649ad0f54b11502533026', 'battle_rule_v1:d21552b190e879250ea80be10bbd88da', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":1,"dies_produced_mana_symbols":["C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrMoonvessel translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('su-chi', 'Su-Chi', '304214b937f688ed7bf116c9d7a9bb68', 'battle_rule_v1:50e81199eb12ebc399f9655afa70bd0c', '{"ability_kind":"triggered","battle_model_scope":"xmage_permanent_dies_add_fixed_mana_v1","dies_mana_produced":4,"dies_produced_mana_symbols":["C","C","C","C"],"dies_produces":"C","effect":"creature","instant":false,"permanent_type":"artifact_creature","sorcery":false,"trigger":"dies","trigger_effect":"add_mana","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuChi translated into ManaLoom runtime scope xmage_permanent_dies_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow permanent with fixed dies mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
