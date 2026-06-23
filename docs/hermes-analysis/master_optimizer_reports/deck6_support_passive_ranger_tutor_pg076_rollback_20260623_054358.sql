BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358 is missing';
  END IF;
END $$;

DELETE FROM card_battle_rules cbr
USING manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358 b
WHERE cbr.normalized_name = b.normalized_name
  AND cbr.logical_rule_key = b.logical_rule_key;

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358;

COMMIT;
