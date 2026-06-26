BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg234_lorehold_ready_batch_four_20260626_082257 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('galvanoth', 'velomachus lorehold', 'palantír of orthanc', 'scholar of new horizons')
   OR normalized_name LIKE 'galvanoth // %'
   OR normalized_name LIKE 'velomachus lorehold // %'
   OR normalized_name LIKE 'palantír of orthanc // %'
   OR normalized_name LIKE 'scholar of new horizons // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('galvanoth', 'Galvanoth', '7ed46e6390c4eeb8ec436a9871abcdaa', 'battle_rule_v1:b8859191e53dd38d3af9f4d8db421a83', '{"ability_kind":"triggered","battle_model_scope":"controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1","effect":"creature","power":3,"toughness":3,"trigger":"controller_upkeep","trigger_effect":"look_top_card_may_cast_if_instant_or_sorcery","upkeep_look_top_card":true,"upkeep_may_cast_top_instant_or_sorcery_without_paying_mana":true,"upkeep_top_library_cast_types":["instant","sorcery"]}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Galvanoth mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('velomachus lorehold', 'Velomachus Lorehold', 'ecd723e730ac3b2cf1f68c816a17c745', 'battle_rule_v1:c3e60ccbaf1d57109e270f072d834a98', '{"ability_kind":"triggered","attack_cast_mana_value_max_source":"source_power","attack_look_top_count":7,"attack_may_cast_from_looked_cards_without_paying_mana":true,"attack_put_rest_bottom_random":true,"attack_top_library_cast_types":["instant","sorcery"],"battle_model_scope":"attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1","effect":"creature","flying":true,"haste":true,"power":5,"toughness":5,"trigger":"attack","trigger_effect":"look_top_seven_may_cast_instant_or_sorcery_lte_power","vigilance":true}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VelomachusLorehold mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('palantír of orthanc', 'Palantír of Orthanc', 'a85ec353e0a18e783ae88be2f64536ec', 'battle_rule_v1:26179de4259137dba13dc5d473b1fe72', '{"ability_kind":"triggered","battle_model_scope":"controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1","decline_mill_count_source":"source_named_counter_count","decline_mill_counter_type":"influence","decline_opponent_life_loss_equals_milled_cards_total_mana_value":true,"effect":"draw_engine","target":"opponent","target_opponent_may_have_you_draw_count":1,"trigger":"controller_end_step","trigger_counter_count":1,"trigger_counter_type":"influence","trigger_effect":"add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss","trigger_scry_count":2}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PalantirOfOrthanc mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('scholar of new horizons', 'Scholar of New Horizons', '4f089ec5603d5179130aee6db95a54bf', 'battle_rule_v1:eeb6d5d36cf100b1f4136ec0b5f5d63d', '{"ability_kind":"activated","activation_cost_generic":0,"activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands":true,"activation_requires_remove_plus_one_counter_from_controlled_permanent":true,"activation_requires_tap":true,"battle_model_scope":"activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1","effect":"creature","enters_with_plus_one_counter_count":1,"land_tutor_to_hand_activated":true,"power":1,"toughness":1,"tutor_destination":"hand","tutor_target":"plains"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScholarOfNewHorizons mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('galvanoth', 'Galvanoth', '7ed46e6390c4eeb8ec436a9871abcdaa', 'battle_rule_v1:b8859191e53dd38d3af9f4d8db421a83', '{"ability_kind":"triggered","battle_model_scope":"controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1","effect":"creature","power":3,"toughness":3,"trigger":"controller_upkeep","trigger_effect":"look_top_card_may_cast_if_instant_or_sorcery","upkeep_look_top_card":true,"upkeep_may_cast_top_instant_or_sorcery_without_paying_mana":true,"upkeep_top_library_cast_types":["instant","sorcery"]}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Galvanoth mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('velomachus lorehold', 'Velomachus Lorehold', 'ecd723e730ac3b2cf1f68c816a17c745', 'battle_rule_v1:c3e60ccbaf1d57109e270f072d834a98', '{"ability_kind":"triggered","attack_cast_mana_value_max_source":"source_power","attack_look_top_count":7,"attack_may_cast_from_looked_cards_without_paying_mana":true,"attack_put_rest_bottom_random":true,"attack_top_library_cast_types":["instant","sorcery"],"battle_model_scope":"attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1","effect":"creature","flying":true,"haste":true,"power":5,"toughness":5,"trigger":"attack","trigger_effect":"look_top_seven_may_cast_instant_or_sorcery_lte_power","vigilance":true}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VelomachusLorehold mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('palantír of orthanc', 'Palantír of Orthanc', 'a85ec353e0a18e783ae88be2f64536ec', 'battle_rule_v1:26179de4259137dba13dc5d473b1fe72', '{"ability_kind":"triggered","battle_model_scope":"controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1","decline_mill_count_source":"source_named_counter_count","decline_mill_counter_type":"influence","decline_opponent_life_loss_equals_milled_cards_total_mana_value":true,"effect":"draw_engine","target":"opponent","target_opponent_may_have_you_draw_count":1,"trigger":"controller_end_step","trigger_counter_count":1,"trigger_counter_type":"influence","trigger_effect":"add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss","trigger_scry_count":2}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PalantirOfOrthanc mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('scholar of new horizons', 'Scholar of New Horizons', '4f089ec5603d5179130aee6db95a54bf', 'battle_rule_v1:eeb6d5d36cf100b1f4136ec0b5f5d63d', '{"ability_kind":"activated","activation_cost_generic":0,"activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands":true,"activation_requires_remove_plus_one_counter_from_controlled_permanent":true,"activation_requires_tap":true,"battle_model_scope":"activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1","effect":"creature","enters_with_plus_one_counter_count":1,"land_tutor_to_hand_activated":true,"power":1,"toughness":1,"tutor_destination":"hand","tutor_target":"plains"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScholarOfNewHorizons mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
    ('galvanoth', 'Galvanoth', '7ed46e6390c4eeb8ec436a9871abcdaa', 'battle_rule_v1:b8859191e53dd38d3af9f4d8db421a83', '{"ability_kind":"triggered","battle_model_scope":"controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1","effect":"creature","power":3,"toughness":3,"trigger":"controller_upkeep","trigger_effect":"look_top_card_may_cast_if_instant_or_sorcery","upkeep_look_top_card":true,"upkeep_may_cast_top_instant_or_sorcery_without_paying_mana":true,"upkeep_top_library_cast_types":["instant","sorcery"]}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Galvanoth mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('velomachus lorehold', 'Velomachus Lorehold', 'ecd723e730ac3b2cf1f68c816a17c745', 'battle_rule_v1:c3e60ccbaf1d57109e270f072d834a98', '{"ability_kind":"triggered","attack_cast_mana_value_max_source":"source_power","attack_look_top_count":7,"attack_may_cast_from_looked_cards_without_paying_mana":true,"attack_put_rest_bottom_random":true,"attack_top_library_cast_types":["instant","sorcery"],"battle_model_scope":"attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1","effect":"creature","flying":true,"haste":true,"power":5,"toughness":5,"trigger":"attack","trigger_effect":"look_top_seven_may_cast_instant_or_sorcery_lte_power","vigilance":true}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VelomachusLorehold mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('palantír of orthanc', 'Palantír of Orthanc', 'a85ec353e0a18e783ae88be2f64536ec', 'battle_rule_v1:26179de4259137dba13dc5d473b1fe72', '{"ability_kind":"triggered","battle_model_scope":"controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1","decline_mill_count_source":"source_named_counter_count","decline_mill_counter_type":"influence","decline_opponent_life_loss_equals_milled_cards_total_mana_value":true,"effect":"draw_engine","target":"opponent","target_opponent_may_have_you_draw_count":1,"trigger":"controller_end_step","trigger_counter_count":1,"trigger_counter_type":"influence","trigger_effect":"add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss","trigger_scry_count":2}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PalantirOfOrthanc mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('scholar of new horizons', 'Scholar of New Horizons', '4f089ec5603d5179130aee6db95a54bf', 'battle_rule_v1:eeb6d5d36cf100b1f4136ec0b5f5d63d', '{"ability_kind":"activated","activation_cost_generic":0,"activation_put_tutored_land_onto_battlefield_tapped_if_opponent_more_lands":true,"activation_requires_remove_plus_one_counter_from_controlled_permanent":true,"activation_requires_tap":true,"battle_model_scope":"activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1","effect":"creature","enters_with_plus_one_counter_count":1,"land_tutor_to_hand_activated":true,"power":1,"toughness":1,"tutor_destination":"hand","tutor_target":"plains"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScholarOfNewHorizons mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
