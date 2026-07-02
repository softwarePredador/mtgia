BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boneyard wurm', 'cantivore', 'cognivore', 'lord of extinction', 'magnivore', 'revenant', 'slag fiend', 'terravore')
   OR normalized_name LIKE 'boneyard wurm // %'
   OR normalized_name LIKE 'cantivore // %'
   OR normalized_name LIKE 'cognivore // %'
   OR normalized_name LIKE 'lord of extinction // %'
   OR normalized_name LIKE 'magnivore // %'
   OR normalized_name LIKE 'revenant // %'
   OR normalized_name LIKE 'slag fiend // %'
   OR normalized_name LIKE 'terravore // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg344_xmage_static_graveyard_count_pt_wave_20260702_0149;

COMMIT;
