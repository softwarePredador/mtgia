BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg822_sage_gate_land_animation_new_serve_20260712_092035 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('sage of the maze')
   OR normalized_name LIKE 'sage of the maze // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('sage of the maze', 'Sage of the Maze', 'daad64346959bcce99bbacd2fe8b446b', 'battle_rule_v1:2fb3b8cb0466f30ea443828df0589bed', '{"_activated_rule_effects":[{"ability_kind":"activated","activate_only_as_sorcery":true,"activated_effect":"land_animation","activated_land_animation":true,"activation_requires_tap":true,"battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","effect":"land_animation","land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","target":"land","target_constraints":{"card_types":["land"],"controller":"self"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"SageOfTheMazeEffect"},{"ability_kind":"activated","activated_effect":"untap_source","activation_requires_tap_target":true,"activation_tap_cost":"untapped_controlled_gate","activation_tap_cost_controller":"self","activation_tap_cost_subtype":"Gate","battle_model_scope":"xmage_activated_tap_gate_untap_source_v1","effect":"untap_source","gate_tap_untap_source":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"UntapSourceEffect"}],"ability_kind":"mana_and_activated","activated_battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","activated_effect":"land_animation_and_gate_untap_source","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1","effect":"ramp_permanent","gate_tap_untap_source":true,"gate_tap_untap_source_cost_subtype":"Gate","is_mana_source":true,"land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Wizard","xmage_ability_classes":["ActivateAsSorceryActivatedAbility","HasteAbility","SimpleActivatedAbility","SimpleManaAbility"],"xmage_effect_classes":["AddManaInAnyCombinationEffect","BecomesCreatureTargetEffect","OneShotEffect","SageOfTheMazeEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfTheMaze translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('sage of the maze', 'Sage of the Maze', 'daad64346959bcce99bbacd2fe8b446b', 'battle_rule_v1:2fb3b8cb0466f30ea443828df0589bed', '{"_activated_rule_effects":[{"ability_kind":"activated","activate_only_as_sorcery":true,"activated_effect":"land_animation","activated_land_animation":true,"activation_requires_tap":true,"battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","effect":"land_animation","land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","target":"land","target_constraints":{"card_types":["land"],"controller":"self"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"SageOfTheMazeEffect"},{"ability_kind":"activated","activated_effect":"untap_source","activation_requires_tap_target":true,"activation_tap_cost":"untapped_controlled_gate","activation_tap_cost_controller":"self","activation_tap_cost_subtype":"Gate","battle_model_scope":"xmage_activated_tap_gate_untap_source_v1","effect":"untap_source","gate_tap_untap_source":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"UntapSourceEffect"}],"ability_kind":"mana_and_activated","activated_battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","activated_effect":"land_animation_and_gate_untap_source","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1","effect":"ramp_permanent","gate_tap_untap_source":true,"gate_tap_untap_source_cost_subtype":"Gate","is_mana_source":true,"land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Wizard","xmage_ability_classes":["ActivateAsSorceryActivatedAbility","HasteAbility","SimpleActivatedAbility","SimpleManaAbility"],"xmage_effect_classes":["AddManaInAnyCombinationEffect","BecomesCreatureTargetEffect","OneShotEffect","SageOfTheMazeEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfTheMaze translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('sage of the maze', 'Sage of the Maze', 'daad64346959bcce99bbacd2fe8b446b', 'battle_rule_v1:2fb3b8cb0466f30ea443828df0589bed', '{"_activated_rule_effects":[{"ability_kind":"activated","activate_only_as_sorcery":true,"activated_effect":"land_animation","activated_land_animation":true,"activation_requires_tap":true,"battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","effect":"land_animation","land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","target":"land","target_constraints":{"card_types":["land"],"controller":"self"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"SageOfTheMazeEffect"},{"ability_kind":"activated","activated_effect":"untap_source","activation_requires_tap_target":true,"activation_tap_cost":"untapped_controlled_gate","activation_tap_cost_controller":"self","activation_tap_cost_subtype":"Gate","battle_model_scope":"xmage_activated_tap_gate_untap_source_v1","effect":"untap_source","gate_tap_untap_source":true,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"UntapSourceEffect"}],"ability_kind":"mana_and_activated","activated_battle_model_scope":"xmage_activated_land_becomes_creature_gate_count_v1","activated_effect":"land_animation_and_gate_untap_source","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1","effect":"ramp_permanent","gate_tap_untap_source":true,"gate_tap_untap_source_cost_subtype":"Gate","is_mana_source":true,"land_animation_count_subtype":"Gate","land_animation_duration":"until_end_of_turn","land_animation_granted_keywords":["haste"],"land_animation_multiplier":2,"land_animation_power_toughness_source":"controlled_subtype_count_times","land_animation_subtype":"Citizen","mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{2}{G}","source_type_line":"Creature \u2014 Elf Wizard","xmage_ability_classes":["ActivateAsSorceryActivatedAbility","HasteAbility","SimpleActivatedAbility","SimpleManaAbility"],"xmage_effect_classes":["AddManaInAnyCombinationEffect","BecomesCreatureTargetEffect","OneShotEffect","SageOfTheMazeEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SageOfTheMaze translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
