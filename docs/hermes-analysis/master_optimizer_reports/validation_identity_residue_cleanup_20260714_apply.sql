\pset pager off
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SELECT pg_advisory_xact_lock(hashtext('validation_identity_residue_cleanup_20260714'));

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
DECLARE
  v_users integer;
  v_decks integer;
  v_deck_cards integer;
  v_telemetry integer;
  v_activation integer;
  v_preferences integer;
  v_plans integer;
  v_unexpected_refs integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_users') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_decks') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_activation') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_plans') IS NOT NULL THEN
    RAISE EXCEPTION 'cleanup backup set already exists; refuse to overwrite rollback evidence';
  END IF;

  WITH target_users AS (
    SELECT id
    FROM users
    WHERE lower(email) IN (
      'optimization.validation.bot@example.com',
      'test_optimize_flow@example.com',
      'iphone15_async_19df87b0eeb@example.com'
    )
  ), target_decks AS (
    SELECT id FROM decks WHERE user_id IN (SELECT id FROM target_users)
  )
  SELECT
    (SELECT count(*) FROM target_users),
    (SELECT count(*) FROM target_decks),
    (SELECT count(*) FROM deck_cards WHERE deck_id IN (SELECT id FROM target_decks)),
    (SELECT count(*) FROM ai_optimize_fallback_telemetry
      WHERE user_id IN (SELECT id FROM target_users)
         OR deck_id IN (SELECT id FROM target_decks)),
    (SELECT count(*) FROM activation_funnel_events
      WHERE user_id IN (SELECT id FROM target_users)
         OR deck_id IN (SELECT id FROM target_decks)),
    (SELECT count(*) FROM ai_user_preferences
      WHERE user_id IN (SELECT id FROM target_users)),
    (SELECT count(*) FROM user_plans
      WHERE user_id IN (SELECT id FROM target_users))
  INTO v_users, v_decks, v_deck_cards, v_telemetry,
       v_activation, v_preferences, v_plans;

  WITH target_users AS (
    SELECT id
    FROM users
    WHERE lower(email) IN (
      'optimization.validation.bot@example.com',
      'test_optimize_flow@example.com',
      'iphone15_async_19df87b0eeb@example.com'
    )
  ), target_decks AS (
    SELECT id FROM decks WHERE user_id IN (SELECT id FROM target_users)
  )
  SELECT
    (SELECT count(*) FROM ai_generate_jobs WHERE user_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM ai_logs WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM ai_optimize_cache WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM ai_optimize_jobs WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM battle_simulations WHERE deck_a_id IN (SELECT id FROM target_decks) OR deck_b_id IN (SELECT id FROM target_decks) OR winner_deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM card_deck_profiles WHERE deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM content_reports WHERE reporter_user_id IN (SELECT id FROM target_users) OR reviewed_by IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM conversations WHERE user_a_id IN (SELECT id FROM target_users) OR user_b_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM deck_comments WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM deck_matchups WHERE deck_id IN (SELECT id FROM target_decks) OR opponent_deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM deck_weakness_reports WHERE deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM direct_messages WHERE sender_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM notifications WHERE user_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM post_game_notes WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM shared_deck_reports WHERE user_id IN (SELECT id FROM target_users) OR deck_id IN (SELECT id FROM target_decks)) +
    (SELECT count(*) FROM trade_items WHERE owner_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM trade_messages WHERE sender_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM trade_offers WHERE sender_id IN (SELECT id FROM target_users) OR receiver_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM trade_status_history WHERE changed_by IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM user_binder_items WHERE user_id IN (SELECT id FROM target_users)) +
    (SELECT count(*) FROM user_follows WHERE follower_id IN (SELECT id FROM target_users) OR following_id IN (SELECT id FROM target_users))
  INTO v_unexpected_refs;

  IF (v_users, v_decks, v_deck_cards, v_telemetry, v_activation, v_preferences, v_plans)
     <> (3, 640, 37963, 62, 1, 2, 3) THEN
    RAISE EXCEPTION
      'precheck failed: users=%, decks=%, deck_cards=%, telemetry=%, activation=%, preferences=%, plans=%',
      v_users, v_decks, v_deck_cards, v_telemetry,
      v_activation, v_preferences, v_plans;
  END IF;
  IF v_unexpected_refs <> 0 THEN
    RAISE EXCEPTION 'precheck failed: unexpected dependent rows=%', v_unexpected_refs;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_users AS
SELECT * FROM users
WHERE lower(email) IN (
  'optimization.validation.bot@example.com',
  'test_optimize_flow@example.com',
  'iphone15_async_19df87b0eeb@example.com'
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_decks AS
SELECT * FROM decks
WHERE user_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards AS
SELECT * FROM deck_cards
WHERE deck_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry AS
SELECT * FROM ai_optimize_fallback_telemetry
WHERE user_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
)
OR deck_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_activation AS
SELECT * FROM activation_funnel_events
WHERE user_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
)
OR deck_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences AS
SELECT * FROM ai_user_preferences
WHERE user_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
);

CREATE TABLE manaloom_deploy_audit.validation_identity_cleanup_20260714_plans AS
SELECT * FROM user_plans
WHERE user_id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
);

DELETE FROM ai_optimize_fallback_telemetry
WHERE id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry
);

DELETE FROM users
WHERE id IN (
  SELECT id FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
);

DO $$
DECLARE
  v_users integer;
  v_decks integer;
  v_deck_cards integer;
  v_telemetry integer;
  v_activation integer;
  v_preferences integer;
  v_plans integer;
BEGIN
  SELECT count(*) INTO v_users
  FROM users live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_users backup
    ON backup.id = live.id;
  SELECT count(*) INTO v_decks
  FROM decks live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_decks backup
    ON backup.id = live.id;
  SELECT count(*) INTO v_deck_cards
  FROM deck_cards live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards backup
    ON backup.deck_id = live.deck_id AND backup.card_id = live.card_id;
  SELECT count(*) INTO v_telemetry
  FROM ai_optimize_fallback_telemetry live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry backup
    ON backup.id = live.id;
  SELECT count(*) INTO v_activation
  FROM activation_funnel_events live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_activation backup
    ON backup.id = live.id;
  SELECT count(*) INTO v_preferences
  FROM ai_user_preferences live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences backup
    ON backup.user_id = live.user_id;
  SELECT count(*) INTO v_plans
  FROM user_plans live
  JOIN manaloom_deploy_audit.validation_identity_cleanup_20260714_plans backup
    ON backup.user_id = live.user_id;

  IF (v_users, v_decks, v_deck_cards, v_telemetry,
      v_activation, v_preferences, v_plans) <> (0, 0, 0, 0, 0, 0, 0) THEN
    RAISE EXCEPTION
      'postcheck failed: users=%, decks=%, deck_cards=%, telemetry=%, activation=%, preferences=%, plans=%',
      v_users, v_decks, v_deck_cards, v_telemetry,
      v_activation, v_preferences, v_plans;
  END IF;
END $$;

COMMIT;

SELECT 'backup_users' AS item, count(*) AS rows
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users
UNION ALL
SELECT 'backup_decks', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks
UNION ALL
SELECT 'backup_deck_cards', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards
UNION ALL
SELECT 'backup_telemetry', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry
UNION ALL
SELECT 'backup_activation', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_activation
UNION ALL
SELECT 'backup_preferences', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences
UNION ALL
SELECT 'backup_plans', count(*)
FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_plans
ORDER BY item;
