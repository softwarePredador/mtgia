WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('acceptable losses', 'Acceptable Losses', 'd71a8b345ef6a001cfed89e257f4646b', 'battle_rule_v1:2d54e8c21001b6b365fe81b0af6428a1', '{"additional_cost":"discard_card","amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":false,"requires_discard_card":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcceptableLosses translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('artillerize', 'Artillerize', '2f71833ab097a370cd7c333082ea00a9', 'battle_rule_v1:b03ad22ee07402503a2f5d9209d44cea', '{"additional_cost":"sacrifice_artifact_or_creature","amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Artillerize translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bone splinters', 'Bone Splinters', '5b0fa8f1b681a6327b1ffe89ef0ffbc9', 'battle_rule_v1:f4fb67d9af26b5ed562b437b85d0e3d3', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneSplinters translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('costly plunder', 'Costly Plunder', '84da77cf84c1f1e0dd6871f3694d69e6', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CostlyPlunder translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('embrace oblivion', 'Embrace Oblivion', '05e8fd4bf8fae8602b5883385f75a6aa', 'battle_rule_v1:1330d6b65c530f0725148ec8f4e16576', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceOblivion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('eviscerator''s insight', 'Eviscerator''s Insight', 'ca7da5d236140d33d01189b3510dcdeb', 'battle_rule_v1:e2ae9a881c3814ca8cb290d9c51f3747', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvisceratorsInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('improvised club', 'Improvised Club', '0276e05f9d0f18098753d013f7d64bdc', 'battle_rule_v1:493c7acef4e465b2707cebd170fdcaae', '{"additional_cost":"sacrifice_artifact_or_creature","amount":4,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":4,"effect":"direct_damage","instant":true,"requires_sacrifice_artifact_or_creature":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImprovisedClub translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid curiosity', 'Morbid Curiosity', '914abef9d9dc0dfeb33d5d64c8c01ecd', 'battle_rule_v1:859624352dbbdcf775e576fe8623cacb', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":1,"effect":"draw_cards","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidCuriosity translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('powerstone fracture', 'Powerstone Fracture', 'a5c06a971f3a0473c0568aba333cf79a', 'battle_rule_v1:142000d6120e9a04710f8a2cc31524b2', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PowerstoneFracture translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raze', 'Raze', 'e0d0084f1ad04bd705cf38689a523622', 'battle_rule_v1:476f315b753e08d325a53d881500898a', '{"additional_cost":"sacrifice_land","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_land":true,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Raze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sonic burst', 'Sonic Burst', 'f1d456de114f89b1ff85f8eebfebcd9e', 'battle_rule_v1:a0c1a4a0bc59e29bab995cb6b485cf06', '{"additional_cost":"discard_card","amount":4,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":4,"effect":"direct_damage","instant":true,"requires_discard_card":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SonicBurst translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sonic seizure', 'Sonic Seizure', 'f9bc1cc90ada44379e53fc5d45cf195e', 'battle_rule_v1:59a9093067f1a0eceeaec3adeab4a21b', '{"additional_cost":"discard_card","amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","instant":true,"requires_discard_card":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SonicSeizure translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
