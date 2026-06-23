BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358 is missing';
  END IF;
END $$;

CREATE TEMP TABLE pg076_rollback_cards AS
SELECT DISTINCT card_id
FROM manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358;

DELETE FROM card_battle_rules cbr
USING pg076_rollback_cards t
WHERE cbr.card_id = t.card_id;

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358;

COMMIT;
