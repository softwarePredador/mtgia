BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ghoulcaller''s chant', 'march of the drowned', 'raise the draugr', 'return from extinction', 'unbury')
   OR normalized_name LIKE 'ghoulcaller''s chant // %'
   OR normalized_name LIKE 'march of the drowned // %'
   OR normalized_name LIKE 'raise the draugr // %'
   OR normalized_name LIKE 'return from extinction // %'
   OR normalized_name LIKE 'unbury // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg328_xmage_recursion_choose_one_wave_20260701_201656;

COMMIT;
