WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('black market connections', 'Black Market Connections', '7d64928ea3153bf9390dc2356ccccb64', 'battle_rule_v1:9627a4437f1b6029c04032ba2e552c0b', '{"ability_kind":"triggered","battle_model_scope":"precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1","cmc":3.0,"effect":"token_maker","mode_selection_life_floor":4,"mode_selection_model":"all_modes_if_life_after_loss_at_least_floor","precombat_main_choose_modes_treasure_draw_token_life_loss":true,"precombat_main_modes":[{"effect":"create_treasure","life_loss":1,"name":"Sell Contraband","treasure_count":1},{"draw_cards":1,"effect":"draw_cards","life_loss":2,"name":"Buy Information"},{"effect":"token_maker","life_loss":3,"name":"Hire a Mercenary","token":{"token_colors":[],"token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":3,"token_subtype":"Shapeshifter","token_toughness":2},"token_count":1}],"trigger":"beginning_precombat_main"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BlackMarketConnections mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('smuggler''s share', 'Smuggler''s Share', '1076ff44243459457e22ec5bec940daf', 'battle_rule_v1:d1967f626af998349b300eee21f20156', '{"ability_kind":"triggered","battle_model_scope":"each_end_step_opponent_extra_draw_landfall_draw_treasure_v1","cmc":3.0,"draw_cards_per_qualified_opponent":1,"each_end_step_opponent_extra_draw_land_treasure":true,"effect":"token_maker","land_entry_runtime_proxy":"lands_played_this_turn","opponent_cards_drawn_threshold":2,"opponent_lands_entered_threshold":2,"treasure_count_per_qualified_opponent":1,"trigger":"each_end_step"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SmugglersShare mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('davros, dalek creator', 'Davros, Dalek Creator', 'b3c9d6bb7aba3a111395e2ab07ccd32f', 'battle_rule_v1:d03959f01d684d887bec04985c092274', '{"ability_kind":"triggered","artifact_creature":true,"artifact_tokens":true,"battle_model_scope":"controller_end_step_opponent_lost_life_dalek_villainous_choice_v1","cmc":4.0,"controller_end_step_opponent_lost_life_dalek_villainous_choice":true,"effect":"creature","menace":true,"opponent_life_lost_threshold":3,"power":3,"token_colors":["B"],"token_count":1,"token_keywords":["menace"],"token_name":"Dalek Token","token_power":3,"token_subtype":"Dalek","token_toughness":3,"toughness":4,"trigger":"controller_end_step","villainous_choice_model":"opponent_discards_if_possible_else_controller_draws"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DavrosDalekCreator mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
