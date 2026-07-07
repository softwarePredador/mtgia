BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blaster mage', 'devout witness', 'notorious assassin', 'seismic mage')
   OR normalized_name LIKE 'blaster mage // %'
   OR normalized_name LIKE 'devout witness // %'
   OR normalized_name LIKE 'notorious assassin // %'
   OR normalized_name LIKE 'seismic mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg627_activated_destroy_discard_cost_new_20260707_172132;

COMMIT;
