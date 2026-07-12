BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg836_artifact_compensation_new_server_20260712_181626 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('buy your silence', 'zuko''s exile')
   OR normalized_name LIKE 'buy your silence // %'
   OR normalized_name LIKE 'zuko''s exile // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('buy your silence', 'Buy Your Silence', '7272d5d266f6ff4669834b8de560e162', 'battle_rule_v1:6bc3d9f3ccc4395630d6c135f4f88397', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"any_color_mana_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":true,"compensation_token_artifact_only":true,"compensation_token_class":"TreasureToken","compensation_token_is_mana_source":true,"compensation_token_mana_activation_requires_sacrifice":true,"compensation_token_mana_activation_requires_tap":true,"compensation_token_mana_produced":1,"compensation_token_mana_source_contextual_only":false,"compensation_token_name":"Treasure Token","compensation_token_produced_mana_symbols":["W","U","B","R","G"],"compensation_token_produces":"any_color","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Treasure","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"any_color_mana_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":true,"target_controller_token_artifact_only":true,"target_controller_token_class":"TreasureToken","target_controller_token_is_mana_source":true,"target_controller_token_mana_activation_requires_sacrifice":true,"target_controller_token_mana_activation_requires_tap":true,"target_controller_token_mana_produced":1,"target_controller_token_mana_source_contextual_only":false,"target_controller_token_name":"Treasure Token","target_controller_token_produced_mana_symbols":["W","U","B","R","G"],"target_controller_token_produces":"any_color","target_controller_token_subtype":"Treasure","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuyYourSilence translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('zuko''s exile', 'Zuko''s Exile', 'ad108129d0f384a98ba01e0688447cf5', 'battle_rule_v1:bedf1ce0a21ccd23ffbfc6623b0da8fe', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"draw_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","compensation_token_activated_draw_on_self_sacrifice":true,"compensation_token_activated_self_sacrifice_draw":true,"compensation_token_activation_cost_generic":2,"compensation_token_activation_cost_mana":"{2}","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":false,"compensation_token_artifact_only":true,"compensation_token_class":"ClueArtifactToken","compensation_token_draw_count":1,"compensation_token_draw_on_self_sacrifice":1,"compensation_token_name":"Clue Token","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Clue","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"draw_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","target_controller_token_activated_draw_on_self_sacrifice":true,"target_controller_token_activated_self_sacrifice_draw":true,"target_controller_token_activation_cost_generic":2,"target_controller_token_activation_cost_mana":"{2}","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":false,"target_controller_token_artifact_only":true,"target_controller_token_class":"ClueArtifactToken","target_controller_token_draw_count":1,"target_controller_token_draw_on_self_sacrifice":1,"target_controller_token_name":"Clue Token","target_controller_token_subtype":"Clue","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ZukosExile translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('buy your silence', 'Buy Your Silence', '7272d5d266f6ff4669834b8de560e162', 'battle_rule_v1:6bc3d9f3ccc4395630d6c135f4f88397', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"any_color_mana_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":true,"compensation_token_artifact_only":true,"compensation_token_class":"TreasureToken","compensation_token_is_mana_source":true,"compensation_token_mana_activation_requires_sacrifice":true,"compensation_token_mana_activation_requires_tap":true,"compensation_token_mana_produced":1,"compensation_token_mana_source_contextual_only":false,"compensation_token_name":"Treasure Token","compensation_token_produced_mana_symbols":["W","U","B","R","G"],"compensation_token_produces":"any_color","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Treasure","destination":"exile","effect":"remove_permanent","instant":false,"sorcery":true,"target":"nonland_permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["land"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"any_color_mana_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":true,"target_controller_token_artifact_only":true,"target_controller_token_class":"TreasureToken","target_controller_token_is_mana_source":true,"target_controller_token_mana_activation_requires_sacrifice":true,"target_controller_token_mana_activation_requires_tap":true,"target_controller_token_mana_produced":1,"target_controller_token_mana_source_contextual_only":false,"target_controller_token_name":"Treasure Token","target_controller_token_produced_mana_symbols":["W","U","B","R","G"],"target_controller_token_produces":"any_color","target_controller_token_subtype":"Treasure","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"nonland_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuyYourSilence translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('zuko''s exile', 'Zuko''s Exile', 'ad108129d0f384a98ba01e0688447cf5', 'battle_rule_v1:bedf1ce0a21ccd23ffbfc6623b0da8fe', '{"battle_model_scope":"xmage_exile_target_with_controller_artifact_token_compensation_spell_v1","compensation_artifact_only_tokens":1,"compensation_artifact_tokens":true,"compensation_token_activated_ability":"draw_self_sacrifice","compensation_token_activated_ability_status":"runtime_supported","compensation_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","compensation_token_activated_draw_on_self_sacrifice":true,"compensation_token_activated_self_sacrifice_draw":true,"compensation_token_activation_cost_generic":2,"compensation_token_activation_cost_mana":"{2}","compensation_token_activation_requires_sacrifice":true,"compensation_token_activation_requires_tap":false,"compensation_token_artifact_only":true,"compensation_token_class":"ClueArtifactToken","compensation_token_draw_count":1,"compensation_token_draw_on_self_sacrifice":1,"compensation_token_name":"Clue Token","compensation_token_status":"dynamic_artifact_token_executor","compensation_token_subtype":"Clue","destination":"exile","effect":"remove_permanent","instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment"]},"target_controller_artifact_only_tokens":1,"target_controller_artifact_tokens":true,"target_controller_token_activated_ability":"draw_self_sacrifice","target_controller_token_activated_ability_status":"runtime_supported","target_controller_token_activated_battle_model_scope":"xmage_permanent_simple_activated_draw_v1","target_controller_token_activated_draw_on_self_sacrifice":true,"target_controller_token_activated_self_sacrifice_draw":true,"target_controller_token_activation_cost_generic":2,"target_controller_token_activation_cost_mana":"{2}","target_controller_token_activation_requires_sacrifice":true,"target_controller_token_activation_requires_tap":false,"target_controller_token_artifact_only":true,"target_controller_token_class":"ClueArtifactToken","target_controller_token_draw_count":1,"target_controller_token_draw_on_self_sacrifice":1,"target_controller_token_name":"Clue Token","target_controller_token_subtype":"Clue","xmage_effect_classes":["ExileTargetEffect","CreateTokenControllerTargetEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ZukosExile translated into ManaLoom runtime scope xmage_exile_target_with_controller_artifact_token_compensation_spell_v1. This row is package-ready only because the source signature is a narrow fixed exile-target spell with target-controller artifact-token compensation with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
