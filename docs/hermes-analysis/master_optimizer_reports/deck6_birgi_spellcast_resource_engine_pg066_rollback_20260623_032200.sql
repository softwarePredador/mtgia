-- PG066 deck6 Birgi spell-cast resource engine rollback.
-- Restores pre-PG066 card_battle_rules rows from the durable backup table.

BEGIN;

DELETE FROM card_battle_rules
WHERE normalized_name = 'birgi, god of storytelling // harnfel, horn of bounty';

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg066_deck6_birgi_spellcast_resource_engine_20260623_032200;

COMMIT;
