BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('absorb', 'fall of the gavel')
   OR normalized_name LIKE 'absorb // %'
   OR normalized_name LIKE 'fall of the gavel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg519_counter_gain_life_new_server_20260705_172315;

COMMIT;
