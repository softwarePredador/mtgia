BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blessed spirits', 'boar-q-pine', 'deeproot champion', 'electrostatic infantry', 'kurgadon', 'lurking lizards', 'mage tower referee', 'pyre hound', 'pyroceratops', 'quirion dryad', 'spellgorger weird', 'sprite dragon', 'stormkeld prowler', 'tempest angler')
   OR normalized_name LIKE 'blessed spirits // %'
   OR normalized_name LIKE 'boar-q-pine // %'
   OR normalized_name LIKE 'deeproot champion // %'
   OR normalized_name LIKE 'electrostatic infantry // %'
   OR normalized_name LIKE 'kurgadon // %'
   OR normalized_name LIKE 'lurking lizards // %'
   OR normalized_name LIKE 'mage tower referee // %'
   OR normalized_name LIKE 'pyre hound // %'
   OR normalized_name LIKE 'pyroceratops // %'
   OR normalized_name LIKE 'quirion dryad // %'
   OR normalized_name LIKE 'spellgorger weird // %'
   OR normalized_name LIKE 'sprite dragon // %'
   OR normalized_name LIKE 'stormkeld prowler // %'
   OR normalized_name LIKE 'tempest angler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg483_spell_cast_add_counters_new_server_20260705_050912;

COMMIT;
