BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('reckless handling', 'demonic counsel', 'scour for scrap', 'summoner''s pact', 'cloud of faeries', 'grinding station')
   OR normalized_name LIKE 'reckless handling // %'
   OR normalized_name LIKE 'demonic counsel // %'
   OR normalized_name LIKE 'scour for scrap // %'
   OR normalized_name LIKE 'summoner''s pact // %'
   OR normalized_name LIKE 'cloud of faeries // %'
   OR normalized_name LIKE 'grinding station // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg258_candidate_template_runtime_promotions_20260629_164;

COMMIT;
