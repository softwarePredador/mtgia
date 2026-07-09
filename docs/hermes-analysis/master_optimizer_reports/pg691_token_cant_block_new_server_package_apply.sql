BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg691_token_cant_block_20260709_045133 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('edgewall pack', 'harried spearguard', 'synapse necromage')
   OR normalized_name LIKE 'edgewall pack // %'
   OR normalized_name LIKE 'harried spearguard // %'
   OR normalized_name LIKE 'synapse necromage // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('edgewall pack', 'Edgewall Pack', '271b1e8e3df78b7c426c23200d186581', 'battle_rule_v1:a100e3f3b59c8767819cc6f271052d61', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_cant_block":true,"etb_token_colors":["B"],"etb_token_count":1,"etb_token_name":"Rat Token","etb_token_power":1,"etb_token_static_restrictions":["cant_block"],"etb_token_subtype":"Rat","etb_token_toughness":1,"keywords":["menace"],"menace":true,"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EdgewallPack translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harried spearguard', 'Harried Spearguard', '12922d50039c146f4833110dfadb40de', 'battle_rule_v1:21fecc381b6135d9c2987a722d9a5868', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":1,"dies_token_name":"Rat Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Rat","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","haste":true,"keywords":["haste"],"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarriedSpearguard translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('synapse necromage', 'Synapse Necromage', 'dc9f36a669ef827fa3dcd3e941c556a6', 'battle_rule_v1:115a25934705a57f0c1d3b500ab00765', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":2,"dies_token_name":"Fungus Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Fungus","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 black Fungus creature token with \"This creature can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"FungusCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SynapseNecromage translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('edgewall pack', 'Edgewall Pack', '271b1e8e3df78b7c426c23200d186581', 'battle_rule_v1:a100e3f3b59c8767819cc6f271052d61', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_cant_block":true,"etb_token_colors":["B"],"etb_token_count":1,"etb_token_name":"Rat Token","etb_token_power":1,"etb_token_static_restrictions":["cant_block"],"etb_token_subtype":"Rat","etb_token_toughness":1,"keywords":["menace"],"menace":true,"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EdgewallPack translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harried spearguard', 'Harried Spearguard', '12922d50039c146f4833110dfadb40de', 'battle_rule_v1:21fecc381b6135d9c2987a722d9a5868', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":1,"dies_token_name":"Rat Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Rat","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","haste":true,"keywords":["haste"],"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarriedSpearguard translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('synapse necromage', 'Synapse Necromage', 'dc9f36a669ef827fa3dcd3e941c556a6', 'battle_rule_v1:115a25934705a57f0c1d3b500ab00765', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":2,"dies_token_name":"Fungus Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Fungus","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 black Fungus creature token with \"This creature can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"FungusCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SynapseNecromage translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('edgewall pack', 'Edgewall Pack', '271b1e8e3df78b7c426c23200d186581', 'battle_rule_v1:a100e3f3b59c8767819cc6f271052d61', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_cant_block":true,"etb_token_colors":["B"],"etb_token_count":1,"etb_token_name":"Rat Token","etb_token_power":1,"etb_token_static_restrictions":["cant_block"],"etb_token_subtype":"Rat","etb_token_toughness":1,"keywords":["menace"],"menace":true,"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EdgewallPack translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harried spearguard', 'Harried Spearguard', '12922d50039c146f4833110dfadb40de', 'battle_rule_v1:21fecc381b6135d9c2987a722d9a5868', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":1,"dies_token_name":"Rat Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Rat","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","haste":true,"keywords":["haste"],"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarriedSpearguard translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('synapse necromage', 'Synapse Necromage', 'dc9f36a669ef827fa3dcd3e941c556a6', 'battle_rule_v1:115a25934705a57f0c1d3b500ab00765', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":2,"dies_token_name":"Fungus Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Fungus","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 black Fungus creature token with \"This creature can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"FungusCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SynapseNecromage translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
