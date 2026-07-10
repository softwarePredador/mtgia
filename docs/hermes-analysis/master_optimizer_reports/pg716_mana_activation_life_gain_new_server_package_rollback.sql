BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pristine talisman')
   OR normalized_name LIKE 'pristine talisman // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg716_mana_activation_life_gain_new_serv_20260710_192227;

COMMIT;
