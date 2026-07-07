BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('chill', 'feroz''s ban', 'geist-fueled scarecrow', 'glowrider', 'high seas', 'irini sengir', 'lodestone golem', 'sphere of resistance', 'squeeze', 'thorn of amethyst', 'vryn wingmare')
   OR normalized_name LIKE 'chill // %'
   OR normalized_name LIKE 'feroz''s ban // %'
   OR normalized_name LIKE 'geist-fueled scarecrow // %'
   OR normalized_name LIKE 'glowrider // %'
   OR normalized_name LIKE 'high seas // %'
   OR normalized_name LIKE 'irini sengir // %'
   OR normalized_name LIKE 'lodestone golem // %'
   OR normalized_name LIKE 'sphere of resistance // %'
   OR normalized_name LIKE 'squeeze // %'
   OR normalized_name LIKE 'thorn of amethyst // %'
   OR normalized_name LIKE 'vryn wingmare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg626_static_spell_tax_new_server_20260707_165227;

COMMIT;
