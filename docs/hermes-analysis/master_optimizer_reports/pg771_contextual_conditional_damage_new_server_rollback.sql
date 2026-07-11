BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('firecannon blast', 'frost bite', 'galvanize', 'invasive maneuvers')
   OR normalized_name LIKE 'firecannon blast // %'
   OR normalized_name LIKE 'frost bite // %'
   OR normalized_name LIKE 'galvanize // %'
   OR normalized_name LIKE 'invasive maneuvers // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg771_contextual_conditional_damage_new_20260711_155411;

COMMIT;
