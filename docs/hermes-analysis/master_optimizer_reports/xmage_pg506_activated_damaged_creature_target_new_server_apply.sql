BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg506_xmage_pg506_activated_damaged_crea_20260705_124220 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ogre siegebreaker', 'opportunist', 'witch''s mist')
   OR normalized_name LIKE 'ogre siegebreaker // %'
   OR normalized_name LIKE 'opportunist // %'
   OR normalized_name LIKE 'witch''s mist // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ogre siegebreaker', 'Ogre Siegebreaker', 'd9fe6fc297eeb748b517f9c308c77065', 'battle_rule_v1:034bd4c748e35fe57e52d223c648e8fd', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreSiegebreaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opportunist', 'Opportunist', 'aba5ffef49bc71c0b02a3ce50eca9c8c', 'battle_rule_v1:06261c009c5bcea9c7932e535c7b3359', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_damaged_this_turn"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Opportunist translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('witch''s mist', 'Witch''s Mist', '6feafae65830ccd4967852c92320404b', 'battle_rule_v1:9b34535f520f3ad0fd7e365e758a83b0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"enchantment","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitchsMist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ogre siegebreaker', 'Ogre Siegebreaker', 'd9fe6fc297eeb748b517f9c308c77065', 'battle_rule_v1:034bd4c748e35fe57e52d223c648e8fd', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreSiegebreaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opportunist', 'Opportunist', 'aba5ffef49bc71c0b02a3ce50eca9c8c', 'battle_rule_v1:06261c009c5bcea9c7932e535c7b3359', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_damaged_this_turn"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Opportunist translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('witch''s mist', 'Witch''s Mist', '6feafae65830ccd4967852c92320404b', 'battle_rule_v1:9b34535f520f3ad0fd7e365e758a83b0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"enchantment","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitchsMist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ogre siegebreaker', 'Ogre Siegebreaker', 'd9fe6fc297eeb748b517f9c308c77065', 'battle_rule_v1:034bd4c748e35fe57e52d223c648e8fd', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B","R"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}{R}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreSiegebreaker translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opportunist', 'Opportunist', 'aba5ffef49bc71c0b02a3ce50eca9c8c', 'battle_rule_v1:06261c009c5bcea9c7932e535c7b3359', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":1,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":1,"effect":"direct_damage","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":1,"activated_effect":"direct_damage","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"creature","target":"creature_damaged_this_turn","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_damaged_this_turn"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Opportunist translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('witch''s mist', 'Witch''s Mist', '6feafae65830ccd4967852c92320404b', 'battle_rule_v1:9b34535f520f3ad0fd7e365e758a83b0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"creature_damaged_this_turn","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"enchantment","target":"creature","target_constraints":{"card_types":["creature"],"damaged_this_turn":true},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WitchsMist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
