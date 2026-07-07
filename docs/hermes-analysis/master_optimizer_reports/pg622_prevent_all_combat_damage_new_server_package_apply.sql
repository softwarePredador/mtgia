BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg622_prevent_all_combat_damage_new_serv_20260707_152050 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('angelsong', 'darkness', 'haze of pollen', 'holy day', 'lull', 'root snare')
   OR normalized_name LIKE 'angelsong // %'
   OR normalized_name LIKE 'darkness // %'
   OR normalized_name LIKE 'haze of pollen // %'
   OR normalized_name LIKE 'holy day // %'
   OR normalized_name LIKE 'lull // %'
   OR normalized_name LIKE 'root snare // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelsong', 'Angelsong', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Angelsong translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkness', 'Darkness', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Darkness translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('haze of pollen', 'Haze of Pollen', '48694a840ec24a39385551b915aee836', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HazeOfPollen translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('holy day', 'Holy Day', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HolyDay translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lull', 'Lull', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Lull translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('root snare', 'Root Snare', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RootSnare translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angelsong', 'Angelsong', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Angelsong translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkness', 'Darkness', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Darkness translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('haze of pollen', 'Haze of Pollen', '48694a840ec24a39385551b915aee836', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HazeOfPollen translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('holy day', 'Holy Day', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HolyDay translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lull', 'Lull', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Lull translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('root snare', 'Root Snare', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RootSnare translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('angelsong', 'Angelsong', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Angelsong translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkness', 'Darkness', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Darkness translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('haze of pollen', 'Haze of Pollen', '48694a840ec24a39385551b915aee836', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HazeOfPollen translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('holy day', 'Holy Day', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HolyDay translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lull', 'Lull', '41207c49996c4ac386e7dcd0821a24ec', 'battle_rule_v1:0ec0e4134d1272b446e1deaab61e2b8f', '{"_cycling_is_auxiliary":true,"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","has_cycling":true,"instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":["CyclingAbility"],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Lull translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('root snare', 'Root Snare', 'ed128f5a827bf1670b8f9e8657506aca', 'battle_rule_v1:46c32a90131f7b4e260f45cd83226e08', '{"battle_model_scope":"xmage_prevent_all_combat_damage_spell_v1","duration":"until_end_of_turn","effect":"damage_prevention_shield","instant":true,"prevent_all_combat_damage_this_turn":true,"prevent_damage_amount":999,"prevent_damage_duration":"until_end_of_turn","prevent_damage_scope":"all_combat_damage","sorcery":false,"xmage_ability_classes":[],"xmage_effect_class":"PreventAllDamageByAllPermanentsEffect"}'::jsonb, '{"category":"protection","effect":"damage_prevention_shield","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RootSnare translated into ManaLoom runtime scope xmage_prevent_all_combat_damage_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution prevention of all combat damage until end of turn with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
