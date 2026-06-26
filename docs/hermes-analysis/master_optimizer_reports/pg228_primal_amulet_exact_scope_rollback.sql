BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('primal amulet // primal wellspring')
   OR normalized_name LIKE 'primal amulet // primal wellspring // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg228_primal_amulet_exact_scope_20260626_061537;

COMMIT;
