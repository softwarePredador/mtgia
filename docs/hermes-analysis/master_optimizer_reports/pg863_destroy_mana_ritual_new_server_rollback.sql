BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deconstruct', 'liturgy of blood', 'seismic spike', 'turn to dust')
   OR normalized_name LIKE 'deconstruct // %'
   OR normalized_name LIKE 'liturgy of blood // %'
   OR normalized_name LIKE 'seismic spike // %'
   OR normalized_name LIKE 'turn to dust // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg863_destroy_mana_ritual_new_server_20260713_043302;

COMMIT;
