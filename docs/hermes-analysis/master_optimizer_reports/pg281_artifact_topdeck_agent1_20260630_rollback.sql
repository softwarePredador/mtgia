BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('leyline dowser', 'orcish spy', 'prototype portal', 'pyxis of pandemonium')
   OR normalized_name LIKE 'leyline dowser // %'
   OR normalized_name LIKE 'orcish spy // %'
   OR normalized_name LIKE 'prototype portal // %'
   OR normalized_name LIKE 'pyxis of pandemonium // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg281_artifact_topdeck_agent1_20260630_20260630_133609;

COMMIT;
