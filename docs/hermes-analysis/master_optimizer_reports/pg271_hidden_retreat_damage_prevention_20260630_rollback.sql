BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hidden retreat')
   OR normalized_name LIKE 'hidden retreat // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg271_hidden_retreat_damage_prevention_20260630_20260630;

COMMIT;
