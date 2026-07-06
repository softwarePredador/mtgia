BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eternal student', 'illustrious historian')
   OR normalized_name LIKE 'eternal student // %'
   OR normalized_name LIKE 'illustrious historian // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg543_graveyard_self_exile_token_new_ser_20260706_022127;

COMMIT;
