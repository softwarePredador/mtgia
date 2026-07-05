BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg503_xmage_creature_etb_fixed_mana_new_20260705_114030 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('akki rockspeaker', 'burning-tree emissary', 'priest of gix', 'priest of urabrask')
   OR normalized_name LIKE 'akki rockspeaker // %'
   OR normalized_name LIKE 'burning-tree emissary // %'
   OR normalized_name LIKE 'priest of gix // %'
   OR normalized_name LIKE 'priest of urabrask // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('akki rockspeaker', 'Akki Rockspeaker', '2c1c6bf2eb1ec865d84ff82c4f54029f', 'battle_rule_v1:03d10668e241154656a14f9ac5949550', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":1,"etb_produced_mana_symbols":["R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkkiRockspeaker translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('burning-tree emissary', 'Burning-Tree Emissary', 'e48292b20c3297f830d2490664f3be82', 'battle_rule_v1:26c40d0b0bdd51355b5247591324af4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":2,"etb_produced_mana_symbols":["R","G"],"etb_produces":"RG","instant":false,"is_mana_source":false,"mana_produced":2,"permanent_type":"creature","produced_mana_symbols":["R","G"],"produces":"RG","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurningTreeEmissary translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of gix', 'Priest of Gix', '53270f2d1fd5d1d54f791d3b097b3138', 'battle_rule_v1:2d3e4b8f02be6791b9d9707558b0ccd6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["B","B","B"],"etb_produces":"B","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfGix translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of urabrask', 'Priest of Urabrask', '473d8c63d1fcef29a0a4a634f4f6c847', 'battle_rule_v1:e98b5dbd90254c3b996852a344bcfc08', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["R","R","R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfUrabrask translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akki rockspeaker', 'Akki Rockspeaker', '2c1c6bf2eb1ec865d84ff82c4f54029f', 'battle_rule_v1:03d10668e241154656a14f9ac5949550', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":1,"etb_produced_mana_symbols":["R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkkiRockspeaker translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('burning-tree emissary', 'Burning-Tree Emissary', 'e48292b20c3297f830d2490664f3be82', 'battle_rule_v1:26c40d0b0bdd51355b5247591324af4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":2,"etb_produced_mana_symbols":["R","G"],"etb_produces":"RG","instant":false,"is_mana_source":false,"mana_produced":2,"permanent_type":"creature","produced_mana_symbols":["R","G"],"produces":"RG","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurningTreeEmissary translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of gix', 'Priest of Gix', '53270f2d1fd5d1d54f791d3b097b3138', 'battle_rule_v1:2d3e4b8f02be6791b9d9707558b0ccd6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["B","B","B"],"etb_produces":"B","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfGix translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of urabrask', 'Priest of Urabrask', '473d8c63d1fcef29a0a4a634f4f6c847', 'battle_rule_v1:e98b5dbd90254c3b996852a344bcfc08', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["R","R","R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfUrabrask translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('akki rockspeaker', 'Akki Rockspeaker', '2c1c6bf2eb1ec865d84ff82c4f54029f', 'battle_rule_v1:03d10668e241154656a14f9ac5949550', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":1,"etb_produced_mana_symbols":["R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkkiRockspeaker translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('burning-tree emissary', 'Burning-Tree Emissary', 'e48292b20c3297f830d2490664f3be82', 'battle_rule_v1:26c40d0b0bdd51355b5247591324af4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":2,"etb_produced_mana_symbols":["R","G"],"etb_produces":"RG","instant":false,"is_mana_source":false,"mana_produced":2,"permanent_type":"creature","produced_mana_symbols":["R","G"],"produces":"RG","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurningTreeEmissary translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of gix', 'Priest of Gix', '53270f2d1fd5d1d54f791d3b097b3138', 'battle_rule_v1:2d3e4b8f02be6791b9d9707558b0ccd6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["B","B","B"],"etb_produces":"B","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfGix translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of urabrask', 'Priest of Urabrask', '473d8c63d1fcef29a0a4a634f4f6c847', 'battle_rule_v1:e98b5dbd90254c3b996852a344bcfc08', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_fixed_mana_v1","effect":"ramp_permanent","etb_mana_produced":3,"etb_produced_mana_symbols":["R","R","R"],"etb_produces":"R","instant":false,"is_mana_source":false,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"add_mana","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BasicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfUrabrask translated into ManaLoom runtime scope xmage_creature_etb_add_fixed_mana_v1. This row is package-ready only because the source signature is a narrow creature with fixed enter-the-battlefield mana trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
