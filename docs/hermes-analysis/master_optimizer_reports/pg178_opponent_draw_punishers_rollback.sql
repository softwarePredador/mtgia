BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fate unraveler', 'underworld dreams')
   OR normalized_name LIKE 'fate unraveler // %'
   OR normalized_name LIKE 'underworld dreams // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg178_opponent_draw_punishers_20260624_134852;

COMMIT;
