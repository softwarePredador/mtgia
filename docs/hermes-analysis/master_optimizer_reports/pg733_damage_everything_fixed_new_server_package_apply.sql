BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg733_damage_everything_fixed_new_server_20260711_014908 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dakmor plague', 'dry spell', 'famine', 'fire tempest', 'inferno', 'rain of embers', 'steam blast')
   OR normalized_name LIKE 'dakmor plague // %'
   OR normalized_name LIKE 'dry spell // %'
   OR normalized_name LIKE 'famine // %'
   OR normalized_name LIKE 'fire tempest // %'
   OR normalized_name LIKE 'inferno // %'
   OR normalized_name LIKE 'rain of embers // %'
   OR normalized_name LIKE 'steam blast // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dakmor plague', 'Dakmor Plague', '013e9a91772b5cb2d8a1993d559d5126', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorPlague translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dry spell', 'Dry Spell', '37af1c7171b4d44b601b0887aea099be', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrySpell translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('famine', 'Famine', '6049389ea99f86359fac910367a8baa4', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Famine translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire tempest', 'Fire Tempest', '51b25fe4487c2ba60bfe5449d9cf4638', 'battle_rule_v1:fb4700fa4da352cbafe2cac6efe2bffe', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireTempest translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inferno', 'Inferno', '93769e4f5f3cb715b3507a643e3c0f10', 'battle_rule_v1:1013318f41fd3644ecd11bb07115c68f', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":true,"sorcery":false,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inferno translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of embers', 'Rain of Embers', '53c764d28470e0a8945bc3cc448033e6', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfEmbers translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steam blast', 'Steam Blast', '48aacdc842feb2625aa9f6ca7999b89c', 'battle_rule_v1:d272553afbab073b0b90a707c20d03e1', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":2,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteamBlast translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dakmor plague', 'Dakmor Plague', '013e9a91772b5cb2d8a1993d559d5126', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorPlague translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dry spell', 'Dry Spell', '37af1c7171b4d44b601b0887aea099be', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrySpell translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('famine', 'Famine', '6049389ea99f86359fac910367a8baa4', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Famine translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire tempest', 'Fire Tempest', '51b25fe4487c2ba60bfe5449d9cf4638', 'battle_rule_v1:fb4700fa4da352cbafe2cac6efe2bffe', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireTempest translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inferno', 'Inferno', '93769e4f5f3cb715b3507a643e3c0f10', 'battle_rule_v1:1013318f41fd3644ecd11bb07115c68f', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":true,"sorcery":false,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inferno translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of embers', 'Rain of Embers', '53c764d28470e0a8945bc3cc448033e6', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfEmbers translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steam blast', 'Steam Blast', '48aacdc842feb2625aa9f6ca7999b89c', 'battle_rule_v1:d272553afbab073b0b90a707c20d03e1', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":2,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteamBlast translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dakmor plague', 'Dakmor Plague', '013e9a91772b5cb2d8a1993d559d5126', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorPlague translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dry spell', 'Dry Spell', '37af1c7171b4d44b601b0887aea099be', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrySpell translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('famine', 'Famine', '6049389ea99f86359fac910367a8baa4', 'battle_rule_v1:58ac689d2294972d0e1b6d29535ad07e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":3,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Famine translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fire tempest', 'Fire Tempest', '51b25fe4487c2ba60bfe5449d9cf4638', 'battle_rule_v1:fb4700fa4da352cbafe2cac6efe2bffe', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FireTempest translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inferno', 'Inferno', '93769e4f5f3cb715b3507a643e3c0f10', 'battle_rule_v1:1013318f41fd3644ecd11bb07115c68f', '{"amount":6,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":6,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":true,"sorcery":false,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inferno translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of embers', 'Rain of Embers', '53c764d28470e0a8945bc3cc448033e6', 'battle_rule_v1:dadbf2239e41f350d14d994f0991b0c0', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":1,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfEmbers translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steam blast', 'Steam Blast', '48aacdc842feb2625aa9f6ca7999b89c', 'battle_rule_v1:d272553afbab073b0b90a707c20d03e1', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_each_creature_each_player_spell_v1","damage":2,"damage_players":true,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"target_controller":"all","xmage_effect_class":"DamageEverythingEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteamBlast translated into ManaLoom runtime scope xmage_fixed_damage_each_creature_each_player_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
