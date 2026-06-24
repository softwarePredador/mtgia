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
