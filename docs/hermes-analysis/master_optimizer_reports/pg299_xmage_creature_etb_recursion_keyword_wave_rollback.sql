BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cadaver imp', 'griffin dreamfinder', 'mnemonic wall', 'sanctum gargoyle')
   OR normalized_name LIKE 'cadaver imp // %'
   OR normalized_name LIKE 'griffin dreamfinder // %'
   OR normalized_name LIKE 'mnemonic wall // %'
   OR normalized_name LIKE 'sanctum gargoyle // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg299_xmage_creature_etb_recursion_keyword_wave_20260701;

COMMIT;
