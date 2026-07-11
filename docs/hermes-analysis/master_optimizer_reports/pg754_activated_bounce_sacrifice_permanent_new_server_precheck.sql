WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barrin, master wizard', 'Barrin, Master Wizard', '87e6d20a7dc1c9db036ec158b494f562', 'battle_rule_v1:85bf4045766f33d584b7be8dbf294cf3', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"return_to_hand","activated_remove_effect":"remove_creature","activated_remove_target":"creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","activated_effect":"return_to_hand","activated_remove_effect":"remove_creature","activated_remove_target":"creature","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrinMasterWizard translated into ManaLoom runtime scope xmage_permanent_simple_activated_return_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dispersing orb', 'Dispersing Orb', 'b32e7eb5686ddbb4b39c03a6eb238da9', 'battle_rule_v1:5227fd189d1975e288565bf858fb26ca', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"return_to_hand","activated_remove_effect":"remove_permanent","activated_remove_target":"permanent","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","activated_effect":"return_to_hand","activated_remove_effect":"remove_permanent","activated_remove_target":"permanent","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["permanent"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"permanent","battle_model_scope":"xmage_permanent_simple_activated_return_to_hand_v1","destination":"hand","effect":"enchantment","target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DispersingOrb translated into ManaLoom runtime scope xmage_permanent_simple_activated_return_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
