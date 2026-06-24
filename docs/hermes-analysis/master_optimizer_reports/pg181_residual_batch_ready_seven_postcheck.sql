WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brass''s bounty', 'Brass''s Bounty', 'beb029ff5233032656034de922a112f0', 'battle_rule_v1:b5dabaaaba6b2cd47cd998989c11a1fa', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"ramp","effect":"treasure_maker","subtype":"treasure_conversion","timing":"activated_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrasssBounty mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('bedevil', 'Bedevil', '77dcf646b59f535df941f6716b802b26', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Bedevil mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cathartic reunion', 'Cathartic Reunion', '27da1fd996cc7f3a85a98aea3b6c030b', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CatharticReunion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crackle with power', 'Crackle with Power', 'cf0db23411445756ee792506b48ae35d', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CrackleWithPower mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('invoke justice', 'Invoke Justice', 'a98214114b5acd853842ac7590854785', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class InvokeJustice mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steelshaper''s gift', 'Steelshaper''s Gift', '8f894c3b42872f60142063c115ef3c9a', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteelshapersGift mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('locket of yesterdays', 'Locket of Yesterdays', '556810471067d11936662c3406a207c8', 'battle_rule_v1:09662427b256781a39f50dd00ba9735b', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LocketOfYesterdays mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg181_residual_batch_ready_seven_20260624_143655) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
