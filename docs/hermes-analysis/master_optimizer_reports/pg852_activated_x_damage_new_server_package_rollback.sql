BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ballista squad', 'cinder elemental', 'pain kami')
   OR normalized_name LIKE 'ballista squad // %'
   OR normalized_name LIKE 'cinder elemental // %'
   OR normalized_name LIKE 'pain kami // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg852_activated_x_damage_new_server_20260712_235735;

COMMIT;
