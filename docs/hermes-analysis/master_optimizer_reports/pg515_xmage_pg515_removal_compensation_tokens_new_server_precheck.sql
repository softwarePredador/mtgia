WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('afterlife', 'Afterlife', '0f513e428063d69c22b815c56b77be91', 'battle_rule_v1:b545b98212493f34f1c13c86d67cbc2e', '{"battle_model_scope":"xmage_destroy_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W"],"compensation_token_flying":true,"compensation_token_keywords":["flying"],"compensation_token_name":"Spirit Token","compensation_token_power":1,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Spirit","compensation_token_toughness":1,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W"],"target_controller_token_flying":true,"target_controller_token_keywords":["flying"],"target_controller_token_name":"Spirit Token","target_controller_token_power":1,"target_controller_token_subtype":"Spirit","target_controller_token_toughness":1,"xmage_effect_classes":["DestroyTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Afterlife translated into ManaLoom runtime scope xmage_destroy_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('angelic ascension', 'Angelic Ascension', '3a82cf60bc614d970705c9fb28ed052c', 'battle_rule_v1:6cc0bba433aa775b820ed771231b51e6', '{"battle_model_scope":"xmage_exile_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W"],"compensation_token_flying":true,"compensation_token_keywords":["flying"],"compensation_token_name":"Angel Token","compensation_token_power":4,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Angel","compensation_token_toughness":4,"destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W"],"target_controller_token_flying":true,"target_controller_token_keywords":["flying"],"target_controller_token_name":"Angel Token","target_controller_token_power":4,"target_controller_token_subtype":"Angel","target_controller_token_toughness":4,"xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicAscension translated into ManaLoom runtime scope xmage_exile_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beast within', 'Beast Within', '2701546210b9dc0d6a680b1f8fe46cf0', 'battle_rule_v1:7dc80aaf4838c847edf216661119d963', '{"battle_model_scope":"xmage_destroy_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["G"],"compensation_token_name":"Beast Token","compensation_token_power":3,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Beast","compensation_token_toughness":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["G"],"target_controller_token_name":"Beast Token","target_controller_token_power":3,"target_controller_token_subtype":"Beast","target_controller_token_toughness":3,"xmage_effect_classes":["DestroyTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastWithin translated into ManaLoom runtime scope xmage_destroy_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bovine intervention', 'Bovine Intervention', '0cbf5f4a1ef9b69dfbf6a9e16cd0c465', 'battle_rule_v1:1112500734b3af1f1a3aece56befd3a3', '{"battle_model_scope":"xmage_destroy_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W"],"compensation_token_name":"Ox Token","compensation_token_power":2,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Ox","compensation_token_toughness":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W"],"target_controller_token_name":"Ox Token","target_controller_token_power":2,"target_controller_token_subtype":"Ox","target_controller_token_toughness":2,"xmage_effect_classes":["DestroyTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BovineIntervention translated into ManaLoom runtime scope xmage_destroy_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harsh annotation', 'Harsh Annotation', '315d492f666084b88c225662f91b9410', 'battle_rule_v1:f7700cc39f558856bb360b783358b0c1', '{"battle_model_scope":"xmage_destroy_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W","B"],"compensation_token_flying":true,"compensation_token_keywords":["flying"],"compensation_token_name":"Inkling Token","compensation_token_power":1,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Inkling","compensation_token_toughness":1,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W","B"],"target_controller_token_flying":true,"target_controller_token_keywords":["flying"],"target_controller_token_name":"Inkling Token","target_controller_token_power":1,"target_controller_token_subtype":"Inkling","target_controller_token_toughness":1,"xmage_effect_classes":["DestroyTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarshAnnotation translated into ManaLoom runtime scope xmage_destroy_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reduce to memory', 'Reduce to Memory', '63c0c321068ea335ec5a8b0521bd5bd7', 'battle_rule_v1:06b3bdee931dc6aa31039a007a8de4a2', '{"battle_model_scope":"xmage_exile_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W","R"],"compensation_token_name":"Spirit Token","compensation_token_power":3,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Spirit","compensation_token_toughness":2,"destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W","R"],"target_controller_token_name":"Spirit Token","target_controller_token_power":3,"target_controller_token_subtype":"Spirit","target_controller_token_toughness":2,"xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReduceToMemory translated into ManaLoom runtime scope xmage_exile_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('secure the scene', 'Secure the Scene', '6c19e67ba34f48807ada1d3dcf4486fc', 'battle_rule_v1:3d1a7f1c13063a741de09f0e885ba1b6', '{"battle_model_scope":"xmage_exile_target_with_controller_creature_token_compensation_spell_v1","compensation_creature_tokens":1,"compensation_token_colors":["W"],"compensation_token_name":"Soldier Token","compensation_token_power":1,"compensation_token_status":"dynamic_creature_token_executor","compensation_token_subtype":"Soldier","compensation_token_toughness":1,"destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller_creature_tokens":1,"target_controller_token_colors":["W"],"target_controller_token_name":"Soldier Token","target_controller_token_power":1,"target_controller_token_subtype":"Soldier","target_controller_token_toughness":1,"xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SecureTheScene translated into ManaLoom runtime scope xmage_exile_target_with_controller_creature_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller creature-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
