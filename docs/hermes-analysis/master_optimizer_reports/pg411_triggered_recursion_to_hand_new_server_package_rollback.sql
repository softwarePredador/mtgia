BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eternal taskmaster', 'pillardrop warden', 'the unspeakable')
   OR normalized_name LIKE 'eternal taskmaster // %'
   OR normalized_name LIKE 'pillardrop warden // %'
   OR normalized_name LIKE 'the unspeakable // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg411_triggered_recursion_to_hand_new_server_triggered_r;

COMMIT;
