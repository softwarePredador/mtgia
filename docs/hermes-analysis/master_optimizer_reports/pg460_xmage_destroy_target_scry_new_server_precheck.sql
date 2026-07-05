WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('artisan''s sorrow', 'Artisan''s Sorrow', 'da43fa4288fbb6986c6ddda5b21db6dd', 'battle_rule_v1:6e9e60bc9fb2ad5c293fdfd311a8c137', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArtisansSorrow translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expose to daylight', 'Expose to Daylight', '3646dffbed1ee5903335e38f180bdd10', 'battle_rule_v1:e27b12d525b32a09c3664f43b350acc4', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExposeToDaylight translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('get the point', 'Get the Point', '9b713515e0ac5d3787f8022921214828', 'battle_rule_v1:60186100f5114fb616355fbbdbb91778', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GetThePoint translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guiding bolt', 'Guiding Bolt', '379be0891c7170a8b2c7e92b0c961cc8', 'battle_rule_v1:7339a89b2ca7be6d9b801f0fbf7123dc', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuidingBolt translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubble reading', 'Rubble Reading', 'ed6c32c050392475b0ad695de29d1e80', 'battle_rule_v1:3d1fa3cc048c47b80f9e4ebc21b72931', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubbleReading translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skywhaler''s shot', 'Skywhaler''s Shot', 'b72b7bfe543e290d2e6fd90b617727a3', 'battle_rule_v1:cf50ba8ae8f3f26d42593ffd7c919fa7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkywhalersShot translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad justice', 'Tel-Jilad Justice', '771f081071e5dbd2213233334c6a2874', 'battle_rule_v1:549bbd1831243bf6128b853515d740c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladJustice translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanquish the foul', 'Vanquish the Foul', 'cde9a7f047448ac2ff5c48179b6cbb80', 'battle_rule_v1:c7411f0db013697c3ba279504bd4dff2', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanquishTheFoul translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
