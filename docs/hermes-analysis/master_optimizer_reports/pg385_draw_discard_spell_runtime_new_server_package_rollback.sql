BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ancestral reminiscence', 'careful study', 'catalog', 'enhanced awareness', 'prying eyes', 'rain of revelation', 'romantic rendezvous', 'sift', 'thoughtflare')
   OR normalized_name LIKE 'ancestral reminiscence // %'
   OR normalized_name LIKE 'careful study // %'
   OR normalized_name LIKE 'catalog // %'
   OR normalized_name LIKE 'enhanced awareness // %'
   OR normalized_name LIKE 'prying eyes // %'
   OR normalized_name LIKE 'rain of revelation // %'
   OR normalized_name LIKE 'romantic rendezvous // %'
   OR normalized_name LIKE 'sift // %'
   OR normalized_name LIKE 'thoughtflare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg385_draw_discard_spell_runtime_new_server_20260704_051;

COMMIT;
