BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg643_creature_source_prevention_new_ser_20260707_220414 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ethereal haze', 'harmless assault', 'hunter''s ambush', 'thwart the enemy', 'vine snare')
   OR normalized_name LIKE 'ethereal haze // %'
   OR normalized_name LIKE 'harmless assault // %'
   OR normalized_name LIKE 'hunter''s ambush // %'
   OR normalized_name LIKE 'thwart the enemy // %'
   OR normalized_name LIKE 'vine snare // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ethereal haze', 'Ethereal Haze', 'e40ccef210036508a675913beb82b76a', 'battle_rule_v1:9fca8ead02e6ecfd5dca402fd1b5005f', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EtherealHaze translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harmless assault', 'Harmless Assault', 'ce5c49e8d6fa039f6ef0779f2948babd', 'battle_rule_v1:5f3de78578b5094b87f338c98ae4b9a7', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"combat_role":"attacking"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarmlessAssault translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hunter''s ambush', 'Hunter''s Ambush', 'c25758a6bbd50a7d902c5c98b40764ac', 'battle_rule_v1:85209bbf30b3c8a3fd7ed15f58a779e2', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HuntersAmbush translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thwart the enemy', 'Thwart the Enemy', 'ad413164aca5d65f29503d075eaee7f8', 'battle_rule_v1:276afd80522f6d887335c2f46352b750', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"controller_scope":"opponents_control"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThwartTheEnemy translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vine snare', 'Vine Snare', '8bbd84b4d5d6a574896f766d9974bf80', 'battle_rule_v1:d0ac46bdd9ce7de24c3f2a13a6b4d0af', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"power_lte":4},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VineSnare translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ethereal haze', 'Ethereal Haze', 'e40ccef210036508a675913beb82b76a', 'battle_rule_v1:9fca8ead02e6ecfd5dca402fd1b5005f', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EtherealHaze translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harmless assault', 'Harmless Assault', 'ce5c49e8d6fa039f6ef0779f2948babd', 'battle_rule_v1:5f3de78578b5094b87f338c98ae4b9a7', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"combat_role":"attacking"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarmlessAssault translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hunter''s ambush', 'Hunter''s Ambush', 'c25758a6bbd50a7d902c5c98b40764ac', 'battle_rule_v1:85209bbf30b3c8a3fd7ed15f58a779e2', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HuntersAmbush translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thwart the enemy', 'Thwart the Enemy', 'ad413164aca5d65f29503d075eaee7f8', 'battle_rule_v1:276afd80522f6d887335c2f46352b750', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"controller_scope":"opponents_control"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThwartTheEnemy translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vine snare', 'Vine Snare', '8bbd84b4d5d6a574896f766d9974bf80', 'battle_rule_v1:d0ac46bdd9ce7de24c3f2a13a6b4d0af', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"power_lte":4},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VineSnare translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ethereal haze', 'Ethereal Haze', 'e40ccef210036508a675913beb82b76a', 'battle_rule_v1:9fca8ead02e6ecfd5dca402fd1b5005f', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EtherealHaze translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harmless assault', 'Harmless Assault', 'ce5c49e8d6fa039f6ef0779f2948babd', 'battle_rule_v1:5f3de78578b5094b87f338c98ae4b9a7', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"combat_role":"attacking"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarmlessAssault translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hunter''s ambush', 'Hunter''s Ambush', 'c25758a6bbd50a7d902c5c98b40764ac', 'battle_rule_v1:85209bbf30b3c8a3fd7ed15f58a779e2', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"exclude_colors":["G"]},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HuntersAmbush translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thwart the enemy', 'Thwart the Enemy', 'ad413164aca5d65f29503d075eaee7f8', 'battle_rule_v1:276afd80522f6d887335c2f46352b750', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"all_damage","prevent_damage_scope":"damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"controller_scope":"opponents_control"},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThwartTheEnemy translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vine snare', 'Vine Snare', '8bbd84b4d5d6a574896f766d9974bf80', 'battle_rule_v1:d0ac46bdd9ce7de24c3f2a13a6b4d0af', '{"battle_model_scope":"xmage_prevent_damage_from_creatures_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_from_creature_sources_this_turn":true,"prevent_damage_kind":"combat_damage","prevent_damage_scope":"combat_damage_from_creatures","prevent_source_constraints":{"card_types":["creature"],"power_lte":4},"sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VineSnare translated into ManaLoom runtime scope xmage_prevent_damage_from_creatures_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of damage from filtered creature sources until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
