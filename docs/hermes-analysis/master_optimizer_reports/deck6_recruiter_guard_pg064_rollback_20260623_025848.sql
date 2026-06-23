-- PG064 deck6 Recruiter of the Guard rollback.
-- Restores pre-PG064 card_battle_rules rows from the durable backup table.

BEGIN;

DELETE FROM card_battle_rules
WHERE normalized_name = 'recruiter of the guard';

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg064_deck6_recruiter_guard_20260623_025848;

COMMIT;
