BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg111_deck607_board_wipe_choice_20260623_192502 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN (
  'promise of loyalty',
  'starfall invocation',
  'tragic arrogance'
);

DO $$
DECLARE
  v_bad_count integer;
BEGIN
  WITH wanted(normalized_name, expected_hash) AS (
    VALUES
      ('promise of loyalty', '21dd715160fde6e50b8edc015ce83b0f'),
      ('starfall invocation', '3429884949eac8ffe09d86dc85bee1ae'),
      ('tragic arrogance', 'efdf5d051aaa7f94b12c4dccbbfd7d3d')
  ),
  matched AS (
    SELECT w.normalized_name, count(c.id) AS matched_rows
    FROM wanted w
    LEFT JOIN public.cards c
      ON lower(c.name) = w.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = w.expected_hash
    GROUP BY w.normalized_name
  )
  SELECT count(*)
    INTO v_bad_count
  FROM matched
  WHERE matched_rows <> 1;

  IF v_bad_count <> 0 THEN
    RAISE EXCEPTION 'PG111 abort: expected exactly one Oracle-hash-matched card row for each target, bad target count %', v_bad_count;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG111: deprecated stale generated/review-only shadow after Oracle/XMage-backed board_wipe_choice runtime rules were promoted.'
    )
  WHERE r.normalized_name IN (
      'promise of loyalty',
      'starfall invocation',
      'tragic arrogance'
    )
    AND r.logical_rule_key NOT IN (
      'battle_rule_v1:78fff8e218103b0710bc5ee9cf174ee9',
      'battle_rule_v1:58cfb4628b4a4a879f6f9c5e0ab3ee5f',
      'battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a'
    )
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_cards AS (
  SELECT lower(name) AS normalized_name, id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) IN (
    'promise of loyalty',
    'starfall invocation',
    'tragic arrogance'
  )
),
payloads AS (
  SELECT
    'promise of loyalty'::text AS normalized_name,
    'battle_rule_v1:78fff8e218103b0710bc5ee9cf174ee9'::text AS logical_rule_key,
    '{
      "battle_model_scope":"each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1",
      "cmc":5.0,
      "effect":"vow_counter_each_player_sacrifice_rest",
      "counter_type":"vow",
      "choice_scope":"each_player_one_creature_they_control",
      "sacrifice_scope":"other_creatures",
      "attack_restriction":"cant_attack_source_controller_or_planeswalkers_while_vow_counter"
    }'::jsonb AS effect_json,
    '{"category":"interaction","effect":"vow_counter_each_player_sacrifice_rest","subtype":"vow_sacrifice_wipe","timing":"sorcery"}'::jsonb AS deck_role_json,
    0.96::numeric AS confidence,
    '21dd715160fde6e50b8edc015ce83b0f'::text AS oracle_hash,
    'PG111: Oracle/XMage-backed Promise of Loyalty rule. Runtime puts one vow counter on the best creature each player controls, sacrifices the rest, and records the vow attack restriction against the source controller.'::text AS notes
  UNION ALL
  SELECT
    'starfall invocation'::text,
    'battle_rule_v1:58cfb4628b4a4a879f6f9c5e0ab3ee5f'::text,
    '{
      "battle_model_scope":"gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1",
      "cmc":5.0,
      "effect":"gift_destroy_all_creatures_return_own_destroyed_creature",
      "gift":"card",
      "gift_default_promised":true,
      "gift_card_draw":true,
      "gift_choice_model":"lowest_visible_threat_opponent",
      "destroy_scope":"all_creatures",
      "return_scope":"own_creature_destroyed_this_way",
      "return_destination":"battlefield_under_your_control"
    }'::jsonb,
    '{"category":"interaction","effect":"gift_destroy_all_creatures_return_own_destroyed_creature","subtype":"gift_rebuild_wipe","timing":"sorcery"}'::jsonb,
    0.96::numeric,
    '3429884949eac8ffe09d86dc85bee1ae'::text,
    'PG111: Oracle/XMage-backed Starfall Invocation rule. Runtime gifts a card, destroys all creatures, and returns the best own creature card put into graveyard this way when the gift is promised.'
  UNION ALL
  SELECT
    'tragic arrogance'::text,
    'battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a'::text,
    '{
      "battle_model_scope":"controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1",
      "cmc":5.0,
      "effect":"selective_nonland_sacrifice",
      "controller_chooses_for_each_player":true,
      "choice_types":["artifact","creature","enchantment","planeswalker"],
      "sacrifice_scope":"other_nonland_permanents"
    }'::jsonb,
    '{"category":"interaction","effect":"selective_nonland_sacrifice","subtype":"selective_nonland_wipe","timing":"sorcery"}'::jsonb,
    0.96::numeric,
    'efdf5d051aaa7f94b12c4dccbbfd7d3d'::text,
    'PG111: Oracle/XMage-backed Tragic Arrogance rule. Runtime lets the source controller choose the best artifact, creature, enchantment, and planeswalker for each player, then sacrifices the other nonland permanents.'
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
    p.normalized_name,
    tc.id,
    tc.name,
    p.effect_json,
    p.deck_role_json,
    'curated',
    p.confidence,
    'verified',
    2,
    p.oracle_hash,
    p.notes,
    'codex-pg111',
    now(),
    now(),
    now(),
    now(),
    p.logical_rule_key,
    'auto'
  FROM payloads p
  JOIN target_cards tc ON tc.normalized_name = p.normalized_name AND tc.oracle_hash = p.oracle_hash
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
SELECT count(*) AS upserted_rows
FROM upserted;

COMMIT;
