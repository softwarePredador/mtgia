BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg217_saga_draw_artifact_20260625_111141 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('the locust god', 'fable of the mirror-breaker // reflection of kiki-jiki', 'biotransference')
   OR normalized_name LIKE 'the locust god // %'
   OR normalized_name LIKE 'fable of the mirror-breaker // reflection of kiki-jiki // %'
   OR normalized_name LIKE 'biotransference // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('the locust god', 'The Locust God', '1b1e612bd7ad1564ae4d3ad8619013e2', 'battle_rule_v1:67d30157e4cec4c53fd99294af46a927', '{"ability_kind":"triggered","activated_loot":true,"activation_cost":"{2}{U}{R}","battle_model_scope":"controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1","cmc":6.0,"controller_draw_create_token":true,"dies_return_to_owner_hand_next_end_step":true,"effect":"creature","flying":true,"power":4,"token_colors":["U","R"],"token_count_per_card_drawn":1,"token_flying":true,"token_haste":true,"token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheLocustGod mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fable of the mirror-breaker // reflection of kiki-jiki', 'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki', '02f9bffe27fcef275a01555f7b6fc16b', 'battle_rule_v1:35f799486c8be66724ba9e6b155490f7', '{"ability_kind":"activated","battle_model_scope":"saga_goblin_rummage_transform_reflection_copy_v1","cmc":3.0,"effect":"token_maker","saga_chapter_effects":{"1":{"effect":"token_maker","token_attack_create_treasure":true,"token_colors":["R"],"token_count":1,"token_name":"Goblin Shaman Token","token_power":2,"token_subtype":"Goblin Shaman","token_toughness":2},"2":{"draw_equal_to_discarded":true,"effect":"discard_draw","max_discard":2},"3":{"effect":"transform"}},"saga_final_chapter":3,"transform_to":{"activated_copy_target_another_nonlegendary_creature_you_control":true,"activation_cost_generic":1,"activation_requires_tap":true,"copy_target_types":["creature"],"effect":"creature","exclude_legendary_copy_targets":true,"exclude_source_from_copy_targets":true,"name":"Reflection of Kiki-Jiki","power":2,"sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true,"toughness":2,"type_line":"Enchantment Creature - Goblin Shaman"}}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FableOfTheMirrorBreaker mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('biotransference', 'Biotransference', 'db6e884f32d6be76e85eebb3e3dd986c', 'battle_rule_v1:4b017d52015c70dfb33338170767bad8', '{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1","cmc":4.0,"controlled_creature_cards_owned_are_artifacts":true,"controlled_creatures_and_creature_spells_are_artifacts":true,"controller_loses_life_on_trigger":1,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_name":"Necron Warrior Token","token_power":2,"token_subtype":"Necron Warrior","token_toughness":2,"trigger":"spell_cast","trigger_artifact_spell":true,"trigger_effect":"token_maker"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Biotransference mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('the locust god', 'The Locust God', '1b1e612bd7ad1564ae4d3ad8619013e2', 'battle_rule_v1:67d30157e4cec4c53fd99294af46a927', '{"ability_kind":"triggered","activated_loot":true,"activation_cost":"{2}{U}{R}","battle_model_scope":"controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1","cmc":6.0,"controller_draw_create_token":true,"dies_return_to_owner_hand_next_end_step":true,"effect":"creature","flying":true,"power":4,"token_colors":["U","R"],"token_count_per_card_drawn":1,"token_flying":true,"token_haste":true,"token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheLocustGod mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fable of the mirror-breaker // reflection of kiki-jiki', 'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki', '02f9bffe27fcef275a01555f7b6fc16b', 'battle_rule_v1:35f799486c8be66724ba9e6b155490f7', '{"ability_kind":"activated","battle_model_scope":"saga_goblin_rummage_transform_reflection_copy_v1","cmc":3.0,"effect":"token_maker","saga_chapter_effects":{"1":{"effect":"token_maker","token_attack_create_treasure":true,"token_colors":["R"],"token_count":1,"token_name":"Goblin Shaman Token","token_power":2,"token_subtype":"Goblin Shaman","token_toughness":2},"2":{"draw_equal_to_discarded":true,"effect":"discard_draw","max_discard":2},"3":{"effect":"transform"}},"saga_final_chapter":3,"transform_to":{"activated_copy_target_another_nonlegendary_creature_you_control":true,"activation_cost_generic":1,"activation_requires_tap":true,"copy_target_types":["creature"],"effect":"creature","exclude_legendary_copy_targets":true,"exclude_source_from_copy_targets":true,"name":"Reflection of Kiki-Jiki","power":2,"sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true,"toughness":2,"type_line":"Enchantment Creature - Goblin Shaman"}}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FableOfTheMirrorBreaker mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('biotransference', 'Biotransference', 'db6e884f32d6be76e85eebb3e3dd986c', 'battle_rule_v1:4b017d52015c70dfb33338170767bad8', '{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1","cmc":4.0,"controlled_creature_cards_owned_are_artifacts":true,"controlled_creatures_and_creature_spells_are_artifacts":true,"controller_loses_life_on_trigger":1,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_name":"Necron Warrior Token","token_power":2,"token_subtype":"Necron Warrior","token_toughness":2,"trigger":"spell_cast","trigger_artifact_spell":true,"trigger_effect":"token_maker"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Biotransference mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('the locust god', 'The Locust God', '1b1e612bd7ad1564ae4d3ad8619013e2', 'battle_rule_v1:67d30157e4cec4c53fd99294af46a927', '{"ability_kind":"triggered","activated_loot":true,"activation_cost":"{2}{U}{R}","battle_model_scope":"controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1","cmc":6.0,"controller_draw_create_token":true,"dies_return_to_owner_hand_next_end_step":true,"effect":"creature","flying":true,"power":4,"token_colors":["U","R"],"token_count_per_card_drawn":1,"token_flying":true,"token_haste":true,"token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheLocustGod mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fable of the mirror-breaker // reflection of kiki-jiki', 'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki', '02f9bffe27fcef275a01555f7b6fc16b', 'battle_rule_v1:35f799486c8be66724ba9e6b155490f7', '{"ability_kind":"activated","battle_model_scope":"saga_goblin_rummage_transform_reflection_copy_v1","cmc":3.0,"effect":"token_maker","saga_chapter_effects":{"1":{"effect":"token_maker","token_attack_create_treasure":true,"token_colors":["R"],"token_count":1,"token_name":"Goblin Shaman Token","token_power":2,"token_subtype":"Goblin Shaman","token_toughness":2},"2":{"draw_equal_to_discarded":true,"effect":"discard_draw","max_discard":2},"3":{"effect":"transform"}},"saga_final_chapter":3,"transform_to":{"activated_copy_target_another_nonlegendary_creature_you_control":true,"activation_cost_generic":1,"activation_requires_tap":true,"copy_target_types":["creature"],"effect":"creature","exclude_legendary_copy_targets":true,"exclude_source_from_copy_targets":true,"name":"Reflection of Kiki-Jiki","power":2,"sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true,"toughness":2,"type_line":"Enchantment Creature - Goblin Shaman"}}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FableOfTheMirrorBreaker mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('biotransference', 'Biotransference', 'db6e884f32d6be76e85eebb3e3dd986c', 'battle_rule_v1:4b017d52015c70dfb33338170767bad8', '{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1","cmc":4.0,"controlled_creature_cards_owned_are_artifacts":true,"controlled_creatures_and_creature_spells_are_artifacts":true,"controller_loses_life_on_trigger":1,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_name":"Necron Warrior Token","token_power":2,"token_subtype":"Necron Warrior","token_toughness":2,"trigger":"spell_cast","trigger_artifact_spell":true,"trigger_effect":"token_maker"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Biotransference mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
