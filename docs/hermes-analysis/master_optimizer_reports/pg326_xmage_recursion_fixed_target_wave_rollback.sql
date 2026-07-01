BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boggart birth rite', 'death''s duet', 'reborn hope', 'revive')
   OR normalized_name LIKE 'boggart birth rite // %'
   OR normalized_name LIKE 'death''s duet // %'
   OR normalized_name LIKE 'reborn hope // %'
   OR normalized_name LIKE 'revive // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg326_xmage_recursion_fixed_target_wave_20260701_195645;

COMMIT;
