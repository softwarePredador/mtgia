BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('basalt ravager', 'explosive prodigy', 'firefist adept', 'gruesome scourger', 'kessig malcontents', 'outrage shaman', 'thundering sparkmage', 'volley veteran')
   OR normalized_name LIKE 'basalt ravager // %'
   OR normalized_name LIKE 'explosive prodigy // %'
   OR normalized_name LIKE 'firefist adept // %'
   OR normalized_name LIKE 'gruesome scourger // %'
   OR normalized_name LIKE 'kessig malcontents // %'
   OR normalized_name LIKE 'outrage shaman // %'
   OR normalized_name LIKE 'thundering sparkmage // %'
   OR normalized_name LIKE 'volley veteran // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg510_xmage_pg510_etb_dynamic_count_dama_20260705_141441;

COMMIT;
