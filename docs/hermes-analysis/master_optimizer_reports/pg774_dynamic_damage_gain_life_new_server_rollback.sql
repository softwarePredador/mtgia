BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('consuming corruption', 'death grasp', 'harsh sustenance', 'swallowing plague', 'tendrils of corruption')
   OR normalized_name LIKE 'consuming corruption // %'
   OR normalized_name LIKE 'death grasp // %'
   OR normalized_name LIKE 'harsh sustenance // %'
   OR normalized_name LIKE 'swallowing plague // %'
   OR normalized_name LIKE 'tendrils of corruption // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg774_dynamic_damage_gain_life_new_serve_20260711_164958;

COMMIT;
