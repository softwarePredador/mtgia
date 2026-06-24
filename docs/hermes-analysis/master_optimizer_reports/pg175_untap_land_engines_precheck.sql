WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('candelabra of tawnos', 'Candelabra of Tawnos', '6121bd69a2275cd8f8a88699fd819713', 'battle_rule_v1:025b56533a93506e5517b27a42dcf059', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic_from_x":true,"activation_requires_tap":true,"battle_model_scope":"x_tap_untap_x_lands_v1","effect":"untap_land_engine","untap_target_land_count_from_x":true,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CandelabraOfTawnos mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('earthcraft', 'Earthcraft', 'f6496abac3c3abd4e9aceb27ba70f866', 'battle_rule_v1:7b54c5adbb14d83b32b736efd1c694a2', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_taps_untapped_creature_you_control":true,"battle_model_scope":"tap_untapped_creature_untap_target_basic_land_v1","effect":"untap_land_engine","untap_target_land_basic_only":true,"untap_target_land_count":1,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Earthcraft mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('magus of the candelabra', 'Magus of the Candelabra', '6121bd69a2275cd8f8a88699fd819713', 'battle_rule_v1:5ebc277a81704d086c4c9009ce3863dc', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic_from_x":true,"activation_requires_tap":true,"battle_model_scope":"creature_x_tap_untap_x_lands_v1","effect":"untap_land_engine","power":1,"toughness":2,"untap_target_land_count_from_x":true,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MagusOfTheCandelabra mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('oboro breezecaller', 'Oboro Breezecaller', '51aa9c6083f41d49800b21ebe5bd49df', 'battle_rule_v1:09d7cae21ee60dcada5b267602355036', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic":2,"activation_returns_land_to_hand":true,"battle_model_scope":"pay_two_return_land_untap_target_land_v1","effect":"untap_land_engine","flying":true,"power":1,"toughness":1,"untap_target_land_count":1,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class OboroBreezecaller mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
