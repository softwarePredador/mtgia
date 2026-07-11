BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('peek', 'sorcerous sight')
   OR normalized_name LIKE 'peek // %'
   OR normalized_name LIKE 'sorcerous sight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg762_look_at_hand_draw_new_server_look_20260711_125229;

COMMIT;
