BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dangerous wager')
   OR normalized_name LIKE 'dangerous wager // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg837_discard_hand_draw_new_server_20260712_183941;

COMMIT;
