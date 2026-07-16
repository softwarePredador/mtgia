-- Generated read-only audit package: 2026-07-15T21:10:43.191808+00:00
-- Targets: 396 exact UUIDs; expected deck_cards rows: 4774.
-- This file is preparation, not PostgreSQL write authorization.
\set ON_ERROR_STOP on

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET LOCAL TIME ZONE 'UTC';
LOCK TABLE public.decks IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.deck_cards IN SHARE ROW EXCLUSIVE MODE;

DO $rollback_precheck$
BEGIN
  IF TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest') IS NULL
     OR TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup') IS NULL
     OR TO_REGCLASS('manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup') IS NULL THEN
    RAISE EXCEPTION 'rollback backup tables are missing';
  END IF;
  IF (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest) <> 396
     OR (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup) <> 396
     OR (SELECT COUNT(*) FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup) <> 4774 THEN
    RAISE EXCEPTION 'rollback backup counts do not match package manifest';
  END IF;
  IF EXISTS (SELECT 1 FROM public.decks d JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = d.id)
     OR EXISTS (SELECT 1 FROM public.deck_cards dc JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = dc.deck_id) THEN
    RAISE EXCEPTION 'target UUIDs already exist; refusing non-idempotent rollback';
  END IF;
  IF EXISTS (
    SELECT 1 FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup b
    LEFT JOIN public.users u ON u.id = b.user_id
    WHERE b.user_id IS NOT NULL AND u.id IS NULL
  ) THEN
    RAISE EXCEPTION 'one or more original owner users no longer exist';
  END IF;
  IF EXISTS (
    SELECT 1 FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup b
    LEFT JOIN public.cards c ON c.id = b.card_id
    WHERE b.card_id IS NOT NULL AND c.id IS NULL
  ) THEN
    RAISE EXCEPTION 'one or more original card rows no longer exist';
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
    RAISE EXCEPTION 'rollback deck_cards backup identity mismatch';
  END IF;
END
$rollback_precheck$;

INSERT INTO public.decks (id, user_id, name, format, description, is_public, synergy_score, strengths, weaknesses, created_at, deleted_at, archetype, bracket, pricing_currency, pricing_total, pricing_missing_cards, pricing_updated_at)
SELECT id, user_id, name, format, description, is_public, synergy_score, strengths, weaknesses, created_at, deleted_at, archetype, bracket, pricing_currency, pricing_total, pricing_missing_cards, pricing_updated_at FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_decks_backup;

INSERT INTO public.deck_cards (id, deck_id, card_id, quantity, is_commander, condition)
SELECT id, deck_id, card_id, quantity, is_commander, condition FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_deck_cards_backup;

DO $rollback_postcheck$
BEGIN
  IF (SELECT COUNT(*) FROM public.decks d JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = d.id)
     <> 396 THEN
    RAISE EXCEPTION 'rollback deck count mismatch';
  END IF;
  IF (SELECT COUNT(*) FROM public.deck_cards dc JOIN manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m ON m.deck_id = dc.deck_id)
     <> 4774 THEN
    RAISE EXCEPTION 'rollback deck_cards count mismatch';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m
    JOIN public.decks d ON d.id = m.deck_id
    WHERE MD5(ROW_TO_JSON(d)::text) IS DISTINCT FROM m.expected_deck_row_md5
  ) THEN
    RAISE EXCEPTION 'rollback identity hash mismatch';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.global_commander_fixture_cleanup_20260715_manifest m
    WHERE (SELECT MD5(COALESCE(STRING_AGG(
      CONCAT_WS(E'\x1f', dc.id::text, dc.deck_id::text,
        COALESCE(dc.card_id::text, '<NULL>'),
        COALESCE(dc.quantity::text, '<NULL>'),
        COALESCE(dc.is_commander::text, '<NULL>'),
        COALESCE(dc.condition, '<NULL>')),
      E'\x1e' ORDER BY dc.id), ''))
      FROM public.deck_cards dc WHERE dc.deck_id = m.deck_id)
      IS DISTINCT FROM m.expected_deck_cards_md5
  ) THEN
    RAISE EXCEPTION 'rollback deck_cards identity hash mismatch';
  END IF;
END
$rollback_postcheck$;

COMMIT;
