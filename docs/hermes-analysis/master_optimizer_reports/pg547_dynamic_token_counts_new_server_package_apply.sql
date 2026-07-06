BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg547_dynamic_token_counts_new_server_dy_20260706_033924 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('crash the party', 'deploy to the front', 'fungal sprouting', 'goblin gathering', 'howl of the night pack')
   OR normalized_name LIKE 'crash the party // %'
   OR normalized_name LIKE 'deploy to the front // %'
   OR normalized_name LIKE 'fungal sprouting // %'
   OR normalized_name LIKE 'goblin gathering // %'
   OR normalized_name LIKE 'howl of the night pack // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crash the party', 'Crash the Party', 'fcc5c9091e8dc516fbe887bb09d4369f', 'battle_rule_v1:5617d2a4db40a81168145b32a933e9ec', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_tapped_creatures","token_description":"4/4 green Rhino Warrior creature token","token_name":"Rhino Warrior Token","token_power":4,"token_subtype":"Rhino Warrior","token_tapped":true,"token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RhinoWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrashTheParty translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deploy to the front', 'Deploy to the Front', '4179614d05de27ce72bb3a55659ef40b', 'battle_rule_v1:7db95ac0624f990faca2a4a8d4e864de', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"all_creatures_on_battlefield","token_description":"1/1 white Soldier creature token","token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeployToTheFront translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fungal sprouting', 'Fungal Sprouting', '2a5a44d545d22c40ad1cf5f1b330d152', 'battle_rule_v1:f3a6a30cc5e2bd3ed129bcfbd9084bf2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"greatest_power_among_controlled_creatures","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FungalSprouting translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin gathering', 'Goblin Gathering', '6986d05a3b7a31a80d433ad992684d3f', 'battle_rule_v1:a0c433cb3bf28fab494fe04f4e10f96b', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["R"],"token_count_base":2,"token_count_card_name":"Goblin Gathering","token_count_source":"named_cards_in_controller_graveyard_plus_base","token_description":"1/1 red Goblin creature token","token_name":"Goblin Token","token_power":1,"token_subtype":"Goblin","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GoblinToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGathering translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('howl of the night pack', 'Howl of the Night Pack', '6890aca1767d2d1b23b90713ae03e1a2', 'battle_rule_v1:f075c7e5b6bb551a0f217eba3bf6ac63', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Forest","token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HowlOfTheNightPack translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('crash the party', 'Crash the Party', 'fcc5c9091e8dc516fbe887bb09d4369f', 'battle_rule_v1:5617d2a4db40a81168145b32a933e9ec', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_tapped_creatures","token_description":"4/4 green Rhino Warrior creature token","token_name":"Rhino Warrior Token","token_power":4,"token_subtype":"Rhino Warrior","token_tapped":true,"token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RhinoWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrashTheParty translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deploy to the front', 'Deploy to the Front', '4179614d05de27ce72bb3a55659ef40b', 'battle_rule_v1:7db95ac0624f990faca2a4a8d4e864de', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"all_creatures_on_battlefield","token_description":"1/1 white Soldier creature token","token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeployToTheFront translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fungal sprouting', 'Fungal Sprouting', '2a5a44d545d22c40ad1cf5f1b330d152', 'battle_rule_v1:f3a6a30cc5e2bd3ed129bcfbd9084bf2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"greatest_power_among_controlled_creatures","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FungalSprouting translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin gathering', 'Goblin Gathering', '6986d05a3b7a31a80d433ad992684d3f', 'battle_rule_v1:a0c433cb3bf28fab494fe04f4e10f96b', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["R"],"token_count_base":2,"token_count_card_name":"Goblin Gathering","token_count_source":"named_cards_in_controller_graveyard_plus_base","token_description":"1/1 red Goblin creature token","token_name":"Goblin Token","token_power":1,"token_subtype":"Goblin","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GoblinToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGathering translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('howl of the night pack', 'Howl of the Night Pack', '6890aca1767d2d1b23b90713ae03e1a2', 'battle_rule_v1:f075c7e5b6bb551a0f217eba3bf6ac63', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Forest","token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HowlOfTheNightPack translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('crash the party', 'Crash the Party', 'fcc5c9091e8dc516fbe887bb09d4369f', 'battle_rule_v1:5617d2a4db40a81168145b32a933e9ec', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_tapped_creatures","token_description":"4/4 green Rhino Warrior creature token","token_name":"Rhino Warrior Token","token_power":4,"token_subtype":"Rhino Warrior","token_tapped":true,"token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RhinoWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrashTheParty translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deploy to the front', 'Deploy to the Front', '4179614d05de27ce72bb3a55659ef40b', 'battle_rule_v1:7db95ac0624f990faca2a4a8d4e864de', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_source":"all_creatures_on_battlefield","token_description":"1/1 white Soldier creature token","token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeployToTheFront translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fungal sprouting', 'Fungal Sprouting', '2a5a44d545d22c40ad1cf5f1b330d152', 'battle_rule_v1:f3a6a30cc5e2bd3ed129bcfbd9084bf2', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"greatest_power_among_controlled_creatures","token_description":"1/1 green Saproling creature token","token_name":"Saproling Token","token_power":1,"token_subtype":"Saproling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FungalSprouting translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin gathering', 'Goblin Gathering', '6986d05a3b7a31a80d433ad992684d3f', 'battle_rule_v1:a0c433cb3bf28fab494fe04f4e10f96b', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["R"],"token_count_base":2,"token_count_card_name":"Goblin Gathering","token_count_source":"named_cards_in_controller_graveyard_plus_base","token_description":"1/1 red Goblin creature token","token_name":"Goblin Token","token_power":1,"token_subtype":"Goblin","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GoblinToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGathering translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('howl of the night pack', 'Howl of the Night Pack', '6890aca1767d2d1b23b90713ae03e1a2', 'battle_rule_v1:f075c7e5b6bb551a0f217eba3bf6ac63', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Forest","token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HowlOfTheNightPack translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
