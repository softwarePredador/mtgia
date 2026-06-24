WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('expedition map', 'Expedition Map', '03a510edd2cc7011492c1c7f4a73a0c8', 'battle_rule_v1:e6e3f483c5eb366bcd6109b743518c40', '{"ability_kind":"activated","activated_self_sacrifice_tutor_to_hand":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"activated_self_sacrifice_land_tutor_to_hand_artifact_v1","effect":"ramp_permanent","tutor_destination":"hand","tutor_target":"land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ExpeditionMap mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('moonsilver key', 'Moonsilver Key', 'dea539b1ab6b8022840db67f2bf0c2d6', 'battle_rule_v1:720fa891c12918f180a36ff13efe7ef8', '{"ability_kind":"activated","activated_self_sacrifice_tutor_to_hand":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"activated_self_sacrifice_artifact_mana_ability_or_basic_land_tutor_to_hand_v1","effect":"ramp_permanent","tutor_destination":"hand","tutor_target":"artifact_mana_ability_or_basic_land"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MoonsilverKey mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('weathered wayfarer', 'Weathered Wayfarer', 'f69def908804331b655fcf9c8e19d67b', 'battle_rule_v1:7df98700ba8ee232d2a8b15f1296ef47', '{"ability_kind":"activated","activation_condition":"opponent_controls_more_lands","activation_cost_colors":["W"],"activation_cost_generic":0,"activation_requires_tap":true,"battle_model_scope":"activated_opponent_more_lands_land_tutor_to_hand_creature_v1","effect":"creature","land_tutor_to_hand_activated":true,"power":1,"toughness":1,"tutor_destination":"hand","tutor_target":"land"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WeatheredWayfarer mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg162_activated_tutor_to_hand_20260624_101026) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
