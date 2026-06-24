BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('perch protection', 'sand scout')
   OR normalized_name LIKE 'perch protection // %'
   OR normalized_name LIKE 'sand scout // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg192_perch_sand_token_creature_20260624_221536;

COMMIT;
