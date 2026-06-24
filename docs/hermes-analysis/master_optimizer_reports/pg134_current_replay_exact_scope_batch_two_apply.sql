BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg134_current_replay_exact_scope_batch_two_20260624_0113 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('archdruid''s charm', 'sink into stupor', 'ruthless technomancer', 'emperor of bones', 'disciple of freyalise', 'vibrance');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('archdruid''s charm', 'Archdruid''s Charm', 'c4df44104e459fecc46e4cb91708c4cd', 'battle_rule_v1:8737c73f1ba15aa4c12ddd7ed2fe2864', '{"ability_kind":"one_shot","battle_model_scope":"search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1","effect":"modal_spell","instant":true,"mode_exile_target_artifact_or_enchantment":true,"mode_put_plus_one_counter_on_controlled_creature_then_fight":true,"mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ArchdruidsCharm mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sink into stupor', 'Sink into Stupor', 'aa830204ff7fdbc43fd5b4b84b30ede1', 'battle_rule_v1:4055b69675e84cc871d1b5d1268ac119', '{"ability_kind":"one_shot","battle_model_scope":"return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1","effect":"bounce","instant":true,"land_side_add_mana":"U","land_side_pay_three_life_else_tapped":true,"target":"spell_or_opponent_nonland_permanent"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SinkIntoStupor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('ruthless technomancer', 'Ruthless Technomancer', '0723f53d95b32cfc0e68da4f2fb9552e', 'battle_rule_v1:90563f719a1a22cb76142cf78207bc25', '{"ability_kind":"triggered","activated_cost":"{2}{B}","activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less":true,"battle_model_scope":"etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1","effect":"creature","etb_may_sacrifice_another_creature_create_treasures_equal_power":true,"power":2,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RuthlessTechnomancer mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('emperor of bones', 'Emperor of Bones', 'c38cbc86cb985c9ee97265b67e59bb42', 'battle_rule_v1:be03995844cb037cb44bce18d4f06bc4', '{"ability_kind":"triggered","adapt_cost":"{1}{B}","adapt_counters":2,"battle_model_scope":"combat_exile_adapt_finality_reanimate_v1","beginning_of_combat_exile_up_to_one_card_from_graveyard":true,"counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot":true,"effect":"creature","power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EmperorOfBones mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('disciple of freyalise', 'Disciple of Freyalise', '3fb90a15cdcaba88791217be1f8cdaff', 'battle_rule_v1:050c819a19a33f85e0bceaac645fa7ba', '{"ability_kind":"triggered","battle_model_scope":"etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1","effect":"creature","etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power":true,"land_side_add_mana":"G","land_side_pay_three_life_else_tapped":true,"power":3,"toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiscipleOfFreyalise mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vibrance', 'Vibrance', '9f9398d4a93c0733a5ac19a0c9e50dd3', 'battle_rule_v1:d6ec311db4082874f2ec217353e116b4', '{"ability_kind":"triggered","battle_model_scope":"evoke_etb_red_damage_or_green_land_tutor_lifegain_v1","effect":"creature","etb_if_green_green_spent_gain_life":2,"etb_if_green_green_spent_search_land_to_hand":true,"etb_if_red_red_spent_damage_any_target":3,"evoke_cost":"{R/G}{R/G}","power":4,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Vibrance mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('archdruid''s charm', 'Archdruid''s Charm', 'c4df44104e459fecc46e4cb91708c4cd', 'battle_rule_v1:8737c73f1ba15aa4c12ddd7ed2fe2864', '{"ability_kind":"one_shot","battle_model_scope":"search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1","effect":"modal_spell","instant":true,"mode_exile_target_artifact_or_enchantment":true,"mode_put_plus_one_counter_on_controlled_creature_then_fight":true,"mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ArchdruidsCharm mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sink into stupor', 'Sink into Stupor', 'aa830204ff7fdbc43fd5b4b84b30ede1', 'battle_rule_v1:4055b69675e84cc871d1b5d1268ac119', '{"ability_kind":"one_shot","battle_model_scope":"return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1","effect":"bounce","instant":true,"land_side_add_mana":"U","land_side_pay_three_life_else_tapped":true,"target":"spell_or_opponent_nonland_permanent"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SinkIntoStupor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('ruthless technomancer', 'Ruthless Technomancer', '0723f53d95b32cfc0e68da4f2fb9552e', 'battle_rule_v1:90563f719a1a22cb76142cf78207bc25', '{"ability_kind":"triggered","activated_cost":"{2}{B}","activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less":true,"battle_model_scope":"etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1","effect":"creature","etb_may_sacrifice_another_creature_create_treasures_equal_power":true,"power":2,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RuthlessTechnomancer mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('emperor of bones', 'Emperor of Bones', 'c38cbc86cb985c9ee97265b67e59bb42', 'battle_rule_v1:be03995844cb037cb44bce18d4f06bc4', '{"ability_kind":"triggered","adapt_cost":"{1}{B}","adapt_counters":2,"battle_model_scope":"combat_exile_adapt_finality_reanimate_v1","beginning_of_combat_exile_up_to_one_card_from_graveyard":true,"counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot":true,"effect":"creature","power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EmperorOfBones mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('disciple of freyalise', 'Disciple of Freyalise', '3fb90a15cdcaba88791217be1f8cdaff', 'battle_rule_v1:050c819a19a33f85e0bceaac645fa7ba', '{"ability_kind":"triggered","battle_model_scope":"etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1","effect":"creature","etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power":true,"land_side_add_mana":"G","land_side_pay_three_life_else_tapped":true,"power":3,"toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiscipleOfFreyalise mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vibrance', 'Vibrance', '9f9398d4a93c0733a5ac19a0c9e50dd3', 'battle_rule_v1:d6ec311db4082874f2ec217353e116b4', '{"ability_kind":"triggered","battle_model_scope":"evoke_etb_red_damage_or_green_land_tutor_lifegain_v1","effect":"creature","etb_if_green_green_spent_gain_life":2,"etb_if_green_green_spent_search_land_to_hand":true,"etb_if_red_red_spent_damage_any_target":3,"evoke_cost":"{R/G}{R/G}","power":4,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Vibrance mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('archdruid''s charm', 'Archdruid''s Charm', 'c4df44104e459fecc46e4cb91708c4cd', 'battle_rule_v1:8737c73f1ba15aa4c12ddd7ed2fe2864', '{"ability_kind":"one_shot","battle_model_scope":"search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1","effect":"modal_spell","instant":true,"mode_exile_target_artifact_or_enchantment":true,"mode_put_plus_one_counter_on_controlled_creature_then_fight":true,"mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ArchdruidsCharm mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sink into stupor', 'Sink into Stupor', 'aa830204ff7fdbc43fd5b4b84b30ede1', 'battle_rule_v1:4055b69675e84cc871d1b5d1268ac119', '{"ability_kind":"one_shot","battle_model_scope":"return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1","effect":"bounce","instant":true,"land_side_add_mana":"U","land_side_pay_three_life_else_tapped":true,"target":"spell_or_opponent_nonland_permanent"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SinkIntoStupor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('ruthless technomancer', 'Ruthless Technomancer', '0723f53d95b32cfc0e68da4f2fb9552e', 'battle_rule_v1:90563f719a1a22cb76142cf78207bc25', '{"ability_kind":"triggered","activated_cost":"{2}{B}","activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less":true,"battle_model_scope":"etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1","effect":"creature","etb_may_sacrifice_another_creature_create_treasures_equal_power":true,"power":2,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RuthlessTechnomancer mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('emperor of bones', 'Emperor of Bones', 'c38cbc86cb985c9ee97265b67e59bb42', 'battle_rule_v1:be03995844cb037cb44bce18d4f06bc4', '{"ability_kind":"triggered","adapt_cost":"{1}{B}","adapt_counters":2,"battle_model_scope":"combat_exile_adapt_finality_reanimate_v1","beginning_of_combat_exile_up_to_one_card_from_graveyard":true,"counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot":true,"effect":"creature","power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EmperorOfBones mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('disciple of freyalise', 'Disciple of Freyalise', '3fb90a15cdcaba88791217be1f8cdaff', 'battle_rule_v1:050c819a19a33f85e0bceaac645fa7ba', '{"ability_kind":"triggered","battle_model_scope":"etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1","effect":"creature","etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power":true,"land_side_add_mana":"G","land_side_pay_three_life_else_tapped":true,"power":3,"toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiscipleOfFreyalise mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vibrance', 'Vibrance', '9f9398d4a93c0733a5ac19a0c9e50dd3', 'battle_rule_v1:d6ec311db4082874f2ec217353e116b4', '{"ability_kind":"triggered","battle_model_scope":"evoke_etb_red_damage_or_green_land_tutor_lifegain_v1","effect":"creature","etb_if_green_green_spent_gain_life":2,"etb_if_green_green_spent_search_land_to_hand":true,"etb_if_red_red_spent_damage_any_target":3,"evoke_cost":"{R/G}{R/G}","power":4,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Vibrance mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    p.notes
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
