\pset pager off
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SELECT pg_advisory_xact_lock(hashtext('validation_identity_residue_cleanup_20260714'));

DO $$
DECLARE
  v_users integer;
  v_decks integer;
  v_deck_cards integer;
  v_telemetry integer;
BEGIN
  IF to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_users') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_decks') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_activation') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences') IS NULL
     OR to_regclass('manaloom_deploy_audit.validation_identity_cleanup_20260714_plans') IS NULL THEN
    RAISE EXCEPTION 'rollback backup is incomplete';
  END IF;

  SELECT count(*) INTO v_users FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users;
  SELECT count(*) INTO v_decks FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks;
  SELECT count(*) INTO v_deck_cards FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards;
  SELECT count(*) INTO v_telemetry FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry;

  IF (v_users, v_decks, v_deck_cards, v_telemetry) <> (3, 640, 37963, 62) THEN
    RAISE EXCEPTION
      'rollback backup counts invalid: users=%, decks=%, deck_cards=%, telemetry=%',
      v_users, v_decks, v_deck_cards, v_telemetry;
  END IF;
END $$;

INSERT INTO users
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_users;

INSERT INTO decks
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_decks;

INSERT INTO deck_cards
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_deck_cards;

INSERT INTO ai_optimize_fallback_telemetry
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_telemetry;

INSERT INTO activation_funnel_events
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_activation;

INSERT INTO ai_user_preferences
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_preferences;

INSERT INTO user_plans
SELECT * FROM manaloom_deploy_audit.validation_identity_cleanup_20260714_plans;

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
      v_activation, v_preferences, v_plans) <> (3, 640, 37963, 62, 1, 2, 3) THEN
    RAISE EXCEPTION
      'rollback postcheck failed: users=%, decks=%, deck_cards=%, telemetry=%, activation=%, preferences=%, plans=%',
      v_users, v_decks, v_deck_cards, v_telemetry,
      v_activation, v_preferences, v_plans;
  END IF;
END $$;

COMMIT;
