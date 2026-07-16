-- Generated read-only audit package: 2026-07-15T21:10:43.191808+00:00
-- Targets: 396 exact UUIDs; expected deck_cards rows: 4774.
-- This file is preparation, not PostgreSQL write authorization.
\set ON_ERROR_STOP on

BEGIN;
SET TRANSACTION READ ONLY;
SET LOCAL TIME ZONE 'UTC';

DO $postcheck$
BEGIN
  IF TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest') IS NULL
     OR TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup') IS NULL
     OR TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup') IS NULL THEN
    RAISE EXCEPTION 'cleanup audit/backup tables are missing';
  END IF;
  IF (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest) <> 396
     OR (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup) <> 396
     OR (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup) <> 4774 THEN
    RAISE EXCEPTION 'manifest or backup count mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM public.decks d JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = d.id)
     OR EXISTS (SELECT 1 FROM public.deck_cards dc JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = dc.deck_id) THEN
    RAISE EXCEPTION 'one or more cleanup targets still exist';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m
    JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup b ON b.id = m.deck_id
    WHERE MD5(ROW_TO_JSON(b)::text) IS DISTINCT FROM m.expected_deck_row_md5
  ) THEN
    RAISE EXCEPTION 'backup identity drift detected';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m
    WHERE (SELECT MD5(COALESCE(STRING_AGG(
      CONCAT_WS(E'\x1f', b.id::text, b.deck_id::text,
        COALESCE(b.card_id::text, '<NULL>'),
        COALESCE(b.quantity::text, '<NULL>'),
        COALESCE(b.is_commander::text, '<NULL>'),
        COALESCE(b.condition, '<NULL>')),
      E'\x1e' ORDER BY b.id), ''))
      FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup b WHERE b.deck_id = m.deck_id)
      IS DISTINCT FROM m.expected_deck_cards_md5
  ) THEN
    RAISE EXCEPTION 'backup deck_cards identity drift detected';
  END IF;
END
$postcheck$;

SELECT
  (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest) AS manifest_decks,
  (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup) AS backed_up_decks,
  (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup) AS backed_up_deck_cards,
  (SELECT COUNT(*) FROM public.decks d JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = d.id)
    AS remaining_target_decks;
COMMIT;
