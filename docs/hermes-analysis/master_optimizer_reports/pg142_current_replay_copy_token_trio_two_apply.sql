BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg142_current_replay_copy_token_trio_two_20260624_042157 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('jaxis, the troublemaker', 'rionya, fire dancer', 'the jolly balloon man')
   OR normalized_name LIKE 'jaxis, the troublemaker // %'
   OR normalized_name LIKE 'rionya, fire dancer // %'
   OR normalized_name LIKE 'the jolly balloon man // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('jaxis, the troublemaker', 'Jaxis, the Troublemaker', '92a1b679c9eca885a43a49b79f3d6fb7', 'battle_rule_v1:082e6fbdbbb20e5efed4de5cf8ab3bf1', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_draw_cards_when_this_dies":1,"token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class JaxisTheTroublemaker mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rionya, fire dancer', 'Rionya, Fire Dancer', 'ef40defdde750928a8c7425749e9fba6', 'battle_rule_v1:c907c29d4de7bea750538d5110daa852', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"exile_token_at_end_step":true,"target_controller":"own","token_count_source":"instant_or_sorcery_spells_cast_this_turn_plus_one","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RionyaFireDancer mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the jolly balloon man', 'The Jolly Balloon Man', 'c7f3f2f27d70fe9c5abb53ad64e06dd0', 'battle_rule_v1:e2ff37fab414ef5ed43b5dc17b921f63', '{"ability_kind":"activated","battle_model_scope":"copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"force_token_creature":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_extra_colors":["R"],"token_flying":true,"token_haste":true,"token_power":1,"token_subtype":"Balloon","token_toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheJollyBalloonMan mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('jaxis, the troublemaker', 'Jaxis, the Troublemaker', '92a1b679c9eca885a43a49b79f3d6fb7', 'battle_rule_v1:082e6fbdbbb20e5efed4de5cf8ab3bf1', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_draw_cards_when_this_dies":1,"token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class JaxisTheTroublemaker mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rionya, fire dancer', 'Rionya, Fire Dancer', 'ef40defdde750928a8c7425749e9fba6', 'battle_rule_v1:c907c29d4de7bea750538d5110daa852', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"exile_token_at_end_step":true,"target_controller":"own","token_count_source":"instant_or_sorcery_spells_cast_this_turn_plus_one","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RionyaFireDancer mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the jolly balloon man', 'The Jolly Balloon Man', 'c7f3f2f27d70fe9c5abb53ad64e06dd0', 'battle_rule_v1:e2ff37fab414ef5ed43b5dc17b921f63', '{"ability_kind":"activated","battle_model_scope":"copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"force_token_creature":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_extra_colors":["R"],"token_flying":true,"token_haste":true,"token_power":1,"token_subtype":"Balloon","token_toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheJollyBalloonMan mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('jaxis, the troublemaker', 'Jaxis, the Troublemaker', '92a1b679c9eca885a43a49b79f3d6fb7', 'battle_rule_v1:082e6fbdbbb20e5efed4de5cf8ab3bf1', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_draw_cards_when_this_dies":1,"token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class JaxisTheTroublemaker mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rionya, fire dancer', 'Rionya, Fire Dancer', 'ef40defdde750928a8c7425749e9fba6', 'battle_rule_v1:c907c29d4de7bea750538d5110daa852', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"exile_token_at_end_step":true,"target_controller":"own","token_count_source":"instant_or_sorcery_spells_cast_this_turn_plus_one","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RionyaFireDancer mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the jolly balloon man', 'The Jolly Balloon Man', 'c7f3f2f27d70fe9c5abb53ad64e06dd0', 'battle_rule_v1:e2ff37fab414ef5ed43b5dc17b921f63', '{"ability_kind":"activated","battle_model_scope":"copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"force_token_creature":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_extra_colors":["R"],"token_flying":true,"token_haste":true,"token_power":1,"token_subtype":"Balloon","token_toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheJollyBalloonMan mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
