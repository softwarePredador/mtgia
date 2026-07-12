WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('buy your silence', 'Buy Your Silence', '7272d5d266f6ff4669834b8de560e162', 'battle_rule_v1:6bc3d9f3ccc4395630d6c135f4f88397', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"any_color_mana_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":true,"compensation_token_artifact_only":true,"compensation_token_class":"TreasureToken","compensation_token_is_mana_source":true,"compensation_token_mana_activation_requires_sacrifice":true,"compensation_token_mana_activation_requires_tap":true,"compensation_token_mana_produced":1,"compensation_token_mana_source_contextual_only":false,"compensation_token_name":"Treasure Token","compensation_token_produced_mana_symbols":["W","U","B","R","G"],"compensation_token_produces":"any_color","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Treasure","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"any_color_mana_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":true,"target_controller_token_artifact_only":true,"target_controller_token_class":"TreasureToken","target_controller_token_is_mana_source":true,"target_controller_token_mana_activation_requires_sacrifice":true,"target_controller_token_mana_activation_requires_tap":true,"target_controller_token_mana_produced":1,"target_controller_token_mana_source_contextual_only":false,"target_controller_token_name":"Treasure Token","target_controller_token_produced_mana_symbols":["W","U","B","R","G"],"target_controller_token_produces":"any_color","target_controller_token_subtype":"Treasure","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuyYourSilence translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('zuko''s exile', 'Zuko''s Exile', 'ad108129d0f384a98ba01e0688447cf5', 'battle_rule_v1:bedf1ce0a21ccd23ffbfc6623b0da8fe', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"draw_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","compensation_token_activated_draw_on_self_sacrifice":true,"compensation_token_activated_self_sacrifice_draw":true,"compensation_token_activation_cost_generic":2,"compensation_token_activation_cost_mana":"{2}","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":false,"compensation_token_artifact_only":true,"compensation_token_class":"ClueArtifactToken","compensation_token_draw_count":1,"compensation_token_draw_on_self_sacrifice":1,"compensation_token_name":"Clue Token","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Clue","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"draw_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","target_controller_token_activated_draw_on_self_sacrifice":true,"target_controller_token_activated_self_sacrifice_draw":true,"target_controller_token_activation_cost_generic":2,"target_controller_token_activation_cost_mana":"{2}","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":false,"target_controller_token_artifact_only":true,"target_controller_token_class":"ClueArtifactToken","target_controller_token_draw_count":1,"target_controller_token_draw_on_self_sacrifice":1,"target_controller_token_name":"Clue Token","target_controller_token_subtype":"Clue","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ZukosExile translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
