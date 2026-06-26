BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bedlam reveler')
   OR normalized_name LIKE 'bedlam reveler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg226_bedlam_reveler_exact_scope_20260626_051643;

COMMIT;
