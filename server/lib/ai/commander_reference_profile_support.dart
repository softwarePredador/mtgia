import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

const loreholdReferenceCommanderName = 'Lorehold, the Historian';
const loreholdReferenceProfileVersion =
    'lorehold_reference_profile_v1_2026-05-11';
const loreholdReferenceProfileSource = 'aggregate_reference_profile_v1';

const commanderReferenceRequiredTables = <String>[
  'commander_reference_profiles',
  'commander_reference_card_stats',
  'commander_card_synergy',
  'card_role_scores',
  'card_function_tags',
];

const _confidenceRank = <String, int>{
  'not_proven': 0,
  'low': 1,
  'medium_low': 2,
  'medium': 3,
  'medium_high': 4,
  'high': 5,
};

String normalizeCommanderReferenceName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizeCommanderReferenceConfidence(Object? value) {
  final normalized =
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  if (normalized == null || normalized.isEmpty) return 'not_proven';
  return normalized;
}

bool isLoreholdCommanderReferenceCandidate(String? commanderName) {
  if (commanderName == null) return false;
  return normalizeCommanderReferenceName(commanderName) ==
      normalizeCommanderReferenceName(loreholdReferenceCommanderName);
}

String? normalizedCommanderReferenceCandidate(String? commanderName) {
  final normalized = normalizeCommanderReferenceName(commanderName ?? '');
  return normalized.isEmpty ? null : normalized;
}

bool isReferenceProfileConfidenceUsable(Object? confidence) {
  return commanderReferenceConfidenceRank(confidence) >=
      commanderReferenceConfidenceRank('medium');
}

int commanderReferenceConfidenceRank(Object? confidence) {
  final normalized = normalizeCommanderReferenceConfidence(confidence);
  return _confidenceRank[normalized] ?? _confidenceRank['not_proven']!;
}

Map<String, dynamic> buildLoreholdReferenceProfilePayload({
  DateTime? updatedAt,
}) {
  return buildCommanderReferenceProfilePayload(
    commanderName: loreholdReferenceCommanderName,
    version: loreholdReferenceProfileVersion,
    source: loreholdReferenceProfileSource,
    confidence: 'high',
    sourceCount: 4,
    colorIdentity: const ['R', 'W'],
    sourceLimitNotes: const [
      'Aggregate/manual reference only; no copied public decklist.',
      'No heavy scraping and no private endpoint assumptions.',
      'No cEDH proof was established for this commander.',
    ],
    themes: const [
      {
        'name': 'boros_miracle_big_spells',
        'confidence': 'high',
        'notes':
            'Lorehold gives instants and sorceries in hand miracle {2}; prioritize expensive high-impact spells only when setup exists.',
      },
      {
        'name': 'topdeck_manipulation',
        'confidence': 'high',
        'notes':
            'Topdeck control and discard replacement make miracle turns more deterministic.',
      },
      {
        'name': 'opponent_turn_draw_rummage',
        'confidence': 'medium_high',
        'notes':
            'Support first-draw opportunities on opponent turns without relying only on the commander.',
      },
      {
        'name': 'spellslinger_copy_payoffs',
        'confidence': 'medium',
        'notes':
            'Copy/token/mana payoffs convert discounted spells into a win, but should not crowd out setup.',
      },
      {
        'name': 'token_burst_finishers',
        'confidence': 'medium',
        'notes':
            'Large white/red sorceries can close games when discounted by miracle.',
      },
      {
        'name': 'graveyard_flashback_recursion',
        'confidence': 'medium_low',
        'notes':
            'Secondary subtheme only when discard value is intentionally supported.',
      },
    ],
    roleTargets: const {
      'lands': {'min': 36, 'max': 38},
      'mana_rocks_treasure_ramp': {'min': 10, 'max': 13},
      'topdeck_miracle_setup': {'min': 6, 'max': 9},
      'draw_rummage_opponent_turn_draw': {'min': 8, 'max': 12},
      'miracle_haymakers': {'min': 10, 'max': 16},
      'spot_interaction': {'min': 4, 'max': 6},
      'board_wipes_resets': {'min': 3, 'max': 5},
      'spell_payoffs_copy_engines': {'min': 5, 'max': 8},
      'graveyard_recursion': {'min': 2, 'max': 5},
      'dedicated_win_conditions': {'min': 4, 'max': 7},
    },
    expectedPackages: const {
      'topdeck_and_miracle_setup': [
        "Sensei's Divining Top",
        'Scroll Rack',
        'Library of Leng',
        'Brainstone',
        'Temple Bell',
        'Mikokoro, Center of the Sea',
        'Victory Chimes',
      ],
      'miracle_payoffs_expensive_spells': [
        'Approach of the Second Sun',
        'Storm Herd',
        'Rise of the Eldrazi',
        'Soulfire Eruption',
        'Apex of Power',
        'Volcanic Vision',
        'Creative Technique',
        'Dance with Calamity',
        'Call Forth the Tempest',
        "Brass's Bounty",
        'Hit the Mother Lode',
        "Mizzix's Mastery",
      ],
      'interaction_and_resets': [
        'Swords to Plowshares',
        'Path to Exile',
        'Blasphemous Act',
        'Austere Command',
        'Terminus',
        'Bonfire of the Damned',
      ],
      'spell_payoff_copy_package': [
        'Storm-Kiln Artist',
        'Monastery Mentor',
        'Young Pyromancer',
        'Primal Amulet // Primal Wellspring',
        "Pyromancer's Goggles",
        'Double Vision',
        "Sunbird's Invocation",
        'Arcane Bombardment',
        "Chandra, Hope's Beacon",
      ],
    },
    avoidPatterns: const [
      {
        'pattern': 'blue_miracle_package',
        'examples': [
          'Temporal Mastery',
          'Devastation Tide',
          'Mystical Tutor',
          'Brainstorm',
        ],
        'reason':
            'Blue cards are outside Lorehold color identity and must not be recommended.',
      },
      {
        'pattern': 'banned_fast_mana',
        'examples': ['Mana Crypt', 'Jeweled Lotus', 'Dockside Extortionist'],
        'reason':
            'Do not override the local Commander legality validator with generic fast-mana heuristics.',
      },
      {
        'pattern': 'cedh_assumption',
        'examples': ['full cEDH fast-mana/stax shell'],
        'reason':
            'Competitive Commander relevance was not proven for this profile.',
      },
      {
        'pattern': 'uncategorized_haymakers',
        'examples': ['random seven-plus mana spells without setup/payoff role'],
        'reason':
            'Every expensive spell must map to payoff, removal, mana, refill or win condition.',
      },
    ],
    updatedAt: updatedAt,
  );
}

Map<String, dynamic> buildCommanderReferenceProfilePayload({
  required String commanderName,
  required String version,
  required String source,
  required String confidence,
  required int sourceCount,
  required List<String> colorIdentity,
  required List<Map<String, dynamic>> themes,
  required Map<String, dynamic> roleTargets,
  required Map<String, List<String>> expectedPackages,
  required List<Map<String, dynamic>> avoidPatterns,
  List<String> sourceLimitNotes = const [],
  DateTime? updatedAt,
}) {
  final commander = commanderName.trim();
  if (commander.isEmpty) {
    throw ArgumentError.value(commanderName, 'commanderName', 'is required');
  }
  final updatedIso = (updatedAt ?? DateTime.now().toUtc()).toIso8601String();
  return {
    'version': version.trim().isEmpty
        ? commanderReferenceProfileHash({'commander': commander})
        : version.trim(),
    'source': source.trim().isEmpty
        ? 'aggregate_reference_profile_v1'
        : source.trim(),
    'commander': commander,
    'confidence': normalizeCommanderReferenceConfidence(confidence),
    'source_count': sourceCount < 0 ? 0 : sourceCount,
    'updated_at': updatedIso,
    'color_identity': colorIdentity
        .map((color) => color.trim().toUpperCase())
        .where((color) => color.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
    'source_limit_notes': sourceLimitNotes,
    'themes': themes,
    'role_targets': roleTargets,
    'expected_packages': expectedPackages,
    'avoid_patterns': avoidPatterns,
  };
}

String commanderReferenceProfileHash(Map<String, dynamic> profile) {
  final material = jsonEncode(_stableJson(profile));
  return sha256.convert(utf8.encode(material)).toString().substring(0, 12);
}

String commanderReferenceProfileCacheVersion(Map<String, dynamic> profile) {
  final version = profile['version']?.toString().trim();
  if (version != null && version.isNotEmpty) return version;
  return commanderReferenceProfileHash(profile);
}

Map<String, dynamic> buildCommanderReferenceDiagnostics(
  Map<String, dynamic>? profile, {
  Map<String, dynamic> cardStatsDiagnostics = const {
    'reference_card_stats_used': false,
    'on_theme_candidate_count': 0,
    'unresolved_reference_cards': <String>[],
    'package_keys': <String>[],
  },
  Map<String, dynamic>? referenceDeckCorpusDiagnostics,
  Map<String, dynamic>? referenceDeckEvaluation,
}) {
  if (profile == null) {
    return {
      'reference_profile_used': false,
      ...cardStatsDiagnostics,
      if (referenceDeckCorpusDiagnostics != null)
        ...referenceDeckCorpusDiagnostics,
      if (referenceDeckEvaluation != null)
        'reference_deck_evaluation': referenceDeckEvaluation,
    };
  }

  return {
    'reference_profile_used': true,
    'reference_profile_source':
        profile['source'] ?? loreholdReferenceProfileSource,
    'reference_profile_version': commanderReferenceProfileCacheVersion(profile),
    'profile_confidence': normalizeCommanderReferenceConfidence(
      profile['confidence'],
    ),
    'themes': _themeNames(profile).take(8).toList(growable: false),
    'source_count': _sourceCount(profile),
    ...cardStatsDiagnostics,
    if (referenceDeckCorpusDiagnostics != null)
      ...referenceDeckCorpusDiagnostics,
    if (referenceDeckEvaluation != null)
      'reference_deck_evaluation': referenceDeckEvaluation,
  };
}

String buildCommanderReferenceProfilePrompt(Map<String, dynamic> profile) {
  final commander = _profileCommanderName(profile);
  final identity = _profileColorIdentity(profile);
  final identityText =
      identity.isEmpty ? 'the profile color identity' : identity.join('/');
  final themes = _themeNames(profile).take(6).join(', ');
  final roleTargets = _formatRoleTargets(profile['role_targets']);
  final packages = _formatExpectedPackages(profile['expected_packages']);
  final avoid = _formatAvoidPatterns(profile['avoid_patterns']);

  return '''
Commander reference profile active:
- Use exactly "$commander" as the Commander.
- Format is Commander; total deck must be exactly 100 cards including the Commander.
- Color identity is exactly $identityText. Every nonland, split, MDFC, adventure, aftermath or back-face card must be legal inside $identityText.
- Never include cards outside this color identity or banned Commander cards. If a familiar miracle/topdeck staple is off-color, replace it with an on-color or colorless alternative instead of relying on validator repair.
- For this reference-guided build, do not infer cards from generic off-color miracle, tutor, cantrip, extra-turn, ramp or draw packages. Use only $identityText/colorless cards and legal lands that match the commander identity; if color identity is uncertain, omit the card.
- Core themes: $themes.
- Role targets: $roleTargets.
- Prioritize these package signals when legal and budget/bracket appropriate: $packages.
- Avoid: $avoid.
- Do not copy a public decklist. Build a legal, functional ManaLoom list from aggregate signals.
''';
}

Future<Map<String, dynamic>?> loadUsableCommanderReferenceProfile({
  required Pool pool,
  required String? commanderName,
}) async {
  final commander = commanderName?.trim();
  if (commander == null || commander.isEmpty) return null;

  final result = await pool.execute(
    Sql.named('''
      SELECT profile_json
      FROM commander_reference_profiles
      WHERE LOWER(commander_name) = LOWER(@commander)
      LIMIT 1
    '''),
    parameters: {'commander': commander},
  );

  if (result.isEmpty) return null;
  final profile = _decodeProfile(result.first[0]);
  if (profile == null) return null;
  if (!isReferenceProfileConfidenceUsable(profile['confidence'])) return null;
  return profile;
}

Future<Map<String, bool>> auditCommanderReferenceTables(Pool pool) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name::text = ANY(@tables)
    '''),
    parameters: {
      'tables': TypedValue(Type.textArray, commanderReferenceRequiredTables),
    },
  );

  final found = result.map((row) => row[0].toString()).toSet();
  return {
    for (final table in commanderReferenceRequiredTables)
      table: found.contains(table),
  };
}

Future<void> ensureCommanderReferenceProfileTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_profiles (
      commander_name TEXT PRIMARY KEY,
      source TEXT NOT NULL,
      deck_count INTEGER NOT NULL DEFAULT 0,
      profile_json JSONB NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  ''');
}

Future<void> upsertLoreholdReferenceProfile(
  Pool pool, {
  DateTime? updatedAt,
}) async {
  final profile = buildLoreholdReferenceProfilePayload(updatedAt: updatedAt);
  await upsertCommanderReferenceProfile(pool, profile);
}

Future<void> upsertCommanderReferenceProfile(
  Pool pool,
  Map<String, dynamic> profile,
) async {
  final commander = _profileCommanderName(profile);
  if (commander.isEmpty) {
    throw ArgumentError.value(profile, 'profile', 'commander is required');
  }
  await pool.execute(
    Sql.named('''
      INSERT INTO commander_reference_profiles (
        commander_name,
        source,
        deck_count,
        profile_json,
        updated_at
      ) VALUES (
        @commander,
        @source,
        0,
        @profile::jsonb,
        NOW()
      )
      ON CONFLICT (commander_name)
      DO UPDATE SET
        source = EXCLUDED.source,
        deck_count = EXCLUDED.deck_count,
        profile_json = EXCLUDED.profile_json,
        updated_at = NOW()
    '''),
    parameters: {
      'commander': commander,
      'source':
          profile['source']?.toString() ?? 'aggregate_reference_profile_v1',
      'profile': jsonEncode(profile),
    },
  );
}

Map<String, dynamic>? _decodeProfile(dynamic value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return null;
}

int _sourceCount(Map<String, dynamic> profile) {
  final raw = profile['source_count'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

String _profileCommanderName(Map<String, dynamic> profile) {
  final raw = profile['commander'] ?? profile['commander_name'];
  return raw?.toString().trim() ?? '';
}

List<String> _profileColorIdentity(Map<String, dynamic> profile) {
  final raw = profile['color_identity'];
  if (raw is! Iterable) return const [];
  final colors = raw
      .map((color) => color.toString().trim().toUpperCase())
      .where((color) => color.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return colors;
}

List<String> _themeNames(Map<String, dynamic> profile) {
  final rawThemes = profile['themes'];
  if (rawThemes is! List) return const [];
  return rawThemes
      .map((theme) {
        if (theme is Map && theme['name'] != null) {
          return theme['name'].toString().trim();
        }
        return theme.toString().trim();
      })
      .where((theme) => theme.isNotEmpty)
      .toList(growable: false);
}

String _formatRoleTargets(dynamic raw) {
  if (raw is! Map) return 'not provided';
  final entries = raw.entries.map((entry) {
    final value = entry.value;
    if (value is Map) {
      final min = value['min'];
      final max = value['max'];
      if (min != null && max != null) return '${entry.key}: $min-$max';
    }
    return '${entry.key}: $value';
  }).toList()
    ..sort();
  return entries.take(12).join('; ');
}

String _formatExpectedPackages(dynamic raw) {
  if (raw is! Map) return 'not provided';
  final entries = raw.entries.map((entry) {
    final count = entry.value is List
        ? (entry.value as List)
            .map((card) => card.toString().trim())
            .where((card) => card.isNotEmpty)
            .length
        : 1;
    return '${entry.key} ($count candidates)';
  }).toList()
    ..sort();
  return entries.take(6).join('; ');
}

String _formatAvoidPatterns(dynamic raw) {
  if (raw is! List) return 'not provided';
  return raw
      .map((item) {
        if (item is Map) {
          final pattern = item['pattern']?.toString().trim();
          final reason = item['reason']?.toString().trim();
          if (pattern != null && pattern.isNotEmpty) {
            return reason == null || reason.isEmpty
                ? pattern
                : '$pattern ($reason)';
          }
        }
        return item.toString().trim();
      })
      .where((item) => item.isNotEmpty)
      .take(8)
      .join('; ');
}

dynamic _stableJson(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {
      for (final key in keys)
        key: _stableJson(value.entries
            .firstWhere((entry) => entry.key.toString() == key)
            .value),
    };
  }
  if (value is List) return value.map(_stableJson).toList(growable: false);
  return value;
}
