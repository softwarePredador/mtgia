BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aid the fallen', 'fortuitous find', 'grim discovery', 'remember the fallen', 'reviving melody', 'season of renewal', 'survivors'' bond')
   OR normalized_name LIKE 'aid the fallen // %'
   OR normalized_name LIKE 'fortuitous find // %'
   OR normalized_name LIKE 'grim discovery // %'
   OR normalized_name LIKE 'remember the fallen // %'
   OR normalized_name LIKE 'reviving melody // %'
   OR normalized_name LIKE 'season of renewal // %'
   OR normalized_name LIKE 'survivors'' bond // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg327_xmage_recursion_choose_one_or_both_wave_20260701_2;

COMMIT;
