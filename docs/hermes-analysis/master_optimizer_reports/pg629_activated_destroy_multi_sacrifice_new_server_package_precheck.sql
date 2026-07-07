WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('earthblighter', 'Earthblighter', 'a609a168f73ac8403e9a5bb434e4dd87', 'battle_rule_v1:5a02d463ae3227ecdfa5e79a1dc61f02', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"target_subtypes":["goblin"]},"count":1,"target_controller":"self"},"activation_sacrifice_target":"goblin","battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Earthblighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('keldon arsonist', 'Keldon Arsonist', '90a229a35b52b4ff9de4f8c2cf326ad3', 'battle_rule_v1:5fc918ece0734a39ee3c3c769dcf2e90', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"land","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"land","target_constraints":{"card_types":["land"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KeldonArsonist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krark-clan engineers', 'Krark-Clan Engineers', '2f1cda4d8f42234f9842aa5a97f228cf', 'battle_rule_v1:30271844421547419ce80f41ac149976', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"artifact","activation_cost_colors":["R"],"activation_cost_generic":0,"activation_cost_mana":"{R}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_cost":{"constraints":{"card_types":["artifact"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrarkClanEngineers translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sandstone deadfall', 'Sandstone Deadfall', '802dab23ebd4e4fff2c2917fff7cdc24', 'battle_rule_v1:fe81aae4282d4895faf30755ec9f8989', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"attacking_creature","activated_self_sacrifice_destroy":true,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":true,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_cost":{"constraints":{"card_types":["land"]},"count":2,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"artifact","target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SandstoneDeadfall translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
