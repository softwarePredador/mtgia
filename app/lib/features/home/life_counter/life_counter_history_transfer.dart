import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'life_counter_history.dart';

const int lifeCounterHistoryTransferVersion = 1;

@immutable
class LifeCounterHistoryTransferEntry {
  const LifeCounterHistoryTransferEntry({
    required this.message,
    this.occurredAt,
  });

  final String message;
  final DateTime? occurredAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'occurred_at': occurredAt?.toIso8601String(),
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
    );
  }
}

@immutable
class LifeCounterHistoryTransfer {
  const LifeCounterHistoryTransfer({
    required this.version,
    required this.exportedAt,
    required this.currentGameEntries,
    required this.archiveEntries,
    this.currentGameName,
    this.currentGameMeta,
    this.gameCounter,
    this.lastTableEvent,
  });

  final int version;
  final DateTime exportedAt;
  final String? currentGameName;
  final Map<String, Object?>? currentGameMeta;
  final int? gameCounter;
  final String? lastTableEvent;
  final List<LifeCounterHistoryTransferEntry> currentGameEntries;
  final List<LifeCounterHistoryTransferEntry> archiveEntries;

  factory LifeCounterHistoryTransfer.fromSnapshot(
    LifeCounterHistorySnapshot snapshot,
  ) {
    return LifeCounterHistoryTransfer(
      version: lifeCounterHistoryTransferVersion,
      exportedAt: DateTime.now().toUtc(),
      currentGameName: snapshot.currentGameName,
      currentGameMeta: snapshot.currentGameMeta,
      gameCounter: snapshot.gameCounter,
      lastTableEvent: snapshot.lastTableEvent,
      currentGameEntries: snapshot.currentGameEntries
          .map(
            (entry) => LifeCounterHistoryTransferEntry(
              message: entry.message,
              occurredAt: entry.occurredAt,
            ),
          )
          .toList(growable: false),
      archiveEntries: snapshot.archiveEntries
          .map(
            (entry) => LifeCounterHistoryTransferEntry(
              message: entry.message,
              occurredAt: entry.occurredAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'current_game_name': currentGameName,
      'current_game_meta': currentGameMeta,
      'game_counter': gameCounter,
      'last_table_event': lastTableEvent,
      'current_game_entries':
          currentGameEntries.map((e) => e.toJson()).toList(),
      'archive_entries': archiveEntries.map((e) => e.toJson()).toList(),
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
    if (currentGameEntries == null || archiveEntries == null) {
      return null;
    }

    return LifeCounterHistoryTransfer(
      version: version,
      exportedAt: exportedAt,
      currentGameName: _readOptionalString(raw['current_game_name']),
      currentGameMeta: _readCurrentGameMeta(raw['current_game_meta']),
      gameCounter: _readOptionalGameCounter(raw['game_counter']),
      lastTableEvent: _readOptionalString(raw['last_table_event']),
      currentGameEntries: currentGameEntries,
      archiveEntries: archiveEntries,
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
}
