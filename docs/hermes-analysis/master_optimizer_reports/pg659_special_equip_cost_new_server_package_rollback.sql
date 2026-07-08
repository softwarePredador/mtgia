BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloodthorn flail', 'demonmail hauberk', 'murderer''s axe')
   OR normalized_name LIKE 'bloodthorn flail // %'
   OR normalized_name LIKE 'demonmail hauberk // %'
   OR normalized_name LIKE 'murderer''s axe // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg659_special_equip_cost_new_server_20260708_140658;

COMMIT;
