BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg760_gain_control_keywords_new_server_g_20260711_121318 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('limits of solidarity', 'lose calm', 'traitorous blood', 'turn against', 'word of seizing')
   OR normalized_name LIKE 'limits of solidarity // %'
   OR normalized_name LIKE 'lose calm // %'
   OR normalized_name LIKE 'traitorous blood // %'
   OR normalized_name LIKE 'turn against // %'
   OR normalized_name LIKE 'word of seizing // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('limits of solidarity', 'Limits of Solidarity', '97d530936b58bcb36b4c9c800aefa735', 'battle_rule_v1:6ce7a3f438ef24898acb9752b339da34', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LimitsOfSolidarity translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lose calm', 'Lose Calm', '4ea4da54e2b8bde35d5191a16c619a27', 'battle_rule_v1:573432282ac3a549c0b92e63411822bf', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["menace","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","MenaceAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoseCalm translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('traitorous blood', 'Traitorous Blood', '2dc0dabd8fdfa87df086e28fa2d4cebb', 'battle_rule_v1:d74301b0270ea6b58123c825a9e9cfeb', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["trample","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","TrampleAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TraitorousBlood translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn against', 'Turn Against', 'a23a5399a4617178bbb4cc3efeaedd61', 'battle_rule_v1:58efd5d9ff4dfe4da0a6020717665c2b', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["DevoidAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnAgainst translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of seizing', 'Word of Seizing', '3dd2cd63ab90a61f0838b7dfe2a00b24', 'battle_rule_v1:39e8db668df0c8f0cdbce692d226ba4c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["SplitSecondAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfSeizing translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('limits of solidarity', 'Limits of Solidarity', '97d530936b58bcb36b4c9c800aefa735', 'battle_rule_v1:6ce7a3f438ef24898acb9752b339da34', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LimitsOfSolidarity translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lose calm', 'Lose Calm', '4ea4da54e2b8bde35d5191a16c619a27', 'battle_rule_v1:573432282ac3a549c0b92e63411822bf', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["menace","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","MenaceAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoseCalm translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('traitorous blood', 'Traitorous Blood', '2dc0dabd8fdfa87df086e28fa2d4cebb', 'battle_rule_v1:d74301b0270ea6b58123c825a9e9cfeb', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["trample","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","TrampleAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TraitorousBlood translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn against', 'Turn Against', 'a23a5399a4617178bbb4cc3efeaedd61', 'battle_rule_v1:58efd5d9ff4dfe4da0a6020717665c2b', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["DevoidAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnAgainst translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of seizing', 'Word of Seizing', '3dd2cd63ab90a61f0838b7dfe2a00b24', 'battle_rule_v1:39e8db668df0c8f0cdbce692d226ba4c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["SplitSecondAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfSeizing translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('limits of solidarity', 'Limits of Solidarity', '97d530936b58bcb36b4c9c800aefa735', 'battle_rule_v1:6ce7a3f438ef24898acb9752b339da34', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LimitsOfSolidarity translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lose calm', 'Lose Calm', '4ea4da54e2b8bde35d5191a16c619a27', 'battle_rule_v1:573432282ac3a549c0b92e63411822bf', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["menace","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","MenaceAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoseCalm translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('traitorous blood', 'Traitorous Blood', '2dc0dabd8fdfa87df086e28fa2d4cebb', 'battle_rule_v1:d74301b0270ea6b58123c825a9e9cfeb', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["trample","haste"],"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility","TrampleAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TraitorousBlood translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn against', 'Turn Against', 'a23a5399a4617178bbb4cc3efeaedd61', 'battle_rule_v1:58efd5d9ff4dfe4da0a6020717665c2b', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["DevoidAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnAgainst translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('word of seizing', 'Word of Seizing', '3dd2cd63ab90a61f0838b7dfe2a00b24', 'battle_rule_v1:39e8db668df0c8f0cdbce692d226ba4c', '{"battle_model_scope":"xmage_gain_control_untap_haste_until_eot_spell_v1","control_duration":"until_end_of_turn","duration":"until_end_of_turn","effect":"gain_control_untap_haste_until_eot","granted_keywords_until_eot":["haste"],"instant":true,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"opponents","untap_target":true,"xmage_ability_classes":["HasteAbility"],"xmage_auxiliary_ability_classes":["SplitSecondAbility"],"xmage_effect_classes":["GainAbilityTargetEffect","GainControlTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"gain_control_untap_haste_until_eot","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WordOfSeizing translated into ManaLoom runtime scope xmage_gain_control_untap_haste_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
