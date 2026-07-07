BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blightsoil druid', 'blood celebrant', 'phyrexian lens', 'standing stones', 'vesper ghoul')
   OR normalized_name LIKE 'blightsoil druid // %'
   OR normalized_name LIKE 'blood celebrant // %'
   OR normalized_name LIKE 'phyrexian lens // %'
   OR normalized_name LIKE 'standing stones // %'
   OR normalized_name LIKE 'vesper ghoul // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg597_pay_life_mana_source_new_server_20260707_060115;

COMMIT;
