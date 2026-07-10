BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg720_token_variable_arg_new_server_toke_20260710_203259 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ant queen', 'broodmate dragon', 'roc egg', 'sprouting thrinax')
   OR normalized_name LIKE 'ant queen // %'
   OR normalized_name LIKE 'broodmate dragon // %'
   OR normalized_name LIKE 'roc egg // %'
   OR normalized_name LIKE 'sprouting thrinax // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ant queen', 'Ant Queen', '53a7ae4dd6f6a5ef1c68b5fe980dd44b', 'battle_rule_v1:6c6a795001e21e4f389c32adde4533d0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AntQueen translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('broodmate dragon', 'Broodmate Dragon', '423b550b931b4696b2288ce547c32449', 'battle_rule_v1:4063c079795837e8b94c581cf24ee0a8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["R"],"etb_token_count":1,"etb_token_flying":true,"etb_token_keywords":["flying"],"etb_token_name":"Dragon Token","etb_token_power":4,"etb_token_subtype":"Dragon","etb_token_toughness":4,"flying":true,"keywords":["flying"],"token_description":"4/4 red Dragon creature token with flying","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DragonToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BroodmateDragon translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roc egg', 'Roc Egg', 'c35bfc0f113c1ee5e7539b5d813aec4f', 'battle_rule_v1:5385b7d23648efeaf502bff68b2a7f0b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","defender":true,"dies_token_colors":["W"],"dies_token_count":1,"dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Bird Token","dies_token_power":3,"dies_token_subtype":"Bird","dies_token_toughness":3,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["defender"],"token_description":"3/3 white Bird creature token with flying","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RocEggToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RocEgg translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sprouting thrinax', 'Sprouting Thrinax', 'ea0c06cc0ad372bf9d662623bfc90f2a', 'battle_rule_v1:302fae4cf3a57e7203c835da45e5b69c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":3,"dies_token_name":"Saproling Token","dies_token_power":1,"dies_token_subtype":"Saproling","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Saproling creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SproutingThrinax translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ant queen', 'Ant Queen', '53a7ae4dd6f6a5ef1c68b5fe980dd44b', 'battle_rule_v1:6c6a795001e21e4f389c32adde4533d0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AntQueen translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('broodmate dragon', 'Broodmate Dragon', '423b550b931b4696b2288ce547c32449', 'battle_rule_v1:4063c079795837e8b94c581cf24ee0a8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["R"],"etb_token_count":1,"etb_token_flying":true,"etb_token_keywords":["flying"],"etb_token_name":"Dragon Token","etb_token_power":4,"etb_token_subtype":"Dragon","etb_token_toughness":4,"flying":true,"keywords":["flying"],"token_description":"4/4 red Dragon creature token with flying","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DragonToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BroodmateDragon translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roc egg', 'Roc Egg', 'c35bfc0f113c1ee5e7539b5d813aec4f', 'battle_rule_v1:5385b7d23648efeaf502bff68b2a7f0b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","defender":true,"dies_token_colors":["W"],"dies_token_count":1,"dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Bird Token","dies_token_power":3,"dies_token_subtype":"Bird","dies_token_toughness":3,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["defender"],"token_description":"3/3 white Bird creature token with flying","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RocEggToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RocEgg translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sprouting thrinax', 'Sprouting Thrinax', 'ea0c06cc0ad372bf9d662623bfc90f2a', 'battle_rule_v1:302fae4cf3a57e7203c835da45e5b69c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":3,"dies_token_name":"Saproling Token","dies_token_power":1,"dies_token_subtype":"Saproling","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Saproling creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SproutingThrinax translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ant queen', 'Ant Queen', '53a7ae4dd6f6a5ef1c68b5fe980dd44b', 'battle_rule_v1:6c6a795001e21e4f389c32adde4533d0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AntQueen translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('broodmate dragon', 'Broodmate Dragon', '423b550b931b4696b2288ce547c32449', 'battle_rule_v1:4063c079795837e8b94c581cf24ee0a8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["R"],"etb_token_count":1,"etb_token_flying":true,"etb_token_keywords":["flying"],"etb_token_name":"Dragon Token","etb_token_power":4,"etb_token_subtype":"Dragon","etb_token_toughness":4,"flying":true,"keywords":["flying"],"token_description":"4/4 red Dragon creature token with flying","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DragonToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BroodmateDragon translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roc egg', 'Roc Egg', 'c35bfc0f113c1ee5e7539b5d813aec4f', 'battle_rule_v1:5385b7d23648efeaf502bff68b2a7f0b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","defender":true,"dies_token_colors":["W"],"dies_token_count":1,"dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Bird Token","dies_token_power":3,"dies_token_subtype":"Bird","dies_token_toughness":3,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["defender"],"token_description":"3/3 white Bird creature token with flying","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RocEggToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RocEgg translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sprouting thrinax', 'Sprouting Thrinax', 'ea0c06cc0ad372bf9d662623bfc90f2a', 'battle_rule_v1:302fae4cf3a57e7203c835da45e5b69c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":3,"dies_token_name":"Saproling Token","dies_token_power":1,"dies_token_subtype":"Saproling","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Saproling creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SproutingThrinax translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
