BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dual shot', 'furious reprisal', 'jagged lightning', 'pinnacle of rage', 'storm of steel', 'swelter')
   OR normalized_name LIKE 'dual shot // %'
   OR normalized_name LIKE 'furious reprisal // %'
   OR normalized_name LIKE 'jagged lightning // %'
   OR normalized_name LIKE 'pinnacle of rage // %'
   OR normalized_name LIKE 'storm of steel // %'
   OR normalized_name LIKE 'swelter // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg669_damage_each_target_20260708_191811;

COMMIT;
