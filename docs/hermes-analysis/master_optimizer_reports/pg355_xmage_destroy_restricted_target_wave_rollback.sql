BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bramblecrush', 'crush', 'dark banishing', 'dark betrayal', 'deathmark', 'exorcist', 'go for the throat', 'hero''s demise', 'joven', 'saltblast', 'terror // terror', 'ultimate price')
   OR normalized_name LIKE 'bramblecrush // %'
   OR normalized_name LIKE 'crush // %'
   OR normalized_name LIKE 'dark banishing // %'
   OR normalized_name LIKE 'dark betrayal // %'
   OR normalized_name LIKE 'deathmark // %'
   OR normalized_name LIKE 'exorcist // %'
   OR normalized_name LIKE 'go for the throat // %'
   OR normalized_name LIKE 'hero''s demise // %'
   OR normalized_name LIKE 'joven // %'
   OR normalized_name LIKE 'saltblast // %'
   OR normalized_name LIKE 'terror // terror // %'
   OR normalized_name LIKE 'ultimate price // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg355_xmage_destroy_restricted_target_wave_20260702_0541;

COMMIT;
