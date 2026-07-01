BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('alchemist''s apprentice', 'arcane encyclopedia', 'archivist', 'azure mage', 'benalish heralds', 'brass secretary', 'courier''s capsule', 'eidolon of philosophy', 'font of fortunes', 'jayemdae tome', 'mystic archaeologist', 'oscorp research team', 'scepter of insight', 'shore keeper', 'third path savant', 'tower of fortunes', 'treasure trove', 'tymora''s invoker')
   OR normalized_name LIKE 'alchemist''s apprentice // %'
   OR normalized_name LIKE 'arcane encyclopedia // %'
   OR normalized_name LIKE 'archivist // %'
   OR normalized_name LIKE 'azure mage // %'
   OR normalized_name LIKE 'benalish heralds // %'
   OR normalized_name LIKE 'brass secretary // %'
   OR normalized_name LIKE 'courier''s capsule // %'
   OR normalized_name LIKE 'eidolon of philosophy // %'
   OR normalized_name LIKE 'font of fortunes // %'
   OR normalized_name LIKE 'jayemdae tome // %'
   OR normalized_name LIKE 'mystic archaeologist // %'
   OR normalized_name LIKE 'oscorp research team // %'
   OR normalized_name LIKE 'scepter of insight // %'
   OR normalized_name LIKE 'shore keeper // %'
   OR normalized_name LIKE 'third path savant // %'
   OR normalized_name LIKE 'tower of fortunes // %'
   OR normalized_name LIKE 'treasure trove // %'
   OR normalized_name LIKE 'tymora''s invoker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg309_xmage_permanent_activated_draw_wave_20260701_13561;

COMMIT;
