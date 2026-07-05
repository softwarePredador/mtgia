BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('implements of sacrifice', 'wild cantor')
   OR normalized_name LIKE 'implements of sacrifice // %'
   OR normalized_name LIKE 'wild cantor // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg523_self_sacrifice_mana_new_serv_20260705_184510;

COMMIT;
