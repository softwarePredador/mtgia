BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('elves of deep shadow', 'talisman of curiosity', 'tarnished citadel')
   OR normalized_name LIKE 'elves of deep shadow // %'
   OR normalized_name LIKE 'talisman of curiosity // %'
   OR normalized_name LIKE 'tarnished citadel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg176_damage_controller_pain_sources_20260624_131434;

COMMIT;
