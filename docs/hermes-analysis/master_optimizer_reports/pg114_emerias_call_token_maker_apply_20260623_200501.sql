BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg114_emerias_call_token_maker_20260623_200501 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'emeria''s call // emeria, shattered skyclave';

DO $$
DECLARE
  v_matched_rows integer;
BEGIN
  SELECT count(c.id)
    INTO v_matched_rows
  FROM public.cards c
  WHERE lower(c.name) = 'emeria''s call // emeria, shattered skyclave'
    AND md5(coalesce(c.oracle_text, '')) = '2fab1a2b9eb87041bc9e93f3b8d52831';

  IF v_matched_rows <> 1 THEN
    RAISE EXCEPTION 'PG114 abort: expected exactly one Oracle-hash-matched Emeria card row, got %', v_matched_rows;
  END IF;
END $$;

WITH deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG114: deprecated stale shadow before Oracle/XMage-backed Emeria token-maker rule was promoted.'
    )
  WHERE r.normalized_name = 'emeria''s call // emeria, shattered skyclave'
    AND r.logical_rule_key <> 'battle_rule_v1:ae4a933d873bec332ec2a46106b79277'
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows
FROM deprecated;

WITH target_card AS (
  SELECT id, name
  FROM public.cards
  WHERE lower(name) = 'emeria''s call // emeria, shattered skyclave'
    AND md5(coalesce(oracle_text, '')) = '2fab1a2b9eb87041bc9e93f3b8d52831'
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
    'emeria''s call // emeria, shattered skyclave',
    tc.id,
    tc.name,
    '{
      "ability_kind":"one_shot",
      "battle_model_scope":"create_two_4_4_flying_angel_warrior_tokens_non_angel_indestructible_until_next_turn_v1",
      "cmc":7.0,
      "effect":"token_maker",
      "token_count":2,
      "token_name":"Angel Warrior Token",
      "token_subtype":"Angel Warrior",
      "token_colors":["W"],
      "token_power":4,
      "token_toughness":4,
      "token_flying":true,
      "grant_non_angel_creatures_indestructible_until_next_turn":true,
      "protection_filter":"non_angel_creatures_you_control",
      "protection_duration":"until_your_next_turn"
    }'::jsonb,
    '{"category":"board_development","effect":"token_maker","subtype":"angel_token_protection","timing":"sorcery"}'::jsonb,
    'curated',
    0.96,
    'verified',
    2,
    '2fab1a2b9eb87041bc9e93f3b8d52831',
    'PG114: Oracle/XMage-backed Emeria''s Call rule. Runtime creates two 4/4 white Angel Warrior flying tokens and grants indestructible until the source controller''s next turn only to non-Angel creatures controlled by that player.',
    'codex-pg114',
    now(),
    now(),
    now(),
    now(),
    'battle_rule_v1:ae4a933d873bec332ec2a46106b79277',
    'auto'
  FROM target_card tc
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
SELECT count(*) AS upserted_rows
FROM upserted;

COMMIT;
