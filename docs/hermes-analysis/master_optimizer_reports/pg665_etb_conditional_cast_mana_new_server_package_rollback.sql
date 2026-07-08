BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('coal stoker', 'iridescent tiger')
   OR normalized_name LIKE 'coal stoker // %'
   OR normalized_name LIKE 'iridescent tiger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg665_etb_conditional_cast_mana_new_serv_20260708_173414;

COMMIT;
