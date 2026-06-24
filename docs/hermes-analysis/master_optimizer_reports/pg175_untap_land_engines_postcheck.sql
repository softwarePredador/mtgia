WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('candelabra of tawnos', 'Candelabra of Tawnos', '6121bd69a2275cd8f8a88699fd819713', 'battle_rule_v1:025b56533a93506e5517b27a42dcf059', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic_from_x":true,"activation_requires_tap":true,"battle_model_scope":"x_tap_untap_x_lands_v1","effect":"untap_land_engine","untap_target_land_count_from_x":true,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CandelabraOfTawnos mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('earthcraft', 'Earthcraft', 'f6496abac3c3abd4e9aceb27ba70f866', 'battle_rule_v1:7b54c5adbb14d83b32b736efd1c694a2', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_taps_untapped_creature_you_control":true,"battle_model_scope":"tap_untapped_creature_untap_target_basic_land_v1","effect":"untap_land_engine","untap_target_land_basic_only":true,"untap_target_land_count":1,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Earthcraft mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('magus of the candelabra', 'Magus of the Candelabra', '6121bd69a2275cd8f8a88699fd819713', 'battle_rule_v1:5ebc277a81704d086c4c9009ce3863dc', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic_from_x":true,"activation_requires_tap":true,"battle_model_scope":"creature_x_tap_untap_x_lands_v1","effect":"untap_land_engine","power":1,"toughness":2,"untap_target_land_count_from_x":true,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MagusOfTheCandelabra mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('oboro breezecaller', 'Oboro Breezecaller', '51aa9c6083f41d49800b21ebe5bd49df', 'battle_rule_v1:09d7cae21ee60dcada5b267602355036', '{"ability_kind":"activated","activated_untap_lands_for_mana_unlock":true,"activation_cost_generic":2,"activation_returns_land_to_hand":true,"battle_model_scope":"pay_two_return_land_untap_target_land_v1","effect":"untap_land_engine","flying":true,"power":1,"toughness":1,"untap_target_land_count":1,"untap_target_land_restriction":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class OboroBreezecaller mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg175_untap_land_engines_20260624_130140) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
