WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('fiery intervention', 'Fiery Intervention', '47787c728dae66ae04ff9ff992da2bd0', 'battle_rule_v1:1e991355b361b8abe50e7d5691deb28e', '{"battle_model_scope":"xmage_choose_one_damage_or_destroy_target_spell_v1","damage_amount":5,"damage_target":"creature","destroy_target":"artifact","effect":"modal_spell","instant":false,"modal_modes":[{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","mode":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","mode":"destroy_target","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}],"mode_max":1,"mode_min":1,"mode_selection":"choose_one","mode_selection_model":"best_available_mode","sorcery":true,"xmage_effect_classes":["DamageTargetEffect","DestroyTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"modal_spell"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FieryIntervention translated into ManaLoom runtime scope xmage_choose_one_damage_or_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molten blast', 'Molten Blast', '44816ac1adb1341cffead9049d6b033c', 'battle_rule_v1:e998291e1e60347aa41461c93b95f96c', '{"battle_model_scope":"xmage_choose_one_damage_or_destroy_target_spell_v1","damage_amount":2,"damage_target":"creature_or_planeswalker","destroy_target":"artifact","effect":"modal_spell","instant":true,"modal_modes":[{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":2,"effect":"direct_damage","mode":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","mode":"destroy_target","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}],"mode_max":1,"mode_min":1,"mode_selection":"choose_one","mode_selection_model":"best_available_mode","sorcery":false,"xmage_effect_classes":["DamageTargetEffect","DestroyTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"modal_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MoltenBlast translated into ManaLoom runtime scope xmage_choose_one_damage_or_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ready to rumble', 'Ready to Rumble', 'c7cb7c5eb0212ec928cd31fc246d9afb', 'battle_rule_v1:38e830b8075b9dba2a7cac8552482b1c', '{"battle_model_scope":"xmage_choose_one_damage_or_destroy_target_spell_v1","damage_amount":5,"damage_target":"creature_or_planeswalker","destroy_target":"artifact","effect":"modal_spell","instant":false,"modal_modes":[{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","mode":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","mode":"destroy_target","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}],"mode_max":1,"mode_min":1,"mode_selection":"choose_one","mode_selection_model":"best_available_mode","sorcery":true,"xmage_effect_classes":["DamageTargetEffect","DestroyTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"modal_spell"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReadyToRumble translated into ManaLoom runtime scope xmage_choose_one_damage_or_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rip apart', 'Rip Apart', '3d5fb02284dcccd2fedcd1a2b7699706', 'battle_rule_v1:073e0388dec40505ed458810a01163e2', '{"battle_model_scope":"xmage_choose_one_damage_or_destroy_target_spell_v1","damage_amount":3,"damage_target":"creature_or_planeswalker","destroy_target":"artifact_or_enchantment","effect":"modal_spell","instant":false,"modal_modes":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":3,"effect":"direct_damage","mode":"direct_damage","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","mode":"destroy_target","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"}],"mode_max":1,"mode_min":1,"mode_selection":"choose_one","mode_selection_model":"best_available_mode","sorcery":true,"xmage_effect_classes":["DamageTargetEffect","DestroyTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"modal_spell"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RipApart translated into ManaLoom runtime scope xmage_choose_one_damage_or_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('start from scratch', 'Start from Scratch', 'f6573945c4b7b6d57b25b00792e29b0b', 'battle_rule_v1:e205b3066f443fdc3dd7a440b13d9702', '{"battle_model_scope":"xmage_choose_one_damage_or_destroy_target_spell_v1","damage_amount":1,"damage_target":"any_target","destroy_target":"artifact","effect":"modal_spell","instant":false,"modal_modes":[{"amount":1,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":1,"effect":"direct_damage","mode":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","mode":"destroy_target","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}],"mode_max":1,"mode_min":1,"mode_selection":"choose_one","mode_selection_model":"best_available_mode","sorcery":true,"xmage_effect_classes":["DamageTargetEffect","DestroyTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"modal_spell"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StartFromScratch translated into ManaLoom runtime scope xmage_choose_one_damage_or_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
