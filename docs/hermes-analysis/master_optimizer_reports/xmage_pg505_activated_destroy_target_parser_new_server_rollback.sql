BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('chandler', 'dwarven demolition team', 'dwarven miner', 'fulminator mage', 'goblin replica', 'intrepid hero', 'trench wurm')
   OR normalized_name LIKE 'chandler // %'
   OR normalized_name LIKE 'dwarven demolition team // %'
   OR normalized_name LIKE 'dwarven miner // %'
   OR normalized_name LIKE 'fulminator mage // %'
   OR normalized_name LIKE 'goblin replica // %'
   OR normalized_name LIKE 'intrepid hero // %'
   OR normalized_name LIKE 'trench wurm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg505_xmage_pg505_activated_destroy_targ_20260705_122344;

COMMIT;
