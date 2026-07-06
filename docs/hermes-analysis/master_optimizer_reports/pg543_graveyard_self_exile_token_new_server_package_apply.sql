BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg543_graveyard_self_exile_token_new_ser_20260706_022127 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('eternal student', 'illustrious historian')
   OR normalized_name LIKE 'eternal student // %'
   OR normalized_name LIKE 'illustrious historian // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eternal student', 'Eternal Student', '5d0d28b33adc1da99013cace22fa94e3', 'battle_rule_v1:14a6c4f3e3b0ff2645919f71c042b467', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalStudent translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('illustrious historian', 'Illustrious Historian', 'fa81074d782e0d0677343f5b38ee6ce4', 'battle_rule_v1:c1687c5ca0cc72d415cd8e171f2436e0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IllustriousHistorian translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eternal student', 'Eternal Student', '5d0d28b33adc1da99013cace22fa94e3', 'battle_rule_v1:14a6c4f3e3b0ff2645919f71c042b467', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalStudent translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('illustrious historian', 'Illustrious Historian', 'fa81074d782e0d0677343f5b38ee6ce4', 'battle_rule_v1:c1687c5ca0cc72d415cd8e171f2436e0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IllustriousHistorian translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eternal student', 'Eternal Student', '5d0d28b33adc1da99013cace22fa94e3', 'battle_rule_v1:14a6c4f3e3b0ff2645919f71c042b467', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalStudent translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('illustrious historian', 'Illustrious Historian', 'fa81074d782e0d0677343f5b38ee6ce4', 'battle_rule_v1:c1687c5ca0cc72d415cd8e171f2436e0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IllustriousHistorian translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
