BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('contentious plan', 'steady progress', 'tezzeret''s gambit', 'vivisurgeon''s insight')
   OR normalized_name LIKE 'contentious plan // %'
   OR normalized_name LIKE 'steady progress // %'
   OR normalized_name LIKE 'tezzeret''s gambit // %'
   OR normalized_name LIKE 'vivisurgeon''s insight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg675_proliferate_draw_new_server_prolif_20260708_223712;

COMMIT;
