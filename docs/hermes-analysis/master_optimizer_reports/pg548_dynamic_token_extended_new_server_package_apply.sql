BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg548_dynamic_token_extended_new_server_20260706_040441 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('flurry of wings', 'ordered migration', 'rise from the tides', 'spontaneous generation', 'spore burst')
   OR normalized_name LIKE 'flurry of wings // %'
   OR normalized_name LIKE 'ordered migration // %'
   OR normalized_name LIKE 'rise from the tides // %'
   OR normalized_name LIKE 'spontaneous generation // %'
   OR normalized_name LIKE 'spore burst // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('flurry of wings', 'Flurry of Wings', '72f8eaf4e66233d8fee70bdc89b0d9e8', 'battle_rule_v1:a91caec6e84e9d586a9840e0c3b920f2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"attacking_creatures","token_description":"1/1 white Bird Soldier creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Soldier Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BirdSoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlurryOfWings translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ordered migration', 'Ordered Migration', '1b5c3336a9ee95c0a884e68cefd3125b', 'battle_rule_v1:86ed16a7f8dfea78058cc7433c03045c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["U"],"token_count_source":"domain_basic_land_types","token_description":"1/1 blue Bird creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BlueBirdToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrderedMigration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise from the tides', 'Rise from the Tides', '5c3cc3549eb1d78a63802563e6421d4d', 'battle_rule_v1:8702d53c8c4cd31c2e292abb579597fe', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["B"],"token_count_source":"controller_graveyard_instant_sorcery_count","token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_tapped":true,"token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheTides translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spontaneous generation', 'Spontaneous Generation', '46e11b6dffc19a0d146cf67ef7478f98', 'battle_rule_v1:47e922b3dd61e1f57d31c4518423fcd5', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controller_hand_count","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpontaneousGeneration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spore burst', 'Spore Burst', 'a2b75ca550ba7fa0f34e5d925329a95f', 'battle_rule_v1:ae6d8c0ab8584b64df647dc87a0fb320', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"domain_basic_land_types","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SporeBurst translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('flurry of wings', 'Flurry of Wings', '72f8eaf4e66233d8fee70bdc89b0d9e8', 'battle_rule_v1:a91caec6e84e9d586a9840e0c3b920f2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"attacking_creatures","token_description":"1/1 white Bird Soldier creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Soldier Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BirdSoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlurryOfWings translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ordered migration', 'Ordered Migration', '1b5c3336a9ee95c0a884e68cefd3125b', 'battle_rule_v1:86ed16a7f8dfea78058cc7433c03045c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["U"],"token_count_source":"domain_basic_land_types","token_description":"1/1 blue Bird creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BlueBirdToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrderedMigration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise from the tides', 'Rise from the Tides', '5c3cc3549eb1d78a63802563e6421d4d', 'battle_rule_v1:8702d53c8c4cd31c2e292abb579597fe', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["B"],"token_count_source":"controller_graveyard_instant_sorcery_count","token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_tapped":true,"token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheTides translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spontaneous generation', 'Spontaneous Generation', '46e11b6dffc19a0d146cf67ef7478f98', 'battle_rule_v1:47e922b3dd61e1f57d31c4518423fcd5', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controller_hand_count","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpontaneousGeneration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spore burst', 'Spore Burst', 'a2b75ca550ba7fa0f34e5d925329a95f', 'battle_rule_v1:ae6d8c0ab8584b64df647dc87a0fb320', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"domain_basic_land_types","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SporeBurst translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('flurry of wings', 'Flurry of Wings', '72f8eaf4e66233d8fee70bdc89b0d9e8', 'battle_rule_v1:a91caec6e84e9d586a9840e0c3b920f2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"attacking_creatures","token_description":"1/1 white Bird Soldier creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Soldier Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BirdSoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlurryOfWings translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ordered migration', 'Ordered Migration', '1b5c3336a9ee95c0a884e68cefd3125b', 'battle_rule_v1:86ed16a7f8dfea78058cc7433c03045c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["U"],"token_count_source":"domain_basic_land_types","token_description":"1/1 blue Bird creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Bird Token","token_power":1,"token_subtype":"Bird","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BlueBirdToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrderedMigration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rise from the tides', 'Rise from the Tides', '5c3cc3549eb1d78a63802563e6421d4d', 'battle_rule_v1:8702d53c8c4cd31c2e292abb579597fe', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["B"],"token_count_source":"controller_graveyard_instant_sorcery_count","token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_tapped":true,"token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiseFromTheTides translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spontaneous generation', 'Spontaneous Generation', '46e11b6dffc19a0d146cf67ef7478f98', 'battle_rule_v1:47e922b3dd61e1f57d31c4518423fcd5', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controller_hand_count","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpontaneousGeneration translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spore burst', 'Spore Burst', 'a2b75ca550ba7fa0f34e5d925329a95f', 'battle_rule_v1:ae6d8c0ab8584b64df647dc87a0fb320', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"domain_basic_land_types","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SporeBurst translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
