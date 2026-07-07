BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg581_each_player_sacrifice_new_server_20260706_235302 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('barter in blood', 'crack the earth', 'innocent blood', 'renounce the guilds', 'simplify', 'tergrid''s shadow', 'tremble')
   OR normalized_name LIKE 'barter in blood // %'
   OR normalized_name LIKE 'crack the earth // %'
   OR normalized_name LIKE 'innocent blood // %'
   OR normalized_name LIKE 'renounce the guilds // %'
   OR normalized_name LIKE 'simplify // %'
   OR normalized_name LIKE 'tergrid''s shadow // %'
   OR normalized_name LIKE 'tremble // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barter in blood', 'Barter in Blood', 'be856a7f6d029bfa5be0bfe07f7915d7', 'battle_rule_v1:4dc466c70a22a941f04f26618e8a6ee1', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarterInBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack the earth', 'Crack the Earth', '08446934f7df33a207467fb5b627fa50', 'battle_rule_v1:d2aa51841d87625e029e0c1d78119c0b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackTheEarth translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('innocent blood', 'Innocent Blood', '936b01368e4684556867764af9ce37c5', 'battle_rule_v1:e36e942e876596fa39c2abef5eac238f', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnocentBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('renounce the guilds', 'Renounce the Guilds', '3127e90fe826e0d6097996f889d848b9', 'battle_rule_v1:172ceadc506f12be79de7edc8edc647b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_requires_multicolored":true,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RenounceTheGuilds translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('simplify', 'Simplify', '3e5ca27a1aaa76ffa9aa0c13d1689aa5', 'battle_rule_v1:8d62f54198483e3e3deeec43de124cd5', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["enchantment"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Simplify translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tergrid''s shadow', 'Tergrid''s Shadow', '5a7e33d8e6b36112f4c1ac58776c8e12', 'battle_rule_v1:d2088319b0a6c4d1bd660dfc024c73e6', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TergridsShadow translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tremble', 'Tremble', 'e3d97dc178a6579b3b6f279e42e225db', 'battle_rule_v1:4aec324ab24ccc2a1adfe7a07131cf98', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tremble translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('barter in blood', 'Barter in Blood', 'be856a7f6d029bfa5be0bfe07f7915d7', 'battle_rule_v1:4dc466c70a22a941f04f26618e8a6ee1', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarterInBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack the earth', 'Crack the Earth', '08446934f7df33a207467fb5b627fa50', 'battle_rule_v1:d2aa51841d87625e029e0c1d78119c0b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackTheEarth translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('innocent blood', 'Innocent Blood', '936b01368e4684556867764af9ce37c5', 'battle_rule_v1:e36e942e876596fa39c2abef5eac238f', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnocentBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('renounce the guilds', 'Renounce the Guilds', '3127e90fe826e0d6097996f889d848b9', 'battle_rule_v1:172ceadc506f12be79de7edc8edc647b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_requires_multicolored":true,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RenounceTheGuilds translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('simplify', 'Simplify', '3e5ca27a1aaa76ffa9aa0c13d1689aa5', 'battle_rule_v1:8d62f54198483e3e3deeec43de124cd5', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["enchantment"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Simplify translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tergrid''s shadow', 'Tergrid''s Shadow', '5a7e33d8e6b36112f4c1ac58776c8e12', 'battle_rule_v1:d2088319b0a6c4d1bd660dfc024c73e6', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TergridsShadow translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tremble', 'Tremble', 'e3d97dc178a6579b3b6f279e42e225db', 'battle_rule_v1:4aec324ab24ccc2a1adfe7a07131cf98', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tremble translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('barter in blood', 'Barter in Blood', 'be856a7f6d029bfa5be0bfe07f7915d7', 'battle_rule_v1:4dc466c70a22a941f04f26618e8a6ee1', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarterInBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack the earth', 'Crack the Earth', '08446934f7df33a207467fb5b627fa50', 'battle_rule_v1:d2aa51841d87625e029e0c1d78119c0b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackTheEarth translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('innocent blood', 'Innocent Blood', '936b01368e4684556867764af9ce37c5', 'battle_rule_v1:e36e942e876596fa39c2abef5eac238f', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnocentBlood translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('renounce the guilds', 'Renounce the Guilds', '3127e90fe826e0d6097996f889d848b9', 'battle_rule_v1:172ceadc506f12be79de7edc8edc647b', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["permanent"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_requires_multicolored":true,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RenounceTheGuilds translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('simplify', 'Simplify', '3e5ca27a1aaa76ffa9aa0c13d1689aa5', 'battle_rule_v1:8d62f54198483e3e3deeec43de124cd5', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["enchantment"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Simplify translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tergrid''s shadow', 'Tergrid''s Shadow', '5a7e33d8e6b36112f4c1ac58776c8e12', 'battle_rule_v1:d2088319b0a6c4d1bd660dfc024c73e6', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":true,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":false,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TergridsShadow translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tremble', 'Tremble', 'e3d97dc178a6579b3b6f279e42e225db', 'battle_rule_v1:4aec324ab24ccc2a1adfe7a07131cf98', '{"battle_model_scope":"xmage_each_player_sacrifice_fixed_permanents_spell_v1","effect":"each_player_sacrifice","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":true,"xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"each_player_sacrifice"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tremble translated into ManaLoom runtime scope xmage_each_player_sacrifice_fixed_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
