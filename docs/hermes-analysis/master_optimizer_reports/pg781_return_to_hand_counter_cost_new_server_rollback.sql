BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('disappearing act', 'familiar''s ruse')
   OR normalized_name LIKE 'disappearing act // %'
   OR normalized_name LIKE 'familiar''s ruse // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg781_pg781_return_to_hand_counter_cost_20260711_184736;

COMMIT;
