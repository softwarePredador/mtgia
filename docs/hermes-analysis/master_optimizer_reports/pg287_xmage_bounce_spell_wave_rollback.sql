BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boomerang', 'disperse', 'drown in shapelessness', 'eye of nowhere', 'regress', 'unsummon', 'void snare')
   OR normalized_name LIKE 'boomerang // %'
   OR normalized_name LIKE 'disperse // %'
   OR normalized_name LIKE 'drown in shapelessness // %'
   OR normalized_name LIKE 'eye of nowhere // %'
   OR normalized_name LIKE 'regress // %'
   OR normalized_name LIKE 'unsummon // %'
   OR normalized_name LIKE 'void snare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg287_xmage_bounce_spell_wave_20260701_081902;

COMMIT;
