WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bounce off', 'Bounce Off', '4697e48be0d012476635626b59ff686b', 'battle_rule_v1:f2e24de1c6d45066dbda2109912a63e2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_vehicle","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]}]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_vehicle","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BounceOff translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cut the earthly bond', 'Cut the Earthly Bond', '160612165db10cbd4158a1c24ceaa263', 'battle_rule_v1:f722ea9825e629e4690dabad8ea3536d', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchanted_permanent","target_constraints":{"card_types":["permanent"],"enchanted":true},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchanted_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CutTheEarthlyBond translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('depart the realm', 'Depart the Realm', '6183c0a6f7e8710981aeb09c5c2fdee4', 'battle_rule_v1:001a1215317195fb0dd53f88c849c54c', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DepartTheRealm translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hoodwink', 'Hoodwink', '89d3f25fb5311c47d4d3c11cc326914a', 'battle_rule_v1:09b2438b59221a455f58e7c7e8db8a22', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment_or_land","target_constraints":{"card_types":["artifact","enchantment","land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hoodwink translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into thin air', 'Into Thin Air', '223da72bf51053d6b0f5dc8845673134', 'battle_rule_v1:1ced64c4f5a32cab3c82e97ad1f7bfad', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoThinAir translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wipe away', 'Wipe Away', '707e43acd81856daca2162b5de8dc02a', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WipeAway translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
