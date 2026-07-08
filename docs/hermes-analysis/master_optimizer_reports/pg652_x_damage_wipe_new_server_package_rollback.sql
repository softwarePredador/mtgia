BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('corrosive gale', 'savage twister', 'windstorm')
   OR normalized_name LIKE 'corrosive gale // %'
   OR normalized_name LIKE 'savage twister // %'
   OR normalized_name LIKE 'windstorm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg652_x_damage_wipe_new_server_20260708_012434;

COMMIT;
