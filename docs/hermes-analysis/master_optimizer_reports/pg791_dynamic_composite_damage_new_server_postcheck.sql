WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('focus fire', 'Focus Fire', 'dadac04a003dabbc0c02353de974b38e', 'battle_rule_v1:0a77c01b41e8b01edc7700293d29c782', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["spacecraft"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FocusFire translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hobbit''s sting', 'Hobbit''s Sting', 'c96fc623db953d300e37f66bcdd6e2a8', 'battle_rule_v1:4cc57a6a390ad2b30a79ce8a740c05ae', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["food"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HobbitsSting translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('road rage', 'Road Rage', 'ade79182ddf63f024acbdd66cb9dbf78', 'battle_rule_v1:7aafa4698684da859113cb2b62e71232', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["mount"]},{"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["vehicle"]}],"battlefield_count_composite_mode":"union","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":2,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoadRage translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash of light', 'Slash of Light', 'cf5f56d8ffa98e6d77f5cc73369073c3', 'battle_rule_v1:d458a10a448c0e3796f48d5e721a36b0', '{"amount":0,"battle_model_scope":"xmage_dynamic_count_damage_spell_v1","battlefield_count_components":[{"battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield"},{"battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["equipment"]}],"battlefield_count_composite_mode":"sum","damage":0,"damage_amount_source":"composite_battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"direct_damage","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashOfLight translated into ManaLoom runtime scope xmage_dynamic_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg791_dynamic_composite_damage_20260711_222405) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
