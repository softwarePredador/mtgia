BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blaze', 'heat ray', 'volcanic geyser')
   OR normalized_name LIKE 'blaze // %'
   OR normalized_name LIKE 'heat ray // %'
   OR normalized_name LIKE 'volcanic geyser // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg476_xmage_x_damage_spell_new_server_20260705_025856;

COMMIT;
