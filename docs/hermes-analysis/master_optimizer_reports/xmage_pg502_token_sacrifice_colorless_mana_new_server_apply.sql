BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg502_xmage_token_sacrifice_colorless_ma_20260705_111909 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dread drone', 'emrakul''s hatcher', 'kozilek''s predator', 'nest invader', 'skittering invasion')
   OR normalized_name LIKE 'dread drone // %'
   OR normalized_name LIKE 'emrakul''s hatcher // %'
   OR normalized_name LIKE 'kozilek''s predator // %'
   OR normalized_name LIKE 'nest invader // %'
   OR normalized_name LIKE 'skittering invasion // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dread drone', 'Dread Drone', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DreadDrone translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('emrakul''s hatcher', 'Emrakul''s Hatcher', '3b806bf1df091419ed95198da66c165e', 'battle_rule_v1:ac512ef260039c67afe5cc63566955c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":3,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmrakulsHatcher translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kozilek''s predator', 'Kozilek''s Predator', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KozileksPredator translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nest invader', 'Nest Invader', 'ea31a3014a52677b8278f66792c7de2d', 'battle_rule_v1:78d896732ea9eefc2e22a28974526cd9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":1,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NestInvader translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skittering invasion', 'Skittering Invasion', '744a28ccbdcf3c2e54fcda739061d6a6', 'battle_rule_v1:e1d250018bb56e6a9c6e3fe2143e5568', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":5,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":false,"token_mana_produced":1,"token_name":"Eldrazi Spawn Token","token_power":0,"token_produced_mana_symbols":["C"],"token_produces":"C","token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Spawn","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkitteringInvasion translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dread drone', 'Dread Drone', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DreadDrone translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('emrakul''s hatcher', 'Emrakul''s Hatcher', '3b806bf1df091419ed95198da66c165e', 'battle_rule_v1:ac512ef260039c67afe5cc63566955c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":3,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmrakulsHatcher translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kozilek''s predator', 'Kozilek''s Predator', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KozileksPredator translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nest invader', 'Nest Invader', 'ea31a3014a52677b8278f66792c7de2d', 'battle_rule_v1:78d896732ea9eefc2e22a28974526cd9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":1,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NestInvader translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skittering invasion', 'Skittering Invasion', '744a28ccbdcf3c2e54fcda739061d6a6', 'battle_rule_v1:e1d250018bb56e6a9c6e3fe2143e5568', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":5,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":false,"token_mana_produced":1,"token_name":"Eldrazi Spawn Token","token_power":0,"token_produced_mana_symbols":["C"],"token_produces":"C","token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Spawn","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkitteringInvasion translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dread drone', 'Dread Drone', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DreadDrone translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('emrakul''s hatcher', 'Emrakul''s Hatcher', '3b806bf1df091419ed95198da66c165e', 'battle_rule_v1:ac512ef260039c67afe5cc63566955c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":3,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmrakulsHatcher translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kozilek''s predator', 'Kozilek''s Predator', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KozileksPredator translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nest invader', 'Nest Invader', 'ea31a3014a52677b8278f66792c7de2d', 'battle_rule_v1:78d896732ea9eefc2e22a28974526cd9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":1,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NestInvader translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skittering invasion', 'Skittering Invasion', '744a28ccbdcf3c2e54fcda739061d6a6', 'battle_rule_v1:e1d250018bb56e6a9c6e3fe2143e5568', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":5,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":false,"token_mana_produced":1,"token_name":"Eldrazi Spawn Token","token_power":0,"token_produced_mana_symbols":["C"],"token_produces":"C","token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Spawn","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkitteringInvasion translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
