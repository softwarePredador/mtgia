@Tags(['live', 'live_backend'])
library;

import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';
import 'package:server/ai/optimize_filler_loader_support.dart';
import 'package:server/ai/optimize_functional_role_support.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final hasDatabaseEnvironment = const [
    'DB_HOST',
    'DB_PORT',
    'DB_NAME',
    'DB_USER',
  ].every((key) => (Platform.environment[key] ?? '').trim().isNotEmpty);
  final skipReason =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !hasDatabaseEnvironment
          ? 'Teste live requer DB_HOST, DB_PORT, DB_NAME e DB_USER.'
          : null;

  Pool openPool() => Pool.withEndpoints([
    Endpoint(
      host: Platform.environment['DB_HOST']!,
      port: int.parse(Platform.environment['DB_PORT']!),
      database: Platform.environment['DB_NAME']!,
      username: Platform.environment['DB_USER']!,
      password: Platform.environment['DB_PASS'] ?? '',
    ),
  ], settings: const PoolSettings(sslMode: SslMode.disable));

  const talrandDeck = <Map<String, dynamic>>[
    {
      'name': 'Talrand, Sky Summoner',
      'type_line': 'Legendary Creature — Merfolk Wizard',
      'oracle_text':
          'Whenever you cast an instant or sorcery spell, create a 2/2 blue '
          'Drake creature token with flying.',
      'color_identity': ['U'],
      'quantity': 1,
      'is_commander': true,
    },
  ];
  const expectedWipeFloors = <int, int>{1: 3, 2: 3, 3: 3, 4: 1, 5: 0};

  test(
    'role-specific PostgreSQL lane returns exact bracket-safe wipe floors',
    () async {
      final pool = openPool();
      try {
        for (final entry in expectedWipeFloors.entries) {
          final candidates = await loadCommanderWipeFloorCandidates(
            pool: pool,
            currentDeckCards: talrandDeck,
            commanderColorIdentity: const {'U'},
            excludeNames: const {},
            bracket: entry.key,
            limit: entry.value,
          );

          expect(
            candidates,
            hasLength(entry.value),
            reason: 'bracket=${entry.key}',
          );
          expect(
            candidates.every(
              (candidate) => looksLikeBoardWipe(
                candidate['oracle_text']?.toString() ?? '',
              ),
            ),
            isTrue,
            reason: 'bracket=${entry.key} candidates=$candidates',
          );
          if (entry.key <= 2) {
            expect(
              candidates.map((candidate) => candidate['name']),
              isNot(contains('Cyclonic Rift')),
              reason: 'bracket=${entry.key}',
            );
          }
        }
      } finally {
        await pool.close();
      }
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
