BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bazaar trademage', 'bellowing crier', 'elite instructor', 'icewind elemental', 'merfolk traders', 'owl familiar', 'quicksilver fisher', 'screeching drake', 'sky-eel school', 'temur tawnyback', 'vodalian merchant')
   OR normalized_name LIKE 'bazaar trademage // %'
   OR normalized_name LIKE 'bellowing crier // %'
   OR normalized_name LIKE 'elite instructor // %'
   OR normalized_name LIKE 'icewind elemental // %'
   OR normalized_name LIKE 'merfolk traders // %'
   OR normalized_name LIKE 'owl familiar // %'
   OR normalized_name LIKE 'quicksilver fisher // %'
   OR normalized_name LIKE 'screeching drake // %'
   OR normalized_name LIKE 'sky-eel school // %'
   OR normalized_name LIKE 'temur tawnyback // %'
   OR normalized_name LIKE 'vodalian merchant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg609_etb_draw_discard_new_server_20260707_102827;

COMMIT;
