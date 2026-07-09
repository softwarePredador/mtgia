BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('end the festivities', 'tectonic hazard')
   OR normalized_name LIKE 'end the festivities // %'
   OR normalized_name LIKE 'tectonic hazard // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg692_damage_each_opponent_permanents_20260709_051144;

COMMIT;
