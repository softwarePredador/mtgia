BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg337_xmage_etb_graveyard_to_library_wave_pg337_xmage_et AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dukhara scavenger', 'meldweb curator')
   OR normalized_name LIKE 'dukhara scavenger // %'
   OR normalized_name LIKE 'meldweb curator // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dukhara scavenger', 'Dukhara Scavenger', '5aa0fc1f83928ece835da7974b31b899', 'battle_rule_v1:aff86b7a250d8bcea98713b8ab9e81f4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"artifact_or_creature","library_controller":"self","target_constraints":{"card_types":["artifact","creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DukharaScavenger translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('meldweb curator', 'Meldweb Curator', 'a0955a787ec1b1c7b6f17f2cf63d860b', 'battle_rule_v1:0a4eab7f075f8c25bd6e8cd872aa4dbe', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"library_controller":"self","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MeldwebCurator translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dukhara scavenger', 'Dukhara Scavenger', '5aa0fc1f83928ece835da7974b31b899', 'battle_rule_v1:aff86b7a250d8bcea98713b8ab9e81f4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"artifact_or_creature","library_controller":"self","target_constraints":{"card_types":["artifact","creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DukharaScavenger translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('meldweb curator', 'Meldweb Curator', 'a0955a787ec1b1c7b6f17f2cf63d860b', 'battle_rule_v1:0a4eab7f075f8c25bd6e8cd872aa4dbe', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"library_controller":"self","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MeldwebCurator translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dukhara scavenger', 'Dukhara Scavenger', '5aa0fc1f83928ece835da7974b31b899', 'battle_rule_v1:aff86b7a250d8bcea98713b8ab9e81f4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"artifact_or_creature","library_controller":"self","target_constraints":{"card_types":["artifact","creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DukharaScavenger translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('meldweb curator', 'Meldweb Curator', 'a0955a787ec1b1c7b6f17f2cf63d860b', 'battle_rule_v1:0a4eab7f075f8c25bd6e8cd872aa4dbe', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"library_controller":"self","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MeldwebCurator translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
