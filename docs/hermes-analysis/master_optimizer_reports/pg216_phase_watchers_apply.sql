BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg216_phase_watchers_20260625_104702 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('black market connections', 'smuggler''s share', 'davros, dalek creator')
   OR normalized_name LIKE 'black market connections // %'
   OR normalized_name LIKE 'smuggler''s share // %'
   OR normalized_name LIKE 'davros, dalek creator // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('black market connections', 'Black Market Connections', '7d64928ea3153bf9390dc2356ccccb64', 'battle_rule_v1:9627a4437f1b6029c04032ba2e552c0b', '{"ability_kind":"triggered","battle_model_scope":"precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1","cmc":3.0,"effect":"token_maker","mode_selection_life_floor":4,"mode_selection_model":"all_modes_if_life_after_loss_at_least_floor","precombat_main_choose_modes_treasure_draw_token_life_loss":true,"precombat_main_modes":[{"effect":"create_treasure","life_loss":1,"name":"Sell Contraband","treasure_count":1},{"draw_cards":1,"effect":"draw_cards","life_loss":2,"name":"Buy Information"},{"effect":"token_maker","life_loss":3,"name":"Hire a Mercenary","token":{"token_colors":[],"token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":3,"token_subtype":"Shapeshifter","token_toughness":2},"token_count":1}],"trigger":"beginning_precombat_main"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BlackMarketConnections mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('smuggler''s share', 'Smuggler''s Share', '1076ff44243459457e22ec5bec940daf', 'battle_rule_v1:d1967f626af998349b300eee21f20156', '{"ability_kind":"triggered","battle_model_scope":"each_end_step_opponent_extra_draw_landfall_draw_treasure_v1","cmc":3.0,"draw_cards_per_qualified_opponent":1,"each_end_step_opponent_extra_draw_land_treasure":true,"effect":"token_maker","land_entry_runtime_proxy":"lands_played_this_turn","opponent_cards_drawn_threshold":2,"opponent_lands_entered_threshold":2,"treasure_count_per_qualified_opponent":1,"trigger":"each_end_step"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SmugglersShare mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('davros, dalek creator', 'Davros, Dalek Creator', 'b3c9d6bb7aba3a111395e2ab07ccd32f', 'battle_rule_v1:d03959f01d684d887bec04985c092274', '{"ability_kind":"triggered","artifact_creature":true,"artifact_tokens":true,"battle_model_scope":"controller_end_step_opponent_lost_life_dalek_villainous_choice_v1","cmc":4.0,"controller_end_step_opponent_lost_life_dalek_villainous_choice":true,"effect":"creature","menace":true,"opponent_life_lost_threshold":3,"power":3,"token_colors":["B"],"token_count":1,"token_keywords":["menace"],"token_name":"Dalek Token","token_power":3,"token_subtype":"Dalek","token_toughness":3,"toughness":4,"trigger":"controller_end_step","villainous_choice_model":"opponent_discards_if_possible_else_controller_draws"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DavrosDalekCreator mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('black market connections', 'Black Market Connections', '7d64928ea3153bf9390dc2356ccccb64', 'battle_rule_v1:9627a4437f1b6029c04032ba2e552c0b', '{"ability_kind":"triggered","battle_model_scope":"precombat_main_choose_modes_treasure_draw_shapeshifter_life_loss_v1","cmc":3.0,"effect":"token_maker","mode_selection_life_floor":4,"mode_selection_model":"all_modes_if_life_after_loss_at_least_floor","precombat_main_choose_modes_treasure_draw_token_life_loss":true,"precombat_main_modes":[{"effect":"create_treasure","life_loss":1,"name":"Sell Contraband","treasure_count":1},{"draw_cards":1,"effect":"draw_cards","life_loss":2,"name":"Buy Information"},{"effect":"token_maker","life_loss":3,"name":"Hire a Mercenary","token":{"token_colors":[],"token_keywords":["changeling"],"token_name":"Shapeshifter Token","token_power":3,"token_subtype":"Shapeshifter","token_toughness":2},"token_count":1}],"trigger":"beginning_precombat_main"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BlackMarketConnections mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('smuggler''s share', 'Smuggler''s Share', '1076ff44243459457e22ec5bec940daf', 'battle_rule_v1:d1967f626af998349b300eee21f20156', '{"ability_kind":"triggered","battle_model_scope":"each_end_step_opponent_extra_draw_landfall_draw_treasure_v1","cmc":3.0,"draw_cards_per_qualified_opponent":1,"each_end_step_opponent_extra_draw_land_treasure":true,"effect":"token_maker","land_entry_runtime_proxy":"lands_played_this_turn","opponent_cards_drawn_threshold":2,"opponent_lands_entered_threshold":2,"treasure_count_per_qualified_opponent":1,"trigger":"each_end_step"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SmugglersShare mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('davros, dalek creator', 'Davros, Dalek Creator', 'b3c9d6bb7aba3a111395e2ab07ccd32f', 'battle_rule_v1:d03959f01d684d887bec04985c092274', '{"ability_kind":"triggered","artifact_creature":true,"artifact_tokens":true,"battle_model_scope":"controller_end_step_opponent_lost_life_dalek_villainous_choice_v1","cmc":4.0,"controller_end_step_opponent_lost_life_dalek_villainous_choice":true,"effect":"creature","menace":true,"opponent_life_lost_threshold":3,"power":3,"token_colors":["B"],"token_count":1,"token_keywords":["menace"],"token_name":"Dalek Token","token_power":3,"token_subtype":"Dalek","token_toughness":3,"toughness":4,"trigger":"controller_end_step","villainous_choice_model":"opponent_discards_if_possible_else_controller_draws"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DavrosDalekCreator mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
