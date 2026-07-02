BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('junk diver')
   OR normalized_name LIKE 'junk diver // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg357_xmage_dies_recursion_keyword_fix_wave_20260702_062;

COMMIT;
