WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deconstruct', 'Deconstruct', '08f659e0e917ed1ddb367a9c86897b45', 'battle_rule_v1:3c02c24a2346797911c20945d2f1a9f0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deconstruct translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liturgy of blood', 'Liturgy of Blood', '793a1d6947010edec6e943eef9da9139', 'battle_rule_v1:7f91b8beaa5f42a0d97e520e388ab01a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LiturgyOfBlood translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seismic spike', 'Seismic Spike', '6ed975bb71da90e04ccbff411312aa15', 'battle_rule_v1:dd8dce7535424809092d8737ac86ce3f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeismicSpike translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn to dust', 'Turn to Dust', '32481b22834ca33b610c00906439c510', 'battle_rule_v1:f4a9e330eee70bed3982dcb7d586e238', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnToDust translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
