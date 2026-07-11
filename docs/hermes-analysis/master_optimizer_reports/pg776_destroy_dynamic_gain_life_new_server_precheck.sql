WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('divine offering', 'Divine Offering', '0c067819a69c20217f9b19b711d92400', 'battle_rule_v1:384969d75fc0ceb3fc48e0fbadd1c0ca', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DivineOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('molder', 'Molder', '8d0f792325fcc149eaadf57e53ed1949', 'battle_rule_v1:ad6e9448ff14addb039ac653ac28c528', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"x_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"],"target_mana_value_source":"x_value"},"target_mana_value_exact_from_x":true,"target_mana_value_source":"x_value","xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Molder translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene offering', 'Serene Offering', '514db4af9246c82d3b8817c1feef0f51', 'battle_rule_v1:45d637ad04edc0bd7690d28ff510deab', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","controller_gain_life_source":"target_mana_value","controller_gains_life":0,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneOffering translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tidy conclusion', 'Tidy Conclusion', '2b0c7ef2b530e70f2069bc11f7860ce1', 'battle_rule_v1:9ac359aa50729b9baf3955aa613a4cce', '{"battle_model_scope":"xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1","battlefield_count_card_types":["artifact"],"battlefield_count_scope":"controller_battlefield","controller_gain_life_source":"battlefield_permanent_count","controller_gains_life":0,"destination":"graveyard","effect":"remove_creature","instant":true,"life_gain_per_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TidyConclusion translated into ManaLoom runtime scope xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
