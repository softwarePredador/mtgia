BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg659_special_equip_cost_new_server_20260708_140658 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bloodthorn flail', 'demonmail hauberk', 'murderer''s axe')
   OR normalized_name LIKE 'bloodthorn flail // %'
   OR normalized_name LIKE 'demonmail hauberk // %'
   OR normalized_name LIKE 'murderer''s axe // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bloodthorn flail', 'Bloodthorn Flail', 'bb46b9b658a80f3d5eec51abf0dfb33a', 'battle_rule_v1:e1578e231f7cb23a2c4211fa2e08e51c', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodthornFlail translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demonmail hauberk', 'Demonmail Hauberk', '1f08deeab2c0475c0f80d8e4cc826355', 'battle_rule_v1:a501e1c0f5726aaf4689af5eacd7774a', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":4,"sorcery":false,"static_power_bonus":4,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonmailHauberk translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderer''s axe', 'Murderer''s Axe', '894f1d5c9adf8542002730887be9850d', 'battle_rule_v1:d207c85ffb0121236b7c49f49361f2aa', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderersAxe translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bloodthorn flail', 'Bloodthorn Flail', 'bb46b9b658a80f3d5eec51abf0dfb33a', 'battle_rule_v1:e1578e231f7cb23a2c4211fa2e08e51c', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodthornFlail translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demonmail hauberk', 'Demonmail Hauberk', '1f08deeab2c0475c0f80d8e4cc826355', 'battle_rule_v1:a501e1c0f5726aaf4689af5eacd7774a', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":4,"sorcery":false,"static_power_bonus":4,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonmailHauberk translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderer''s axe', 'Murderer''s Axe', '894f1d5c9adf8542002730887be9850d', 'battle_rule_v1:d207c85ffb0121236b7c49f49361f2aa', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderersAxe translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bloodthorn flail', 'Bloodthorn Flail', 'bb46b9b658a80f3d5eec51abf0dfb33a', 'battle_rule_v1:e1578e231f7cb23a2c4211fa2e08e51c', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":1,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":1,"xmage_ability_classes":["EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodthornFlail translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demonmail hauberk', 'Demonmail Hauberk', '1f08deeab2c0475c0f80d8e4cc826355', 'battle_rule_v1:a501e1c0f5726aaf4689af5eacd7774a', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":4,"sorcery":false,"static_power_bonus":4,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonmailHauberk translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('murderer''s axe', 'Murderer''s Axe', '894f1d5c9adf8542002730887be9850d', 'battle_rule_v1:d207c85ffb0121236b7c49f49361f2aa', '{"ability_kind":"equipment_static","attached_keywords":[],"battle_model_scope":"xmage_equipment_static_power_toughness_attachment_v1","effect":"equipment_static_attachment","equipment":true,"instant":false,"power_boost":2,"sorcery":false,"static_power_bonus":2,"static_toughness_bonus":2,"target":"creature_you_control","target_constraints":{"card_types":["creature"],"controller":"self","zone":"battlefield"},"toughness_boost":2,"xmage_ability_classes":["AddAbility","EquipAbility","SimpleStaticAbility"],"xmage_effect_classes":["BoostEquippedEffect"]}'::jsonb, '{"category":"support","effect":"equipment_static_attachment","subtype":"equipment_static_pump","target":"creature_you_control"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MurderersAxe translated into ManaLoom runtime scope xmage_equipment_static_power_toughness_attachment_v1. This row is package-ready only because the source signature is a narrow fixed Equipment attachment with static equipped-creature power/toughness and keyword modifier with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
