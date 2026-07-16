import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'life_counter_history.dart';

const int lifeCounterHistoryTransferVersion = 1;

@immutable
class LifeCounterHistoryTransferEntry {
  const LifeCounterHistoryTransferEntry({
    required this.message,
    this.occurredAt,
    this.rawOccurredAt,
  });

  final String message;
  final DateTime? occurredAt;
  final String? rawOccurredAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'occurred_at': occurredAt?.toIso8601String(),
      'raw_occurred_at': rawOccurredAt,
    };
  }

  static LifeCounterHistoryTransferEntry? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final message = raw['message'];
    if (message is! String || message.trim().isEmpty) {
      return null;
    }

    final occurredAtRaw = raw['occurred_at'];
    return LifeCounterHistoryTransferEntry(
      message: message.trim(),
      occurredAt:
          occurredAtRaw is String ? DateTime.tryParse(occurredAtRaw) : null,
      rawOccurredAt: _readOptionalString(raw['raw_occurred_at']),
    );
  }

  static String? _readOptionalString(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

@immutable
class LifeCounterHistoryTransfer {
  const LifeCounterHistoryTransfer({
    required this.version,
    required this.exportedAt,
    required this.currentGameEntries,
    required this.archiveEntries,
    this.archivedGames = const <LifeCounterArchivedGame>[],
    this.archivedGameCount,
    this.currentGameName,
    this.currentGameMeta,
    this.gameCounter,
    this.lastTableEvent,
  });

  final int version;
  final DateTime exportedAt;
  final int? archivedGameCount;
  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final int? gameCounter;
  final String? lastTableEvent;
  final List<LifeCounterHistoryTransferEntry> currentGameEntries;
  final List<LifeCounterHistoryTransferEntry> archiveEntries;
  final List<LifeCounterArchivedGame> archivedGames;

  factory LifeCounterHistoryTransfer.fromSnapshot(
    LifeCounterHistorySnapshot snapshot,
  ) {
    return LifeCounterHistoryTransfer(
      version: lifeCounterHistoryTransferVersion,
      exportedAt: DateTime.now().toUtc(),
      archivedGameCount: snapshot.archivedGameCount,
      currentGameName: snapshot.currentGameName,
      currentGameMeta: snapshot.currentGameMeta,
      gameCounter: snapshot.gameCounter,
      lastTableEvent: snapshot.lastTableEvent,
      archivedGames: snapshot.archivedGames,
      currentGameEntries: snapshot.currentGameEntries
          .map(
            (entry) => LifeCounterHistoryTransferEntry(
              message: entry.message,
              occurredAt: entry.occurredAt,
              rawOccurredAt: entry.rawOccurredAt,
            ),
          )
          .toList(growable: false),
      archiveEntries: snapshot.archiveEntries
          .map(
            (entry) => LifeCounterHistoryTransferEntry(
              message: entry.message,
              occurredAt: entry.occurredAt,
              rawOccurredAt: entry.rawOccurredAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'archived_game_count': archivedGameCount,
      'current_game_name': currentGameName,
      'current_game_meta': currentGameMeta,
      'game_counter': gameCounter,
      'last_table_event': lastTableEvent,
      'current_game_entries':
          currentGameEntries.map((e) => e.toJson()).toList(),
      'archive_entries': archiveEntries.map((e) => e.toJson()).toList(),
      if (archivedGames.isNotEmpty || (archivedGameCount ?? 0) == 0)
        'archived_games': archivedGames.map((game) => game.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterHistoryTransfer? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return tryFromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static LifeCounterHistoryTransfer? tryFromJson(Map<String, dynamic> raw) {
    final version = (raw['version'] as num?)?.toInt();
    if (version == null || version < 1) {
      return null;
    }

    final exportedAtRaw = raw['exported_at'];
    final exportedAt =
        exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;
    if (exportedAt == null) {
      return null;
    }

    final currentGameEntries = _readEntries(raw['current_game_entries']);
    final archiveEntries = _readEntries(raw['archive_entries']);
    final hasStructuredArchivedGames = raw.containsKey('archived_games');
    final archivedGames = _readArchivedGames(raw['archived_games']);
    if (currentGameEntries == null ||
        archiveEntries == null ||
        archivedGames == null) {
      return null;
    }

    final resolvedArchiveEntries =
        archiveEntries.isNotEmpty
            ? archiveEntries
            : archivedGames.reversed
                .expand(
                  (game) => game.entries.map(
                    (entry) => LifeCounterHistoryTransferEntry(
                      message: entry.message,
                      occurredAt: entry.occurredAt,
                      rawOccurredAt: entry.rawOccurredAt,
                    ),
                  ),
                )
                .toList(growable: false);
    final archivedGameCount =
        hasStructuredArchivedGames
            ? archivedGames.length
            : _readOptionalArchivedGameCount(raw['archived_game_count']);

    return LifeCounterHistoryTransfer(
      version: version,
      exportedAt: exportedAt,
      archivedGameCount: archivedGameCount,
      currentGameName: _readOptionalString(raw['current_game_name']),
      currentGameMeta: _readCurrentGameMeta(raw['current_game_meta']),
      gameCounter: _readOptionalGameCounter(raw['game_counter']),
      lastTableEvent: _readOptionalString(raw['last_table_event']),
      currentGameEntries: currentGameEntries,
      archiveEntries: resolvedArchiveEntries,
      archivedGames: archivedGames,
    );
  }

  static List<LifeCounterHistoryTransferEntry>? _readEntries(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      return null;
    }

    final entries = <LifeCounterHistoryTransferEntry>[];
    for (final item in raw) {
      final parsed = LifeCounterHistoryTransferEntry.tryFromJson(item);
      if (parsed == null) {
        return null;
      }
      entries.add(parsed);
    }

    return List<LifeCounterHistoryTransferEntry>.unmodifiable(entries);
  }

  static List<LifeCounterArchivedGame>? _readArchivedGames(Object? raw) {
    if (raw == null) {
      return const <LifeCounterArchivedGame>[];
    }
    if (raw is! List) {
      return null;
    }

    final games = <LifeCounterArchivedGame>[];
    for (final item in raw) {
      final game = LifeCounterArchivedGame.tryFromJson(item);
      if (game == null) {
        return null;
      }
      games.add(game);
    }
    return List<LifeCounterArchivedGame>.unmodifiable(games);
  }

  static String? _readOptionalString(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, Object?>? _readCurrentGameMeta(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    try {
      final encoded = jsonEncode(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
      return LifeCounterHistoryState.decodeCurrentGameMeta(encoded);
    } catch (_) {
      return null;
    }
  }

  static int? _readOptionalGameCounter(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw < 1 ? 1 : raw;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value < 1 ? 1 : value;
    }
    return null;
  }

  static int? _readOptionalArchivedGameCount(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw < 0 ? 0 : raw;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    return null;
  }
}
