BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg654_dynamic_damage_wipe_new_server_20260708_115133 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('calamitous cave-in', 'chain reaction', 'gates ablaze', 'immolating gyre', 'skyreaping')
   OR normalized_name LIKE 'calamitous cave-in // %'
   OR normalized_name LIKE 'chain reaction // %'
   OR normalized_name LIKE 'gates ablaze // %'
   OR normalized_name LIKE 'immolating gyre // %'
   OR normalized_name LIKE 'skyreaping // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('calamitous cave-in', 'Calamitous Cave-In', '4069479e2214edce819d6a9edc3da97f', 'battle_rule_v1:ff384c2972d27eae1173bbbb12bcd2e0', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"caves_controlled_plus_cave_cards_in_graveyard","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CalamitousCaveIn translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chain reaction', 'Chain Reaction', '7133da1b111adf3a50a495277840c796', 'battle_rule_v1:b721248b835b2a566a36928f7de5f211', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChainReaction translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gates ablaze', 'Gates Ablaze', '93d9ca2d64d6702472f1beba1505cc00', 'battle_rule_v1:bce9b09587369ceddee79a4d87b2639d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GatesAblaze translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immolating gyre', 'Immolating Gyre', '92e197d6b4ce1c5741779d0b5f327e0e', 'battle_rule_v1:3a36e4c65fe5fbd1658a5dc91815619d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmolatingGyre translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyreaping', 'Skyreaping', '0c832362e9df1c38970d782accc8a1c3', 'battle_rule_v1:e00622e2a40dda1f82a2eb04c0b22f91', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"devotion_to_green","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skyreaping translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('calamitous cave-in', 'Calamitous Cave-In', '4069479e2214edce819d6a9edc3da97f', 'battle_rule_v1:ff384c2972d27eae1173bbbb12bcd2e0', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"caves_controlled_plus_cave_cards_in_graveyard","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CalamitousCaveIn translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chain reaction', 'Chain Reaction', '7133da1b111adf3a50a495277840c796', 'battle_rule_v1:b721248b835b2a566a36928f7de5f211', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChainReaction translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gates ablaze', 'Gates Ablaze', '93d9ca2d64d6702472f1beba1505cc00', 'battle_rule_v1:bce9b09587369ceddee79a4d87b2639d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GatesAblaze translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immolating gyre', 'Immolating Gyre', '92e197d6b4ce1c5741779d0b5f327e0e', 'battle_rule_v1:3a36e4c65fe5fbd1658a5dc91815619d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmolatingGyre translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyreaping', 'Skyreaping', '0c832362e9df1c38970d782accc8a1c3', 'battle_rule_v1:e00622e2a40dda1f82a2eb04c0b22f91', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"devotion_to_green","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skyreaping translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('calamitous cave-in', 'Calamitous Cave-In', '4069479e2214edce819d6a9edc3da97f', 'battle_rule_v1:ff384c2972d27eae1173bbbb12bcd2e0', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"caves_controlled_plus_cave_cards_in_graveyard","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CalamitousCaveIn translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chain reaction', 'Chain Reaction', '7133da1b111adf3a50a495277840c796', 'battle_rule_v1:b721248b835b2a566a36928f7de5f211', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChainReaction translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gates ablaze', 'Gates Ablaze', '93d9ca2d64d6702472f1beba1505cc00', 'battle_rule_v1:bce9b09587369ceddee79a4d87b2639d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GatesAblaze translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immolating gyre', 'Immolating Gyre', '92e197d6b4ce1c5741779d0b5f327e0e', 'battle_rule_v1:3a36e4c65fe5fbd1658a5dc91815619d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmolatingGyre translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyreaping', 'Skyreaping', '0c832362e9df1c38970d782accc8a1c3', 'battle_rule_v1:e00622e2a40dda1f82a2eb04c0b22f91', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"devotion_to_green","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skyreaping translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
