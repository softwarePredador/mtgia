WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('anguished unmaking', 'Anguished Unmaking', 'f8337b2095f501b70402522ca5e4e826', 'battle_rule_v1:fcc2a24633a343991810834bfe8eda4e', '{"battle_model_scope":"xmage_exile_target_and_source_controller_loses_life_spell_v1","destination":"exile","effect":"remove_permanent","instant":true,"life_loss_amount":3,"resolution_order":"exile_then_source_controller_life_loss","sorcery":false,"source_controller_life_loss_on_resolve":3,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"xmage_effect_classes":["ExileTargetEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnguishedUnmaking translated into ManaLoom runtime scope xmage_exile_target_and_source_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ashes to ashes', 'Ashes to Ashes', 'ceee93d2db429607864eb158fd05e262', 'battle_rule_v1:eb1c4920b925fbc798cd7ff27f81044a', '{"battle_model_scope":"xmage_exile_target_and_source_controller_damage_spell_v1","damage_amount":5,"destination":"exile","effect":"remove_creature","instant":false,"max_targets":2,"resolution_order":"exile_then_source_controller_damage","sorcery":true,"source_controller_damage_on_resolve":5,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_classes":["ExileTargetEffect","DamageControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshesToAshes translated into ManaLoom runtime scope xmage_exile_target_and_source_controller_damage_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dramatic rescue', 'Dramatic Rescue', '248722f844d2fe3e9651ac1a54cb3964', 'battle_rule_v1:639e745e58a3fb223aa690a3384f1c27', '{"battle_model_scope":"xmage_return_target_to_hand_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"hand","effect":"remove_creature","instant":true,"resolution_order":"bounce_then_controller_gain_life","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_effect_classes":["ReturnToHandTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DramaticRescue translated into ManaLoom runtime scope xmage_return_target_to_hand_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('last breath', 'Last Breath', '12b3ca987db5253248782557446116db', 'battle_rule_v1:702e1e27e3c977d2019a78bb4fc45df6', '{"battle_model_scope":"xmage_exile_target_and_target_controller_gain_life_spell_v1","destination":"exile","effect":"remove_creature","instant":true,"resolution_order":"exile_then_target_controller_gain_life","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_max":2},"target_controller_gains_life":4,"xmage_effect_classes":["ExileTargetEffect","GainLifeTargetControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LastBreath translated into ManaLoom runtime scope xmage_exile_target_and_target_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('narrow escape', 'Narrow Escape', 'cd032665c315117d90c67cc22a7ca7e9', 'battle_rule_v1:c8158bba2c1e5140d61fdecf1af5c741', '{"battle_model_scope":"xmage_return_target_to_hand_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"hand","effect":"remove_permanent","instant":true,"resolution_order":"bounce_then_controller_gain_life","sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self"},"target_controller":"self","xmage_effect_classes":["ReturnToHandTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NarrowEscape translated into ManaLoom runtime scope xmage_return_target_to_hand_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vapor snag', 'Vapor Snag', '805e609aa1a2a0607491c9a23a694c51', 'battle_rule_v1:23989393015122c4bfb231da3c3bb5b4', '{"battle_model_scope":"xmage_return_target_to_hand_and_target_controller_loses_life_spell_v1","destination":"hand","effect":"remove_creature","instant":true,"life_loss_amount":1,"resolution_order":"bounce_then_target_controller_life_loss","sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_controller_life_loss_on_resolve":1,"xmage_effect_classes":["ReturnToHandTargetEffect","LoseLifeTargetControllerEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VaporSnag translated into ManaLoom runtime scope xmage_return_target_to_hand_and_target_controller_loses_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
