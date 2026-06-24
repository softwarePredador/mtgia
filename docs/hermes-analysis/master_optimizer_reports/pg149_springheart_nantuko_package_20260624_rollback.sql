BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('springheart nantuko')
   OR normalized_name LIKE 'springheart nantuko // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg149_springheart_nantuko_20260624_065629;

COMMIT;
