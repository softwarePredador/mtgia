BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aberrant return', 'evil reawakened', 'unbreakable bond')
   OR normalized_name LIKE 'aberrant return // %'
   OR normalized_name LIKE 'evil reawakened // %'
   OR normalized_name LIKE 'unbreakable bond // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg335_xmage_battlefield_counter_recursion_wave_20260701_;

COMMIT;
