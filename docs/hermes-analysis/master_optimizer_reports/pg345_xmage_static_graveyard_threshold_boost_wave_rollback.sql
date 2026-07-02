BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anurid barkripper', 'basking capybara', 'frilled cave-wurm', 'krosan beast', 'metamorphic wurm', 'seton''s scout', 'springing tiger')
   OR normalized_name LIKE 'anurid barkripper // %'
   OR normalized_name LIKE 'basking capybara // %'
   OR normalized_name LIKE 'frilled cave-wurm // %'
   OR normalized_name LIKE 'krosan beast // %'
   OR normalized_name LIKE 'metamorphic wurm // %'
   OR normalized_name LIKE 'seton''s scout // %'
   OR normalized_name LIKE 'springing tiger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg345_xmage_static_graveyard_threshold_boost_wave_202607;

COMMIT;
