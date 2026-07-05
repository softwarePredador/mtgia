BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fathom fleet cutthroat', 'vraska''s finisher')
   OR normalized_name LIKE 'fathom fleet cutthroat // %'
   OR normalized_name LIKE 'vraska''s finisher // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg494_etb_destroy_damaged_this_turn_new_20260705_083727;

COMMIT;
