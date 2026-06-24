BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('sol ring', 'izzet signet', 'simic signet')
   OR normalized_name LIKE 'sol ring // %'
   OR normalized_name LIKE 'izzet signet // %'
   OR normalized_name LIKE 'simic signet // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg154_simple_artifact_mana_rocks_20260624_081824;

COMMIT;
