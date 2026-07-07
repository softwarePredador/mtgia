WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bounce off', 'Bounce Off', '4697e48be0d012476635626b59ff686b', 'battle_rule_v1:f2e24de1c6d45066dbda2109912a63e2', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"creature_or_vehicle","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]}]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_vehicle","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BounceOff translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cut the earthly bond', 'Cut the Earthly Bond', '160612165db10cbd4158a1c24ceaa263', 'battle_rule_v1:f722ea9825e629e4690dabad8ea3536d', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchanted_permanent","target_constraints":{"card_types":["permanent"],"enchanted":true},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchanted_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CutTheEarthlyBond translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('depart the realm', 'Depart the Realm', '6183c0a6f7e8710981aeb09c5c2fdee4', 'battle_rule_v1:001a1215317195fb0dd53f88c849c54c', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DepartTheRealm translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hoodwink', 'Hoodwink', '89d3f25fb5311c47d4d3c11cc326914a', 'battle_rule_v1:09b2438b59221a455f58e7c7e8db8a22', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment_or_land","target_constraints":{"card_types":["artifact","enchantment","land"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment_or_land","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hoodwink translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('into thin air', 'Into Thin Air', '223da72bf51053d6b0f5dc8845673134', 'battle_rule_v1:1ced64c4f5a32cab3c82e97ad1f7bfad', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IntoThinAir translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wipe away', 'Wipe Away', '707e43acd81856daca2162b5de8dc02a', 'battle_rule_v1:2048333401c1ae3096acb4d43a4c83db', '{"battle_model_scope":"xmage_return_target_to_hand_spell_v1","destination":"hand","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WipeAway translated into ManaLoom runtime scope xmage_return_target_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg591_bounce_target_variants_new_server_20260707_035542) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
