BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('tortured existence', 'undertaker')
   OR normalized_name LIKE 'tortured existence // %'
   OR normalized_name LIKE 'undertaker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg353_xmage_permanent_activated_graveyard_to_hand_discar;

COMMIT;
