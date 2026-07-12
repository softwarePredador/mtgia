BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg820_heraldic_banner_chosen_color_stati_20260712_084027 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('heraldic banner')
   OR normalized_name LIKE 'heraldic banner // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('heraldic banner', 'Heraldic Banner', 'ed7379514aeb8e44fccbd2964c6fedda', 'battle_rule_v1:c47ed426b45962ec47c53926d1a6c9e3', '{"_composite_rule_components":[{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_power_bonus":1,"static_required_chosen_color":true,"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":"chosen_color","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"HeraldicBannerEffect"}],"ability_kind":"activated_mana_and_static","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_static_boost","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","SimpleStaticAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","HeraldicBannerEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeraldicBanner translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('heraldic banner', 'Heraldic Banner', 'ed7379514aeb8e44fccbd2964c6fedda', 'battle_rule_v1:c47ed426b45962ec47c53926d1a6c9e3', '{"_composite_rule_components":[{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_power_bonus":1,"static_required_chosen_color":true,"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":"chosen_color","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"HeraldicBannerEffect"}],"ability_kind":"activated_mana_and_static","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_static_boost","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","SimpleStaticAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","HeraldicBannerEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeraldicBanner translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('heraldic banner', 'Heraldic Banner', 'ed7379514aeb8e44fccbd2964c6fedda', 'battle_rule_v1:c47ed426b45962ec47c53926d1a6c9e3', '{"_composite_rule_components":[{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_power_bonus":1,"static_required_chosen_color":true,"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":"chosen_color","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"HeraldicBannerEffect"}],"ability_kind":"activated_mana_and_static","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","chosen_color_mana":true,"conditional_mana_modes":[{"color":"W","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"U","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"B","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"R","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"},{"color":"G","mode":"chosen_color_mana","restriction":"any_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","conditional_mana_same_color_choice":true,"effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_and_chosen_color_static_boost","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AsEntersBattlefieldAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":["AsEntersBattlefieldAbility","SimpleStaticAbility"],"xmage_effect_classes":["AddManaChosenColorEffect","ChooseColorEffect","HeraldicBannerEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HeraldicBanner translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
