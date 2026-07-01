BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('clay revenant', 'durable coilbug', 'firewing phoenix', 'jungle creeper', 'merchant of many hats', 'sanitarium skeleton')
   OR normalized_name LIKE 'clay revenant // %'
   OR normalized_name LIKE 'durable coilbug // %'
   OR normalized_name LIKE 'firewing phoenix // %'
   OR normalized_name LIKE 'jungle creeper // %'
   OR normalized_name LIKE 'merchant of many hats // %'
   OR normalized_name LIKE 'sanitarium skeleton // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg319_xmage_graveyard_self_return_wave_20260701_170519;

COMMIT;
