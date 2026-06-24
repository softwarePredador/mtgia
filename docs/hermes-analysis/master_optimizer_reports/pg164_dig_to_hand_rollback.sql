BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ancestral memories', 'scattered thoughts')
   OR normalized_name LIKE 'ancestral memories // %'
   OR normalized_name LIKE 'scattered thoughts // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg164_dig_to_hand_20260624_103413;

COMMIT;
