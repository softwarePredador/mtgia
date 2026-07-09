WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aftershock', 'Aftershock', '35dc73d5a88dc039ddcdffb53181b083', 'battle_rule_v1:100b2701ae685f36978dbaffd5908ee2', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_damage_spell_v1","damage_amount":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"resolution_order":"destroy_then_source_controller_damage","sorcery":true,"source_controller_damage_on_resolve":3,"target":"artifact_creature_or_land","target_constraints":{"card_types":["artifact","creature","land"]},"xmage_effect_classes":["DestroyTargetEffect","DamageControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_creature_or_land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Aftershock translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal grasp', 'Infernal Grasp', '3b76619b3ecdbafc14a3015ca3a3073b', 'battle_rule_v1:d6d2ea2bf2839c48250d4142a00650a0', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalGrasp translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reckless spite', 'Reckless Spite', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:16f50903bd0ea73d9170b60af44385d3', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RecklessSpite translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wicked pact', 'Wicked Pact', '43173fa6435217d9661e1161452a4bf5', 'battle_rule_v1:4d5b1d988662baacaa8acd4146e95b43', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"life_loss_amount":5,"max_targets":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":true,"source_controller_life_loss_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WickedPact translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('withering torment', 'Withering Torment', 'd52f19b218bf50ac4ab71edd91ddc0b0', 'battle_rule_v1:41e281910727fb998934ffbfadeb8883', '{"battle_model_scope":"xmage_destroy_target_and_source_controller_loses_life_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"life_loss_amount":2,"resolution_order":"destroy_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":2,"target":"creature_or_enchantment","target_constraints":{"card_types":["creature","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitheringTorment translated into ManaLoom runtime scope xmage_destroy_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
