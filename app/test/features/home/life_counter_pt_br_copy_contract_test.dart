import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final lifeCounterDirectory = Directory('lib/features/home/life_counter');
  final flutterSurfaceFiles = <File>[
    ...lifeCounterDirectory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.dart'),
    ),
    File('lib/features/home/lotus/lotus_host_overlays.dart'),
  ];

  test('Life Counter visible copy remains in PT-BR', () {
    final sources = <String, String>{
      for (final file in flutterSurfaceFiles)
        file.path: file.readAsStringSync(),
    };

    const knownVisibleEnglishRemnants = <String>[
      'Life Counter Settings',
      'Life Counter History',
      'Life counter unavailable',
      'Preparing the life counter',
      'Card Search',
      'Find card details without leaving the game.',
      'Search cards',
      'Clear search',
      'Commander Damage',
      'Commander damage lethal',
      'Target Player',
      'Target Status',
      'Damage By Source',
      'Day / Night',
      'Dice Tools',
      'Quick Actions',
      'High Roll',
      'Current State',
      'First Player',
      'Last Event',
      'Game Modes',
      'Available',
      'Unavailable',
      'Active Now',
      'Card Pool Open',
      'Edit Card Pool',
      'Close Card Pool',
      'Close Mode',
      'Open Settings',
      'How It Works',
      'Quick Rules',
      'Game Timer',
      'Elapsed',
      'Running',
      'Paused',
      'Current events',
      'Archived games',
      'Archived events',
      'Last Table Event',
      'Current Game',
      'Import History',
      'Replace existing history?',
      'Player Appearance',
      'Target Player',
      'Profile name',
      'Background Images',
      'Player Counter',
      'Current player status',
      'Available counters',
      'Add custom counter',
      'Player State',
      'Current Status',
      'Commander Setup',
      'Player Tools',
      'Special State',
      'Set Life',
      'Manage Counters',
      'Roll D20',
      'Knock Out',
      'Decked Out',
      'Left Table',
      'Table State',
      'Storm Count',
      'Turn Tracker',
      'Starting Player',
      'Tracker Options',
      'Turn Status',
      'Auto high roll',
      'Turn timer',
      'Start Game',
      'Close table controls',
      'Open table controls',
      'Exit life counter',
      'Life counter tutorial',
      'Confirm action',
      'RETURN TO GAME',
      'GOT IT!',
      'TURN TRACKER',
      'Fullscreen mode',
      'DISPLAY COUNTERS ON PLAYER CARDS?',
    ];

    final failures = <String>[];
    for (final entry in sources.entries) {
      for (final remnant in knownVisibleEnglishRemnants) {
        if (_containsVisibleLiteral(entry.value, remnant)) {
          failures.add('${entry.key}: "$remnant"');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Copy visible to the player must stay in PT-BR. '
          'Protocol identifiers and canonical MTG names are validated separately.\n'
          '${failures.join('\n')}',
    );
  });

  test('canonical names and protocol identifiers are not localized', () {
    final gameModesSource =
        File(
          'lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart',
        ).readAsStringSync();
    final historySource =
        File(
          'lib/features/home/life_counter/life_counter_history.dart',
        ).readAsStringSync();
    final sessionSource =
        File(
          'lib/features/home/life_counter/life_counter_session.dart',
        ).readAsStringSync();
    final dayNightSource =
        File(
          'lib/features/home/life_counter/life_counter_day_night_state.dart',
        ).readAsStringSync();
    final canonicalUiSource = <String>[
      gameModesSource,
      File(
        'lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart',
      ).readAsStringSync(),
      File(
        'lib/features/home/life_counter/life_counter_native_table_state_sheet.dart',
      ).readAsStringSync(),
    ].join('\n');

    for (final canonicalName in const <String>[
      'Planechase',
      'Archenemy',
      'Commander',
      'Storm',
      'Bounty',
    ]) {
      expect(canonicalUiSource, contains(canonicalName));
    }

    for (final protocolLiteral in const <String>[
      "'gameHistory'",
      "'allGamesHistory'",
      "'currentGameMeta'",
      "'gameCounter'",
      "'player: \${player.toInt()} • change: \${change.toInt()} • life: \${life.toInt()}'",
    ]) {
      expect(historySource, contains(protocolLiteral));
    }

    for (final protocolLiteral in const <String>[
      "'decked_out'",
      "'answer_left'",
      "'commander_damage'",
    ]) {
      expect(sessionSource, contains(protocolLiteral));
    }

    expect(dayNightSource, contains("isNight ? 'night' : 'day'"));
  });

  test('embedded Life Counter declares Brazilian Portuguese', () {
    final visualSkin =
        File(
          'lib/features/home/lotus/lotus_visual_skin.dart',
        ).readAsStringSync();

    expect(visualSkin, contains("document.documentElement.lang = 'pt-BR';"));
  });

  test('embedded Lotus runtime translates the core visible controls', () {
    final visualSkin =
        File(
          'lib/features/home/lotus/lotus_visual_skin.dart',
        ).readAsStringSync();

    for (final translation
        in const <String, String>{
          'Settings': 'Configurações',
          'Restart Game': 'Reiniciar partida',
          'History': 'Histórico',
          'Current Game': 'Partida atual',
          'Winner': 'Vencedor',
          'Save': 'Salvar',
          'Cancel': 'Cancelar',
        }.entries) {
      expect(
        visualSkin,
        contains("['${translation.key}', '${translation.value}']"),
      );
    }
    expect(visualSkin, contains('syncPtBrCopy();'));
    expect(
      visualSkin,
      contains("document.title = 'ManaLoom • Contador de vida';"),
    );
  });
}

bool _containsVisibleLiteral(String source, String value) {
  return source.contains("'$value'") ||
      source.contains('"$value"') ||
      source.contains('>$value<') ||
      source.contains('>$value ');
}
