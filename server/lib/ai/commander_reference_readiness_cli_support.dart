const activeUsableCommanderReferenceProfilesSql = '''
SELECT BTRIM(commander_name) AS commander_name
FROM commander_reference_profiles
WHERE BTRIM(commander_name) <> ''
  AND REGEXP_REPLACE(
        LOWER(BTRIM(COALESCE(profile_json->>'confidence', ''))),
        '([[:space:]]|-)+',
        '_',
        'g'
      ) IN ('medium', 'medium_high', 'high')
ORDER BY LOWER(BTRIM(commander_name)), BTRIM(commander_name)
''';

typedef CommanderReferenceProfileNameQuery =
    Future<Iterable<Object?>> Function(String sql);

class CommanderReferenceReadinessSelection {
  const CommanderReferenceReadinessSelection({
    required this.allActiveProfiles,
    required this.commanders,
  });

  final bool allActiveProfiles;
  final List<String> commanders;
}

CommanderReferenceReadinessSelection parseCommanderReferenceReadinessSelection(
  List<String> args,
) {
  final allActiveProfiles = args.contains('--all-active-profiles');
  final commanderArgs = args
      .where((arg) => arg.startsWith('--commander='))
      .toList(growable: false);
  final commandersArgs = args
      .where((arg) => arg.startsWith('--commanders='))
      .toList(growable: false);

  final selectedModeCount =
      <bool>[
        allActiveProfiles,
        commanderArgs.isNotEmpty,
        commandersArgs.isNotEmpty,
      ].where((selected) => selected).length;
  if (selectedModeCount > 1) {
    throw ArgumentError(
      'Use apenas um modo de selecao: --commander, --commanders ou '
      '--all-active-profiles.',
    );
  }
  if (selectedModeCount == 0) {
    throw ArgumentError(
      'Informe --commander=<nome>, --commanders="A;B;C" ou '
      '--all-active-profiles.',
    );
  }

  if (allActiveProfiles) {
    return const CommanderReferenceReadinessSelection(
      allActiveProfiles: true,
      commanders: [],
    );
  }

  final commanders = <Object?>[];
  for (final arg in commanderArgs) {
    commanders.add(arg.substring('--commander='.length));
  }
  for (final arg in commandersArgs) {
    commanders.addAll(
      arg.substring('--commanders='.length).split(RegExp(r'[;\n]')),
    );
  }
  final normalized = normalizeCommanderReferenceProfileNames(commanders);
  if (normalized.isEmpty) {
    throw ArgumentError('O modo de selecao informado nao contem commanders.');
  }
  return CommanderReferenceReadinessSelection(
    allActiveProfiles: false,
    commanders: normalized,
  );
}

Future<List<String>> discoverActiveUsableCommanderReferenceProfiles({
  required CommanderReferenceProfileNameQuery query,
}) async {
  final names = await query(activeUsableCommanderReferenceProfilesSql);
  return normalizeCommanderReferenceProfileNames(names);
}

List<String> normalizeCommanderReferenceProfileNames(Iterable<Object?> values) {
  final byNormalizedName = <String, String>{};
  for (final raw in values) {
    final name = raw?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    byNormalizedName.putIfAbsent(name.toLowerCase(), () => name);
  }
  final names = byNormalizedName.values.toList(growable: false);
  names.sort((left, right) {
    final normalizedOrder = left.toLowerCase().compareTo(right.toLowerCase());
    return normalizedOrder == 0 ? left.compareTo(right) : normalizedOrder;
  });
  return names;
}
