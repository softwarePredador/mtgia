BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aerial predation', 'dark offering', 'eriette''s lullaby', 'lucky offering', 'noxious grasp', 'poison arrow', 'radiant strike', 'silverstrike', 'surge of righteousness', 'triumphant surge')
   OR normalized_name LIKE 'aerial predation // %'
   OR normalized_name LIKE 'dark offering // %'
   OR normalized_name LIKE 'eriette''s lullaby // %'
   OR normalized_name LIKE 'lucky offering // %'
   OR normalized_name LIKE 'noxious grasp // %'
   OR normalized_name LIKE 'poison arrow // %'
   OR normalized_name LIKE 'radiant strike // %'
   OR normalized_name LIKE 'silverstrike // %'
   OR normalized_name LIKE 'surge of righteousness // %'
   OR normalized_name LIKE 'triumphant surge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg608_destroy_gain_life_target_variants_20260707_100806;

COMMIT;
