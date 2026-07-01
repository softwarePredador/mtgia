BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bottle gnomes', 'braidwood cup', 'brindle boar', 'dedicated martyr', 'font of vigor', 'fountain of youth', 'marble chalice', 'silent attendant', 'soulmender', 'starlight invoker', 'stone haven medic', 'tanglebloom', 'tower of eons', 'zarichi tiger')
   OR normalized_name LIKE 'bottle gnomes // %'
   OR normalized_name LIKE 'braidwood cup // %'
   OR normalized_name LIKE 'brindle boar // %'
   OR normalized_name LIKE 'dedicated martyr // %'
   OR normalized_name LIKE 'font of vigor // %'
   OR normalized_name LIKE 'fountain of youth // %'
   OR normalized_name LIKE 'marble chalice // %'
   OR normalized_name LIKE 'silent attendant // %'
   OR normalized_name LIKE 'soulmender // %'
   OR normalized_name LIKE 'starlight invoker // %'
   OR normalized_name LIKE 'stone haven medic // %'
   OR normalized_name LIKE 'tanglebloom // %'
   OR normalized_name LIKE 'tower of eons // %'
   OR normalized_name LIKE 'zarichi tiger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg320_xmage_permanent_activated_life_gain_wave_20260701_;

COMMIT;
