import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../ai/battle_engine_config.dart';
import '../ai/forge_battle_client.dart';
import '../ai/native_battle_client.dart';
import '../ai/xmage_battle_client.dart';
import '../deck_validation_state_support.dart';

const battlePreflightSchemaVersion = 'battle_preflight_v1';

class BattlePreflightNotFound implements Exception {
  const BattlePreflightNotFound(this.target);

  final String target;
}

class BattlePreflightDeck {
  const BattlePreflightDeck({
    required this.id,
    required this.name,
    required this.format,
    required this.validationState,
    required this.validationReasons,
    required this.validationUpdatedAt,
    required this.cards,
  });

  final String id;
  final String name;
  final String format;
  final String validationState;
  final List<String> validationReasons;
  final DateTime? validationUpdatedAt;
  final List<Map<String, dynamic>> cards;

  int get cardCount => cards.fold<int>(
    0,
    (total, card) => total + ((card['quantity'] as int?) ?? 0),
  );

  int get commanderCount => cards.fold<int>(
    0,
    (total, card) =>
        total +
        (card['is_commander'] == true ? ((card['quantity'] as int?) ?? 0) : 0),
  );

  Map<String, dynamic> get externalPayload => {
    'id': id,
    'name': name,
    'cards': cards
        .map(
          (card) => {
            'name': card['name'],
            'set_code': card['set_code'],
            'collector_number': card['collector_number'],
            'quantity': card['quantity'],
            'is_commander': card['is_commander'],
          },
        )
        .toList(growable: false),
  };

  String get snapshotHash => canonicalExternalBattleDeckHash(externalPayload);

  String get revision {
    final validationMarker =
        validationUpdatedAt?.toUtc().toIso8601String() ?? 'unvalidated';
    return sha256
        .convert(utf8.encode('$snapshotHash\n$validationMarker\n'))
        .toString();
  }
}

class BattleCoverageReport {
  const BattleCoverageReport({
    required this.engineCoverage,
    required this.blockers,
    this.selectedEngine,
    this.unsupportedCards = const <Map<String, dynamic>>[],
  });

  final Map<String, String> engineCoverage;
  final List<String> blockers;
  final String? selectedEngine;
  final List<Map<String, dynamic>> unsupportedCards;

  bool get ready => selectedEngine != null && blockers.isEmpty;
}

typedef BattleCoverageProbe =
    Future<BattleCoverageReport> Function({
      required BattleEngineConfig config,
      required BattlePreflightDeck deck,
      required BattlePreflightDeck opponent,
    });

class BattlePreflightService {
  BattlePreflightService(this._pool, {BattleCoverageProbe? coverageProbe})
    : _coverageProbe = coverageProbe ?? checkExternalBattleCoverage;

  final Pool _pool;
  final BattleCoverageProbe _coverageProbe;

  Future<Map<String, dynamic>> inspect({
    required String userId,
    required String deckId,
    required String opponentDeckId,
    required Map<String, String> environment,
  }) async {
    final deck = await _loadDeck(
      userId: userId,
      deckId: deckId,
      allowPublic: false,
    );
    if (deck == null) throw const BattlePreflightNotFound('deck');

    final opponent = await _loadDeck(
      userId: userId,
      deckId: opponentDeckId,
      allowPublic: true,
    );
    if (opponent == null) throw const BattlePreflightNotFound('opponent');

    final availableOpponentCount = await _availableOpponentCount(
      userId: userId,
      deckId: deckId,
    );
    final blockers = <String>[
      ..._deckBlockers(deck, prefix: 'deck'),
      ..._deckBlockers(opponent, prefix: 'opponent'),
      if (availableOpponentCount == 0) 'no_available_opponents',
    ];

    BattleCoverageReport coverage;
    try {
      final config = BattleEngineConfig.fromEnvironment(environment);
      coverage = await _coverageProbe(
        config: config,
        deck: deck,
        opponent: opponent,
      );
    } on BattleEngineConfigurationException {
      coverage = const BattleCoverageReport(
        engineCoverage: {
          'xmage': 'unknown',
          'forge': 'unknown',
          'native': 'unknown',
        },
        blockers: ['engine_not_configured'],
      );
    }
    blockers.addAll(coverage.blockers);
    final normalizedBlockers = blockers.toSet().toList(growable: false);

    return {
      'schema_version': battlePreflightSchemaVersion,
      'status':
          normalizedBlockers.isEmpty && coverage.ready ? 'ready' : 'blocked',
      'read_only': true,
      'card_count': deck.cardCount,
      'commander_count': deck.commanderCount,
      'validation_state': deck.validationState,
      'validation_reasons': deck.validationReasons,
      'opponent': {
        'id': opponent.id,
        'name': opponent.name,
        'card_count': opponent.cardCount,
        'commander_count': opponent.commanderCount,
        'validation_state': opponent.validationState,
        'validation_reasons': opponent.validationReasons,
        'deck_snapshot_hash': opponent.snapshotHash,
        'deck_revision': opponent.revision,
      },
      'available_opponent_count': availableOpponentCount,
      'engine_coverage': coverage.engineCoverage,
      if (coverage.selectedEngine != null)
        'selected_engine': coverage.selectedEngine,
      'unsupported_cards': coverage.unsupportedCards,
      'blockers': normalizedBlockers,
      'deck_snapshot_hash': deck.snapshotHash,
      'deck_revision': deck.revision,
    };
  }

  Future<BattlePreflightDeck?> _loadDeck({
    required String userId,
    required String deckId,
    required bool allowPublic,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          d.id::text,
          d.name,
          d.format,
          d.validation_state,
          d.validation_reasons,
          d.validation_updated_at,
          c.name,
          c.set_code,
          c.collector_number,
          dc.quantity::int,
          dc.is_commander
        FROM decks d
        JOIN deck_cards dc ON dc.deck_id = d.id
        JOIN cards c ON c.id = dc.card_id
        WHERE d.id = CAST(@deckId AS uuid)
          AND (
            d.user_id = CAST(@userId AS uuid)
            OR (CAST(@allowPublic AS boolean) AND d.is_public = true)
          )
        ORDER BY
          dc.is_commander DESC,
          LOWER(c.name) ASC,
          COALESCE(c.oracle_id::text, '') ASC,
          COALESCE(c.scryfall_id::text, '') ASC,
          c.id::text ASC
      '''),
      parameters: {
        'deckId': deckId,
        'userId': userId,
        'allowPublic': allowPublic,
      },
    );
    if (result.isEmpty) return null;

    final first = result.first;
    return BattlePreflightDeck(
      id: first[0].toString(),
      name: first[1]?.toString() ?? deckId,
      format: first[2]?.toString().trim().toLowerCase() ?? '',
      validationState: normalizeDeckValidationState(first[3]),
      validationReasons: normalizeDeckValidationReasons(first[4]),
      validationUpdatedAt:
          first[5] is DateTime
              ? first[5] as DateTime
              : DateTime.tryParse(first[5]?.toString() ?? ''),
      cards: result
          .map(
            (row) => <String, dynamic>{
              'name': row[6]?.toString() ?? '',
              'set_code': row[7]?.toString(),
              'collector_number': row[8]?.toString(),
              'quantity': row[9] as int? ?? 0,
              'is_commander': row[10] as bool? ?? false,
            },
          )
          .toList(growable: false),
    );
  }

  Future<int> _availableOpponentCount({
    required String userId,
    required String deckId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM decks d
        WHERE d.id <> CAST(@deckId AS uuid)
          AND (d.user_id = CAST(@userId AS uuid) OR d.is_public = true)
          AND EXISTS (
            SELECT 1 FROM deck_cards dc WHERE dc.deck_id = d.id
          )
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    return result.isEmpty ? 0 : (result.first[0] as int? ?? 0);
  }
}

List<String> _deckBlockers(BattlePreflightDeck deck, {required String prefix}) {
  final blockers = <String>[];
  final expectedCount = switch (deck.format) {
    'commander' => 100,
    'brawl' => 60,
    _ => 60,
  };
  final exactSizeRequired =
      deck.format == 'commander' || deck.format == 'brawl';
  if ((exactSizeRequired && deck.cardCount != expectedCount) ||
      (!exactSizeRequired && deck.cardCount < expectedCount)) {
    blockers.add('${prefix}_size_invalid');
  }
  if (exactSizeRequired && deck.commanderCount != 1) {
    blockers.add('${prefix}_commander_invalid');
  }
  if (deck.validationState != deckValidationStateValidated) {
    blockers.add('${prefix}_validation_required');
  }
  return blockers;
}

Future<BattleCoverageReport> checkExternalBattleCoverage({
  required BattleEngineConfig config,
  required BattlePreflightDeck deck,
  required BattlePreflightDeck opponent,
}) async {
  final request = {
    'deck_a': deck.externalPayload,
    'deck_b': opponent.externalPayload,
  };
  final engineCoverage = <String, String>{
    'xmage': 'not_selected',
    'forge': 'not_selected',
    'native': 'not_selected',
  };
  final unsupportedCards = <Map<String, dynamic>>[];

  Future<bool> checkXmage() async {
    final client = XmageBattleClient(
      baseUrl: config.xmageSidecarUrl,
      expectedIdentity: config.xmageIdentity,
      allowLegacyIdentity: config.allowLegacySidecarIdentity,
      timeout: const Duration(seconds: 20),
    );
    try {
      final result = await client.coverage(request);
      final ready = result['ready'] == true;
      engineCoverage['xmage'] = ready ? 'ready' : 'unsupported';
      if (!ready) {
        unsupportedCards.addAll(_coverageRows(result, engine: 'xmage'));
      }
      return ready;
    } finally {
      client.close();
    }
  }

  Future<bool> checkForge() async {
    final client = ForgeBattleClient(
      baseUrl: config.forgeSidecarUrl,
      expectedIdentity: config.forgeIdentity,
      allowLegacyIdentity: config.allowLegacySidecarIdentity,
      timeout: const Duration(seconds: 20),
    );
    try {
      final result = await client.coverage(request);
      final ready = result['ready'] == true;
      engineCoverage['forge'] = ready ? 'ready' : 'unsupported';
      if (!ready) {
        unsupportedCards.addAll(_coverageRows(result, engine: 'forge'));
      }
      return ready;
    } finally {
      client.close();
    }
  }

  Future<bool> checkNative() async {
    final client = NativeBattleClient(
      baseUrl: config.nativeSidecarUrl,
      timeout: const Duration(seconds: 20),
    );
    try {
      final cards = <Map<String, dynamic>>[...deck.cards, ...opponent.cards];
      final result = await client.cardCoverage(cards);
      final ready = result['status'] == 'ready';
      engineCoverage['native'] = ready ? 'ready' : 'unsupported';
      if (!ready) {
        unsupportedCards.addAll(_coverageRows(result, engine: 'native'));
      }
      return ready;
    } finally {
      client.close();
    }
  }

  try {
    if (config.isStrictXmage) {
      final ready = await checkXmage();
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: ready ? const [] : const ['engine_coverage_incomplete'],
        selectedEngine: ready ? 'xmage' : null,
        unsupportedCards: unsupportedCards,
      );
    }
    if (config.isStrictForge) {
      final ready = await checkForge();
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: ready ? const [] : const ['engine_coverage_incomplete'],
        selectedEngine: ready ? 'forge' : null,
        unsupportedCards: unsupportedCards,
      );
    }
    if (config.isNative) {
      final ready = await checkNative();
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: ready ? const [] : const ['engine_coverage_incomplete'],
        selectedEngine: ready ? 'native' : null,
        unsupportedCards: unsupportedCards,
      );
    }

    if (await checkXmage()) {
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: const [],
        selectedEngine: 'xmage',
      );
    }
    if (await checkForge()) {
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: const [],
        selectedEngine: 'forge',
        unsupportedCards: unsupportedCards,
      );
    }
    if (await checkNative()) {
      return BattleCoverageReport(
        engineCoverage: engineCoverage,
        blockers: const [],
        selectedEngine: 'native',
        unsupportedCards: unsupportedCards,
      );
    }
    return BattleCoverageReport(
      engineCoverage: engineCoverage,
      blockers: const ['engine_coverage_incomplete'],
      unsupportedCards: unsupportedCards,
    );
  } on XmageServiceException {
    engineCoverage['xmage'] = 'unavailable';
  } on ForgeServiceException {
    engineCoverage['forge'] = 'unavailable';
  } on NativeBattleServiceException {
    engineCoverage['native'] = 'unavailable';
  }

  return BattleCoverageReport(
    engineCoverage: engineCoverage,
    blockers: const ['engine_coverage_unavailable'],
    unsupportedCards: unsupportedCards,
  );
}

List<Map<String, dynamic>> _coverageRows(
  Map<String, dynamic> result, {
  required String engine,
}) {
  final rows = result['unsupported_cards'];
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map(
        (row) => {
          'engine': engine,
          if (row['deck_key'] != null) 'deck_key': row['deck_key'].toString(),
          if (row['name'] != null) 'name': row['name'].toString(),
        },
      )
      .toList(growable: false);
}
