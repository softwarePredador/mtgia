BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('knuckles the echidna')
   OR normalized_name LIKE 'knuckles the echidna // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg144_knuckles_combat_treasure_20260624_052524;

COMMIT;
