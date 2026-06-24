BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg192_perch_sand_token_creature_20260624_221536 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('perch protection', 'sand scout')
   OR normalized_name LIKE 'perch protection // %'
   OR normalized_name LIKE 'sand scout // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('perch protection', 'Perch Protection', '071dda7526fa44bf0c7a64079c454d96', 'battle_rule_v1:20683e46e0165b27840cb086f902c649', '{"_composite_rule_components":[{"battle_model_scope":"create_four_2_2_blue_flying_bird_tokens_component_v1","effect":"token_maker","token_colors":["U"],"token_count":4,"token_flying":true,"token_name":"Bird Token","token_power":2,"token_subtype":"Bird","token_toughness":2},{"battle_model_scope":"gift_promised_phase_all_permanents_life_lock_protection_component_v1","effect":"phase_out","gift_required":true,"life_total_cant_change":true,"phase_out_all_permanents_you_control":true,"phase_out_includes_lands":true,"protection_from_everything":true}],"ability_kind":"one_shot","battle_model_scope":"create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1","effect":"composite_resolution","exiles_self":true,"gift_default_promised":true,"gift_extra_turn":true,"instant":true}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PerchProtection mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sand scout', 'Sand Scout', '5b433ca71a358a2826c5aff65783f004', 'battle_rule_v1:d25329373e747c6a62963a0acf6b606f', '{"ability_kind":"triggered","battle_model_scope":"sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1","effect":"creature","etb_land_ramp_condition":"opponent_controls_more_lands","etb_land_ramp_count":1,"land_cards_to_your_graveyard_create_token":true,"land_enters_tapped":true,"land_graveyard_token_colors":["R","G","W"],"land_graveyard_token_name":"Sand Warrior Token","land_graveyard_token_power":1,"land_graveyard_token_subtype":"Sand Warrior","land_graveyard_token_toughness":1,"land_graveyard_trigger_once_each_turn":true,"land_subtypes_any":["desert"],"power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SandScout mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('perch protection', 'Perch Protection', '071dda7526fa44bf0c7a64079c454d96', 'battle_rule_v1:20683e46e0165b27840cb086f902c649', '{"_composite_rule_components":[{"battle_model_scope":"create_four_2_2_blue_flying_bird_tokens_component_v1","effect":"token_maker","token_colors":["U"],"token_count":4,"token_flying":true,"token_name":"Bird Token","token_power":2,"token_subtype":"Bird","token_toughness":2},{"battle_model_scope":"gift_promised_phase_all_permanents_life_lock_protection_component_v1","effect":"phase_out","gift_required":true,"life_total_cant_change":true,"phase_out_all_permanents_you_control":true,"phase_out_includes_lands":true,"protection_from_everything":true}],"ability_kind":"one_shot","battle_model_scope":"create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1","effect":"composite_resolution","exiles_self":true,"gift_default_promised":true,"gift_extra_turn":true,"instant":true}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PerchProtection mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sand scout', 'Sand Scout', '5b433ca71a358a2826c5aff65783f004', 'battle_rule_v1:d25329373e747c6a62963a0acf6b606f', '{"ability_kind":"triggered","battle_model_scope":"sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1","effect":"creature","etb_land_ramp_condition":"opponent_controls_more_lands","etb_land_ramp_count":1,"land_cards_to_your_graveyard_create_token":true,"land_enters_tapped":true,"land_graveyard_token_colors":["R","G","W"],"land_graveyard_token_name":"Sand Warrior Token","land_graveyard_token_power":1,"land_graveyard_token_subtype":"Sand Warrior","land_graveyard_token_toughness":1,"land_graveyard_trigger_once_each_turn":true,"land_subtypes_any":["desert"],"power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SandScout mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('perch protection', 'Perch Protection', '071dda7526fa44bf0c7a64079c454d96', 'battle_rule_v1:20683e46e0165b27840cb086f902c649', '{"_composite_rule_components":[{"battle_model_scope":"create_four_2_2_blue_flying_bird_tokens_component_v1","effect":"token_maker","token_colors":["U"],"token_count":4,"token_flying":true,"token_name":"Bird Token","token_power":2,"token_subtype":"Bird","token_toughness":2},{"battle_model_scope":"gift_promised_phase_all_permanents_life_lock_protection_component_v1","effect":"phase_out","gift_required":true,"life_total_cant_change":true,"phase_out_all_permanents_you_control":true,"phase_out_includes_lands":true,"protection_from_everything":true}],"ability_kind":"one_shot","battle_model_scope":"create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1","effect":"composite_resolution","exiles_self":true,"gift_default_promised":true,"gift_extra_turn":true,"instant":true}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PerchProtection mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sand scout', 'Sand Scout', '5b433ca71a358a2826c5aff65783f004', 'battle_rule_v1:d25329373e747c6a62963a0acf6b606f', '{"ability_kind":"triggered","battle_model_scope":"sand_scout_etb_desert_if_behind_lands_land_graveyard_token_v1","effect":"creature","etb_land_ramp_condition":"opponent_controls_more_lands","etb_land_ramp_count":1,"land_cards_to_your_graveyard_create_token":true,"land_enters_tapped":true,"land_graveyard_token_colors":["R","G","W"],"land_graveyard_token_name":"Sand Warrior Token","land_graveyard_token_power":1,"land_graveyard_token_subtype":"Sand Warrior","land_graveyard_token_toughness":1,"land_graveyard_trigger_once_each_turn":true,"land_subtypes_any":["desert"],"power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SandScout mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
