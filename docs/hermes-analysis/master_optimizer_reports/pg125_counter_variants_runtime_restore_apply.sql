BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg125_counter_variants_runtime_restore_20260623_235642 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('pact of negation', 'swan song', 'an offer you can''t refuse', 'refute', 'wizard''s retort');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pact of negation', 'Pact of Negation', '262a21c885bcc509fa438d4ba3ead7d8', 'battle_rule_v1:395f96ea9a7b45f017ebef88b456663b', '{"ability_kind":"one_shot","battle_model_scope":"pact_of_negation_delayed_upkeep_counter_v1","delayed_upkeep_mana_payment":"{3}{U}{U}","effect":"counter_spell","instant":true,"lose_game_if_unpaid":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PactOfNegation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swan song', 'Swan Song', 'f31d32e77db92d33647a4424c52ade5d', 'battle_rule_v1:9e1a27e7c6c194ebfab6c500503665a6', '{"ability_kind":"one_shot","battle_model_scope":"counter_enchantment_instant_sorcery_spell_target_controller_bird_v1","effect":"counter_spell","instant":true,"target":"enchantment_instant_or_sorcery_spell","target_controller_creates_token":{"colors":["U"],"count":1,"keywords":["flying"],"name":"Bird","power":2,"toughness":2}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwanSong mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('an offer you can''t refuse', 'An Offer You Can''t Refuse', 'fd5c2cd66bcbe90bb2d072f0146d67b3', 'battle_rule_v1:eafa496b9179d9cbd3350b078d13f17e', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_target_controller_treasure_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","target_controller_creates_treasure":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AnOfferYouCantRefuse mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('refute', 'Refute', '08a27b0252c823f1a0d6532701925010', 'battle_rule_v1:41a3506a6969888f362a122077db87cb', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_draw_then_discard_v1","draw_then_discard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Refute mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wizard''s retort', 'Wizard''s Retort', 'ff5f40a24723d9dbc7424b86099c51b1', 'battle_rule_v1:642383d239e504a8da473caca3b05597', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_costs_one_less_if_control_wizard_v1","cost_reduction_generic_if_control_wizard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WizardsRetort mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
      ON lower(c.name) = p.normalized_name
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pact of negation', 'Pact of Negation', '262a21c885bcc509fa438d4ba3ead7d8', 'battle_rule_v1:395f96ea9a7b45f017ebef88b456663b', '{"ability_kind":"one_shot","battle_model_scope":"pact_of_negation_delayed_upkeep_counter_v1","delayed_upkeep_mana_payment":"{3}{U}{U}","effect":"counter_spell","instant":true,"lose_game_if_unpaid":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PactOfNegation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swan song', 'Swan Song', 'f31d32e77db92d33647a4424c52ade5d', 'battle_rule_v1:9e1a27e7c6c194ebfab6c500503665a6', '{"ability_kind":"one_shot","battle_model_scope":"counter_enchantment_instant_sorcery_spell_target_controller_bird_v1","effect":"counter_spell","instant":true,"target":"enchantment_instant_or_sorcery_spell","target_controller_creates_token":{"colors":["U"],"count":1,"keywords":["flying"],"name":"Bird","power":2,"toughness":2}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwanSong mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('an offer you can''t refuse', 'An Offer You Can''t Refuse', 'fd5c2cd66bcbe90bb2d072f0146d67b3', 'battle_rule_v1:eafa496b9179d9cbd3350b078d13f17e', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_target_controller_treasure_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","target_controller_creates_treasure":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AnOfferYouCantRefuse mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('refute', 'Refute', '08a27b0252c823f1a0d6532701925010', 'battle_rule_v1:41a3506a6969888f362a122077db87cb', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_draw_then_discard_v1","draw_then_discard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Refute mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wizard''s retort', 'Wizard''s Retort', 'ff5f40a24723d9dbc7424b86099c51b1', 'battle_rule_v1:642383d239e504a8da473caca3b05597', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_costs_one_less_if_control_wizard_v1","cost_reduction_generic_if_control_wizard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WizardsRetort mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pact of negation', 'Pact of Negation', '262a21c885bcc509fa438d4ba3ead7d8', 'battle_rule_v1:395f96ea9a7b45f017ebef88b456663b', '{"ability_kind":"one_shot","battle_model_scope":"pact_of_negation_delayed_upkeep_counter_v1","delayed_upkeep_mana_payment":"{3}{U}{U}","effect":"counter_spell","instant":true,"lose_game_if_unpaid":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PactOfNegation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swan song', 'Swan Song', 'f31d32e77db92d33647a4424c52ade5d', 'battle_rule_v1:9e1a27e7c6c194ebfab6c500503665a6', '{"ability_kind":"one_shot","battle_model_scope":"counter_enchantment_instant_sorcery_spell_target_controller_bird_v1","effect":"counter_spell","instant":true,"target":"enchantment_instant_or_sorcery_spell","target_controller_creates_token":{"colors":["U"],"count":1,"keywords":["flying"],"name":"Bird","power":2,"toughness":2}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwanSong mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('an offer you can''t refuse', 'An Offer You Can''t Refuse', 'fd5c2cd66bcbe90bb2d072f0146d67b3', 'battle_rule_v1:eafa496b9179d9cbd3350b078d13f17e', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_target_controller_treasure_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","target_controller_creates_treasure":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AnOfferYouCantRefuse mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('refute', 'Refute', '08a27b0252c823f1a0d6532701925010', 'battle_rule_v1:41a3506a6969888f362a122077db87cb', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_draw_then_discard_v1","draw_then_discard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Refute mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wizard''s retort', 'Wizard''s Retort', 'ff5f40a24723d9dbc7424b86099c51b1', 'battle_rule_v1:642383d239e504a8da473caca3b05597', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_costs_one_less_if_control_wizard_v1","cost_reduction_generic_if_control_wizard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WizardsRetort mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
    p.notes
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
