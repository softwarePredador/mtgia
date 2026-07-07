WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aerial volley', 'Aerial Volley', '00609b4fb1c5ac75b66f8573ebf8e43d', 'battle_rule_v1:8c3af016c2a83571c684414e12f6ba8f', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":3,"sorcery":false,"target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"flying_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AerialVolley translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('arc lightning', 'Arc Lightning', '74204b1dabfd1c5919ff3fd2f0744f71', 'battle_rule_v1:f2c5e312fa1842f2baf7ae6283fe5313', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":3,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArcLightning translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('boulderfall', 'Boulderfall', '41d7708efeb4a68047e6ee18b9273336', 'battle_rule_v1:5e9ebeeda9437feb0ac9a01d61ae3a3b', '{"ability_kind":"one_shot","amount":5,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":5,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":5,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":5,"target_count_max":5,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Boulderfall translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chandra''s pyrohelix', 'Chandra''s Pyrohelix', '1ba0332667f38202bea076b467d2c71a', 'battle_rule_v1:39027367cdd1f0f585b9d0f240d3a039', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":2,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChandrasPyrohelix translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deft dismissal', 'Deft Dismissal', '18576ea60d74ab1ed1c5c2ffb1272372', 'battle_rule_v1:4bdf19bcd2790da7cb3d56a14be59ea3', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":3,"sorcery":false,"target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeftDismissal translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire at will', 'Fire at Will', '8646a4a7ed02c0d2cd6f6ff343ec1a11', 'battle_rule_v1:4bdf19bcd2790da7cb3d56a14be59ea3', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":3,"sorcery":false,"target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireAtWill translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flames of the firebrand', 'Flames of the Firebrand', 'a9e2e1aa166282dc86b7279ff3da02f3', 'battle_rule_v1:f2c5e312fa1842f2baf7ae6283fe5313', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":3,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamesOfTheFirebrand translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forked bolt', 'Forked Bolt', '52abe6d8587fe0540e6df205a9bff961', 'battle_rule_v1:70d511bda849f87dc14022fdd9c1d3cc', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":2,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForkedBolt translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forked lightning', 'Forked Lightning', '0a28e75daca9fdef081f1fd949da8aa5', 'battle_rule_v1:04a2875b32e0ede63cdf997841853f38', '{"ability_kind":"one_shot","amount":4,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":4,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":3,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForkedLightning translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ignite disorder', 'Ignite Disorder', '62b8a9bea0d1331e23b20b0278ddbe85', 'battle_rule_v1:9eb46af2f059e444167117db8701ca0b', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":3,"sorcery":false,"target":"white_or_blue_creature","target_constraints":{"card_types":["creature"],"target_colors":["W","U"]},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"white_or_blue_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IgniteDisorder translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magic missile', 'Magic Missile', '6f6aa371529551318248e64805ef22ff', 'battle_rule_v1:f2c5e312fa1842f2baf7ae6283fe5313', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":3,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":3,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":3,"target_count_max":3,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagicMissile translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyrotechnics', 'Pyrotechnics', '848c99c225e90a5f56ff353cbfc0c94b', 'battle_rule_v1:9d6e4255475c9b2528d2db4de3a11552', '{"ability_kind":"one_shot","amount":4,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":4,"divided_damage":true,"effect":"multi_target_damage","instant":false,"max_targets":4,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":4,"target_count_max":4,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Pyrotechnics translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roil''s retribution', 'Roil''s Retribution', 'cd25ab62a52fc0244dd6142f49161fc2', 'battle_rule_v1:08cd518f4a35b21a9a199668f1a8840d', '{"ability_kind":"one_shot","amount":5,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":5,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":5,"sorcery":false,"target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"target_count":5,"target_count_max":5,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoilsRetribution translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spreading flames', 'Spreading Flames', '1075550ab89dbc75776e18619545a0ee', 'battle_rule_v1:0858be9b7e3ddcf7f58281af8926b485', '{"ability_kind":"one_shot","amount":6,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":6,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":6,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":6,"target_count_max":6,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpreadingFlames translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('twin bolt', 'Twin Bolt', '1dbae0c5025714853d78e2fbee68418e', 'battle_rule_v1:39027367cdd1f0f585b9d0f240d3a039', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_multi_target_damage_spell_v1","damage":2,"divided_damage":true,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageMultiEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TwinBolt translated into ManaLoom runtime scope xmage_fixed_multi_target_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
